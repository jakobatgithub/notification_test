## notifications/models/wagtail.py

from wagtail.admin.panels import FieldPanel
from wagtail.api import APIField
from wagtail.models import Orderable

from .base import BaseMessage, BaseNotification

class Message(BaseMessage):
    panels = [
        FieldPanel("title"),
        FieldPanel("body"),
    ]

    api_fields = [
        APIField("title"),
        APIField("body"),
        APIField("created_at"),
    ]

class Notification(Orderable, BaseNotification):
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
