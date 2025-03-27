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
    """
    Mixin to handle sending notifications to users via MQTT and Firebase.
    """

    def send_all_notifications(self, message, recipients, mqtt_client, title, body):
        """
        Send notifications to all recipients via MQTT and Firebase (if available).

        Args:
            message (UserNotification): The notification message to send.
            recipients (QuerySet): A queryset of recipient users.
            mqtt_client (object): The MQTT client instance.
            title (str): The title of the notification.
            body (str): The body of the notification.
        """
        for recipient in recipients:
            UserNotification.objects.create(message=message, recipient=recipient)

            # Send a notification via MQTT
            send_mqtt_message(mqtt_client, recipient, msg_id=message.id, title=title, body=body)

            # Send a notification to Firebase devices if Firebase is installed
            if firebase_installed:
                devices = FCMDevice.objects.filter(user=recipient)
                devices.send_message(FCMMessage(notification=Notification(title=title, body=body)))


class ClientEventMixin:
    """
    Mixin to handle client connection and disconnection events.
    """

    def handle_client_connected(self, user_id, device_id, ip_address=None):
        """
        Handle the event when a client connects.

        Args:
            user_id (int): The ID of the user associated with the client.
            device_id (str): The unique identifier of the device.
            ip_address (str, optional): The IP address of the client. Defaults to None.
        """
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
        """
        Handle the event when a client disconnects.

        Args:
            user_id (int): The ID of the user associated with the client.
            device_id (str): The unique identifier of the device.
        """
        user = get_user_model().objects.filter(id=int(user_id)).first()
        if not user:
            return

        updated = EMQXDevice.objects.filter(client_id=device_id, user=user).update(
            active=False,
            last_status="offline",
        )

        if updated:
            print(f"User {user} disconnected from device {device_id}")
