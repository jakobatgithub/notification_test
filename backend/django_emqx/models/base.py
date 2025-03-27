## notifications/models/base.py

from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()

class BaseMessage(models.Model):
    """
    Abstract base model for messages.

    Fields:
        - title: The title of the message.
        - body: The body content of the message.
        - created_at: Timestamp when the message was created.
        - created_by: The user who created the message (optional).
    """
    title = models.CharField(max_length=255)
    body = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sent_messages', blank=True, null=True)

    class Meta:
        abstract = True

class BaseNotification(models.Model):
    """
    Abstract base model for notifications.

    Fields:
        - message: The related message for the notification.
        - recipient: The user who is the recipient of the notification.
        - delivered_at: Timestamp when the notification was delivered.
    """
    message = models.ForeignKey('django_emqx.Message', on_delete=models.CASCADE, related_name='notifications')
    recipient = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    delivered_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        abstract = True


# Concrete Django versions of the models
class Message(BaseMessage):
    """
    Concrete implementation of BaseMessage.
    """
    class Meta:
        abstract = False

class UserNotification(BaseNotification):
    """
    Concrete implementation of BaseNotification.
    """
    class Meta:
        abstract = False
