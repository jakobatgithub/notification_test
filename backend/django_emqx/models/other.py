## django_emqx/models/other.py

from django.db import models
from django.contrib.auth import get_user_model

class EMQXDevice(models.Model):
    """
    Represents an EMQX MQTT device associated with a user.

    Fields:
        id (AutoField): Primary key for the device.
        client_id (CharField): Unique identifier for the MQTT client.
        active (BooleanField): Indicates whether the device is active.
        user (ForeignKey): Reference to the user owning the device.
        last_connected_at (DateTimeField): Timestamp of the last successful connection.
        last_status (CharField): Last known status of the device (e.g., online, offline, error).
        subscribed_topics (TextField): Comma-separated list of topics the device subscribes to.
        ip_address (GenericIPAddressField): Last known IP address of the device.
        created_at (DateTimeField): Timestamp when the device was created.
    """
    id = models.AutoField(
        verbose_name="ID",
        primary_key=True,
        auto_created=True,
    )
    client_id = models.CharField(
        verbose_name="MQTT Client ID",
        max_length=255,
        unique=True,
        help_text="Unique identifier for the MQTT client"
    )
    active = models.BooleanField(
        verbose_name="Is active",
        default=True,
        help_text="Indicates whether the device is active"
    )
    user = models.ForeignKey(
        get_user_model(),
        blank=True,
        null=True,
        on_delete=models.CASCADE,
        related_name="mqtt_devices",
    )
    last_connected_at = models.DateTimeField(
        verbose_name="Last connected at",
        null=True,
        blank=True,
        help_text="Timestamp of the last successful connection"
    )
    last_status = models.CharField(
        verbose_name="Last known status",
        max_length=20,
        choices=[("online", "Online"), ("offline", "Offline"), ("error", "Error")],
        default="offline",
        help_text="Last known status of the device"
    )
    subscribed_topics = models.TextField(
        verbose_name="Subscribed Topics",
        blank=True,
        help_text="Comma-separated list of topics the device subscribes to"
    )
    ip_address = models.GenericIPAddressField(
        verbose_name="Last known IP address",
        blank=True,
        null=True,
        help_text="Last known IP address of the device"
    )
    created_at = models.DateTimeField(
        verbose_name="Creation date", auto_now_add=True, null=True
    )

    def __str__(self):
        return f"{self.client_id} ({'Active' if self.active else 'Inactive'}) - {self.ip_address or 'No IP'}"
