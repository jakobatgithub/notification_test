## django_emqx/models/__init__.py

from .other import EMQXDevice

try:
    from .wagtail import Message, Notification
except ImportError:
    from .base import BaseMessage as Message, BaseNotification as Notification
