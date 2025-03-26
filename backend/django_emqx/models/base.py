## notifications/models/base.py

from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()

class BaseMessage(models.Model):
    title = models.CharField(max_length=255)
    body = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        abstract = True

class BaseNotification(models.Model):
    message = models.ForeignKey('notifications.Message', on_delete=models.CASCADE, related_name='notifications')
    recipient = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    delivered_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        abstract = True