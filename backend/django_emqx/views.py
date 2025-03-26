import json

from rest_framework import status
from rest_framework.viewsets import ViewSet
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated

from django.http import JsonResponse
from django.conf import settings
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.db import connection

from firebase_admin.messaging import Message, Notification
from fcm_django.models import FCMDevice

from .models import EMQXDevice
from .serializers import EMQXDeviceSerializer
from .mqtt import MQTTClient
from .utils import generate_mqtt_token, send_mqtt_message


class NotificationViewSet(ViewSet):
    permission_classes = [IsAuthenticated]
    message_counter = 0

    mqtt_client = None

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if NotificationViewSet.mqtt_client is None:
            NotificationViewSet.mqtt_client = MQTTClient(broker=settings.EMQX_BROKER, port=settings.EMQX_PORT)

    def create(self, request):
        data = json.loads(request.body)
        title = data.get("title")
        body = data.get("body")

        if not title and not body:
            return Response({"error": "Title or body are required"}, status=status.HTTP_400_BAD_REQUEST)

        # Generate a unique msg_id by counting requests
        NotificationViewSet.message_counter += 1
        msg_id = NotificationViewSet.message_counter

        # Send a notification via MQTT
        send_mqtt_message(NotificationViewSet.mqtt_client, msg_id=msg_id, title=title, body=body)

        # Send a notification to all registered Firebase devices
        devices = FCMDevice.objects.all()
        devices.send_message(Message(notification=Notification(title=title, body=body)))

        return JsonResponse({"message": "Notifications sent successfully"})


class EMQXTokenViewSet(ViewSet):
    permission_classes = [IsAuthenticated]

    def create(self, request):
        user = request.user
        token = generate_mqtt_token(user)

        return Response({"mqtt_token": token, "user_id": str(user.id)})


class EMQXDeviceViewSet(ViewSet):
    # @action(detail=False, methods=["GET"], url_path="devices")
    def list(self, request):
        devices = EMQXDevice.objects.all()
        serializer = EMQXDeviceSerializer(devices, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    # @action(detail=False, methods=["POST"], url_path="webhook")
    def create(self, request):
        token = request.headers.get("X-Webhook-Token")

        if not token or token != settings.EMQX_WEBHOOK_SECRET:
            return Response({"error": "Forbidden"}, status=403)

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

        device, created = EMQXDevice.objects.update_or_create(
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

        device = EMQXDevice.objects.filter(client_id=device_id, user=user).update(
            active=False,
            last_status="offline",
        )

        if device:
            print(f"User {user_id} disconnected from device {device_id}")