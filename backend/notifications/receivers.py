## notifications/receivers.py

import json

from django.dispatch import receiver
from django.contrib.auth import get_user_model

from django_emqx.signals import emqx_device_connected, new_emqx_device_connected, emqx_device_disconnected
from django_emqx.utils import send_mqtt_message
from django_emqx.models import Message

User = get_user_model()


@receiver(emqx_device_connected)
def handle_emqx_device_connected(sender, user_id, client_id, ip_address, **kwargs):
    user = User.objects.filter(id=int(user_id)).first()
    active_users = User.objects.filter(emqx_devices__active=True).distinct()
    print(f"User {user} connected on device {client_id} (IP: {ip_address})")
    data = json.dumps({
        "client_id": client_id,
        "user": user.id,
        "event": "device_connected",
    })
    message = Message.objects.create(data=data)
    for recipient in active_users:
        send_mqtt_message(recipient, message)

@receiver(new_emqx_device_connected)
def handle_new_emqx_device_connected(sender, user_id, client_id, ip_address, **kwargs):
    user = User.objects.filter(id=int(user_id)).first()
    print(f"User {user} connected on new device {client_id} (IP: {ip_address})")
    active_users = User.objects.filter(emqx_devices__active=True).distinct()
    data = json.dumps({
        "client_id": client_id,
        "user": user.id,
        "event": "new_device_connected",
    })
    message = Message.objects.create(data=data)
    for recipient in active_users:
        send_mqtt_message(recipient, message)


@receiver(emqx_device_disconnected)
def handle_emqx_device_disconnected(sender, user_id, client_id, ip_address, **kwargs):
    user = User.objects.filter(id=int(user_id)).first()
    print(f"User {user} disconnected from device {client_id}")
    active_users = User.objects.filter(emqx_devices__active=True).distinct()
    data = json.dumps({
        "client_id": client_id,
        "user": user.id,
        "event": "device_disconnected",
    })
    message = Message.objects.create(data=data)
    for recipient in active_users:
        send_mqtt_message(recipient, message)
