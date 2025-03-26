## django_emqx/serializers.py

from rest_framework import serializers

from .models import EMQXDevice, UserNotification

class EMQXDeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = EMQXDevice
        fields = ['id', 'client_id', 'active', 'last_status', 'last_connected_at']

class UserNotificationSerializer(serializers.ModelSerializer):
    title = serializers.CharField(source='message.title')
    body = serializers.CharField(source='message.body')

    class Meta:
        model = UserNotification
        fields = ['id', 'title', 'body', 'delivered_at']  # include other relevant fields