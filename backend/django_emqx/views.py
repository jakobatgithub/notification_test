## django_emqx/views.py

import json

from rest_framework import status
from rest_framework.viewsets import ViewSet
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

from django.http import JsonResponse
from django.conf import settings
from django.contrib.auth import get_user_model
from django.utils import timezone

# Check if Firebase is available
try:
    from fcm_django.models import FCMDevice
    from firebase_admin.messaging import Notification, Message as FCMMessage
    firebase_installed = True
except ImportError:
    firebase_installed = False

from . import get_mqtt_client
from .models import EMQXDevice, Message, UserNotification

from .serializers import EMQXDeviceSerializer
from .utils import generate_mqtt_token, send_mqtt_message

User = get_user_model()

class NotificationViewSet(ViewSet):
    permission_classes = [IsAuthenticated]
    message_counter = 0

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.mqtt_client = get_mqtt_client()

    def create(self, request):
        data = json.loads(request.body)
        title = data.get("title")
        body = data.get("body")
        user_ids = data.get("user_ids", None)  # optional targeting
        
        if not title and not body:
            return Response({"error": "Title or body are required"}, status=status.HTTP_400_BAD_REQUEST)

        message = Message.objects.create(title=title, body=body)

        if user_ids:
            recipients = User.objects.filter(id__in=user_ids)
        else:
            recipients = User.objects.all()

        for recipient in recipients:
            UserNotification.objects.create(message=message, recipient=recipient)

            # Send a notification via MQTT
            send_mqtt_message(self.mqtt_client, recipient, msg_id=message.id, title=title, body=body)

            # Send a notification to all registered Firebase devices if Firebase is installed
            if firebase_installed:
                devices = FCMDevice.objects.filter(user=recipient)
                devices.send_message(FCMMessage(notification=Notification(title=title, body=body)))

        return JsonResponse({"message": "Notifications sent successfully"})


class EMQXTokenViewSet(ViewSet):
    permission_classes = [IsAuthenticated]

    def create(self, request):
        user = request.user
        token = generate_mqtt_token(user)

        return Response({"mqtt_token": token, "user_id": str(user.id)})


class EMQXDeviceViewSet(ViewSet):
    def list(self, request):
        devices = EMQXDevice.objects.all()
        serializer = EMQXDeviceSerializer(devices, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

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