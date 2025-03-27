## notifications/models/wagtail.py

from wagtail.admin.panels import FieldPanel
from wagtail.api import APIField
from wagtail.models import Orderable

from .base import BaseMessage, BaseNotification

class Message(BaseMessage):
    """
    Represents a message with a title and body, inheriting from BaseMessage.
    Includes panels for editing and API fields for serialization.
    This model is only used if Wagtail is installed.
    """
    panels = [
        FieldPanel("title"),
        FieldPanel("body"),
    ]

    api_fields = [
        APIField("title"),
        APIField("body"),
        APIField("created_at"),
    ]

class UserNotification(Orderable, BaseNotification):
    """
    Represents a user notification, linking a recipient to a message.
    Tracks delivery time and supports editing and API serialization.
    This model is only used if Wagtail is installed.
    """
    panels = [
        FieldPanel("recipient"),
        FieldPanel("message"),
        FieldPanel("delivered_at", read_only=True),
    ]

    api_fields = [
        APIField("recipient"),
        APIField("message"),
        APIField("delivered_at"),
    ]
