import json

from rest_framework import status
from rest_framework.viewsets import ViewSet
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated

from rest_framework_simplejwt.authentication import JWTAuthentication

from django.http import JsonResponse
from django.conf import settings
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.db import connection

from firebase_admin.messaging import Message, Notification
from fcm_django.models import FCMDevice
from fcm_django.api.rest_framework import FCMDeviceViewSet

from .models import MQTTDevice
from .serializers import MQTTDeviceSerializer
from .mqtt import MQTTClient
from .utils import generate_mqtt_token, send_mqtt_message


class SendNotificationView(ViewSet):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    message_counter = 0

    mqtt_client = None

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if SendNotificationView.mqtt_client is None:
            SendNotificationView.mqtt_client = MQTTClient(broker=settings.MQTT_BROKER, port=settings.MQTT_PORT)

    @action(detail=False, methods=["POST"], url_path="send_notification")
    def send_notification(self, request):
        if request.method == "POST":
            data = json.loads(request.body)
            title = data.get("title")
            body = data.get("body")

            # Generate a unique msg_id by counting requests
            SendNotificationView.message_counter += 1
            msg_id = SendNotificationView.message_counter

            # Send a notification via MQTT
            send_mqtt_message(SendNotificationView.mqtt_client, msg_id=msg_id, title=title, body=body)

            # Send a notification to all registered Firebase devices
            devices = FCMDevice.objects.all()
            devices.send_message(Message(notification=Notification(title=title, body=body)))

            return JsonResponse({"message": "Notifications sent successfully"})
        
        return JsonResponse({"error": "Invalid request"}, status=400)

class MQTTDeviceViewSet(ViewSet):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=["GET"], url_path="devices")
    def list_devices(self, request):
        devices = MQTTDevice.objects.all()
        serializer = MQTTDeviceSerializer(devices, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    @action(detail=False, methods=["POST"], url_path="webhook")
    def webhook(self, request):
        try:
            body = request.body
            decoded_str = body.decode("utf-8")
            data = json.loads(decoded_str)

            event = data.get("event")
            client_id = data.get("clientid")
            user_id = data.get("user_id")
            ip_address = data.get("ip_address", None)

            if not client_id or not user_id:
                return Response({"error": "Invalid data"}, status=400)

            if user_id == "backend":
                return Response({"status": "success"})

            if event == "client.connected":
                self.handle_client_connected(user_id, client_id, ip_address)
            elif event == "client.disconnected":
                self.handle_client_disconnected(user_id, client_id)
            else:
                return Response({"error": "Unknown event"}, status=400)

            return Response({"status": "success"})

        except json.JSONDecodeError:
            return Response({"error": "Invalid JSON"}, status=400)

        finally:
            connection.close()  # Explicitly close the database connection        

    def handle_client_connected(self, user_id, device_id, ip_address):
        user = get_user_model().objects.filter(id=int(user_id)).first()
        if not user:
            return

        device, created = MQTTDevice.objects.update_or_create(
            client_id=device_id,
            defaults={
                "user": user,
                "active": True,
                "last_status": "online",
                "last_connected_at": timezone.now(),
                "ip_address": ip_address,  # Store IP
            },
        )
        print(f"User {user} connected on device {device_id} (IP: {ip_address})")

    def handle_client_disconnected(self, user_id, device_id):
        user = get_user_model().objects.filter(id=int(user_id)).first()
        if not user:
            return

        device = MQTTDevice.objects.filter(client_id=device_id, user=user).update(
            active=False,
            last_status="offline",
        )

        if device:
            print(f"User {user_id} disconnected from device {device_id}")

class EMQXTokenViewSet(ViewSet):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=["GET"], url_path="emqx_token")
    def mqtt_token(self, request):
        user = request.user
        if not user.is_authenticated:
            return Response({"error": "Unauthorized"}, status=401)
        
        token = generate_mqtt_token(user)

        return Response({"mqtt_token": token, "user_id": str(user.id)})

class SecureFCMDeviceViewSet(FCMDeviceViewSet):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Ensure users can only access their own devices."""
        return super().get_queryset().filter(user=self.request.user)

    def perform_create(self, serializer):
        """Ensure the registered device is linked to the authenticated user."""
        serializer.save(user=self.request.user)

    def update(self, request, *args, **kwargs):
        """Prevent updating device details to enhance security."""
        return Response({"detail": "Update not allowed."}, status=status.HTTP_405_METHOD_NOT_ALLOWED)

    def partial_update(self, request, *args, **kwargs):
        """Prevent partial updates."""
        return Response({"detail": "Partial update not allowed."}, status=status.HTTP_405_METHOD_NOT_ALLOWED)


class SecureMQTTDeviceViewSet(MQTTDeviceViewSet):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Ensure users can only access their own devices."""
        return super().get_queryset().filter(user=self.request.user)

    def perform_create(self, serializer):
        """Ensure the registered device is linked to the authenticated user."""
        serializer.save(user=self.request.user)

    def update(self, request, *args, **kwargs):
        """Prevent updating device details to enhance security."""
        return Response({"detail": "Update not allowed."}, status=status.HTTP_405_METHOD_NOT_ALLOWED)

    def partial_update(self, request, *args, **kwargs):
        """Prevent partial updates."""
        return Response({"detail": "Partial update not allowed."}, status=status.HTTP_405_METHOD_NOT_ALLOWED)