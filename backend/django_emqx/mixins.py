## django_emqx/mixins.py

# Check if Firebase is available
try:
    from fcm_django.models import FCMDevice
    from firebase_admin.messaging import Notification, Message as FCMMessage
    firebase_installed = True
except ImportError:
    firebase_installed = False

from .models import UserNotification
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
