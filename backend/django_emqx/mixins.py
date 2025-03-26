## django_emqx/mixins.py

from django.utils import timezone
from django.contrib.auth import get_user_model

# Check if Firebase is available
try:
    from fcm_django.models import FCMDevice
    from firebase_admin.messaging import Notification, Message as FCMMessage
    firebase_installed = True
except ImportError:
    firebase_installed = False

from .models import UserNotification, EMQXDevice
from .utils import send_mqtt_message


class NotificationSenderMixin:
    def send_all_notifications(self, message, recipients, mqtt_client, title, body):
        for recipient in recipients:
            UserNotification.objects.create(message=message, recipient=recipient)

            # Send a notification via MQTT
            send_mqtt_message(mqtt_client, recipient, msg_id=message.id, title=title, body=body)

            # Send a notification to Firebase devices if Firebase is installed
            if firebase_installed:
                devices = FCMDevice.objects.filter(user=recipient)
                devices.send_message(FCMMessage(notification=Notification(title=title, body=body)))


class ClientEventMixin:
    def handle_client_connected(self, user_id, device_id, ip_address=None):
        user = get_user_model().objects.filter(id=int(user_id)).first()
        if not user:
            return

        EMQXDevice.objects.update_or_create(
            client_id=device_id,
            defaults={
                "user": user,
                "active": True,
                "last_status": "online",
                "last_connected_at": timezone.now(),
                "ip_address": ip_address,
            },
        )
        print(f"User {user} connected on device {device_id} (IP: {ip_address})")

    def handle_client_disconnected(self, user_id, device_id):
        user = get_user_model().objects.filter(id=int(user_id)).first()
        if not user:
            return

        updated = EMQXDevice.objects.filter(client_id=device_id, user=user).update(
            active=False,
            last_status="offline",
        )

        if updated:
            print(f"User {user_id} disconnected from device {device_id}")
