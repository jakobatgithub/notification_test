from rest_framework import serializers

from .models import EMQXDevice

class EMQXDeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = EMQXDevice
        fields = ["id", "client_id", "active", "last_status", "last_connected_at"]
