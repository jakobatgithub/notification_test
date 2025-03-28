## notifications/receivers.py

from django.dispatch import receiver
from django.contrib.auth import get_user_model

from django_emqx.signals import emqx_device_connected, new_emqx_device_connected, emqx_device_disconnected

@receiver(emqx_device_connected)
def handle_emqx_device_connected(sender, user_id, device_id, ip_address, **kwargs):
    user = get_user_model().objects.filter(id=int(user_id)).first()
    print(f"User {user} connected on device {device_id} (IP: {ip_address})")

@receiver(new_emqx_device_connected)
def handle_new_emqx_device_connected(sender, user_id, device_id, ip_address, **kwargs):
    user = get_user_model().objects.filter(id=int(user_id)).first()
    print(f"User {user} connected on new device {device_id} (IP: {ip_address})")

@receiver(emqx_device_disconnected)
def handle_emqx_device_disconnected(sender, user_id, device_id, ip_address, **kwargs):
    user = get_user_model().objects.filter(id=int(user_id)).first()
    print(f"User {user} disconnected from device {device_id}")