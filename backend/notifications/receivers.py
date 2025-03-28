## notifications/receivers.py

import json

from django.dispatch import receiver
from django.contrib.auth import get_user_model

from django_emqx.signals import emqx_device_connected, new_emqx_device_connected, emqx_device_disconnected
from django_emqx.utils import send_mqtt_message
from django_emqx.models import Message


@receiver(emqx_device_connected)
def handle_emqx_device_connected(sender, user_id, device_id, ip_address, **kwargs):
    user = get_user_model().objects.filter(id=int(user_id)).first()
    print(f"User {user} connected on device {device_id} (IP: {ip_address})")
    recipients = get_user_model().objects.all()
    data = json.dumps({
        "device_id": device_id,
        "userID": user.id,
        "event": "device_connected",
    })
    message = Message.objects.create(data=data)
    for recipient in recipients:
        send_mqtt_message(recipient, message)

@receiver(new_emqx_device_connected)
def handle_new_emqx_device_connected(sender, user_id, device_id, ip_address, **kwargs):
    user = get_user_model().objects.filter(id=int(user_id)).first()
    print(f"User {user} connected on new device {device_id} (IP: {ip_address})")
    recipients = get_user_model().objects.all()
    data = json.dumps({
        "device_id": device_id,
        "userID": user.id,
        "event": "new_device_disconnected",
    })
    message = Message.objects.create(data=data)
    for recipient in recipients:
        send_mqtt_message(recipient, message)


@receiver(emqx_device_disconnected)
def handle_emqx_device_disconnected(sender, user_id, device_id, ip_address, **kwargs):
    user = get_user_model().objects.filter(id=int(user_id)).first()
    print(f"User {user} disconnected from device {device_id}")
    recipients = get_user_model().objects.all()
    data = json.dumps({
        "device_id": device_id,
        "userID": user.id,
        "event": "device_disconnected",
    })
    message = Message.objects.create(data=data)
    for recipient in recipients:
        send_mqtt_message(recipient, message)
