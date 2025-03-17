from rest_framework import serializers

from .models import MQTTDevice

class MQTTDeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = MQTTDevice
        fields = ["id", "client_id", "active", "last_status", "last_connected_at"]
