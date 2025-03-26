## notifications/models/base.py

from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()

class BaseMessage(models.Model):
    title = models.CharField(max_length=255)
    body = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sent_messages', blank=True, null=True)

    class Meta:
        abstract = True

class BaseNotification(models.Model):
    message = models.ForeignKey('django_emqx.Message', on_delete=models.CASCADE, related_name='notifications')
    recipient = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    delivered_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        abstract = True


# Concrete Django versions of the models
class Message(BaseMessage):
    class Meta:
        abstract = False

class UserNotification(BaseNotification):
    class Meta:
        abstract = False
