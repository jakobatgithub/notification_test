## django_emqx/serializers.py

from rest_framework import serializers

from .models import EMQXDevice, UserNotification

class EMQXDeviceSerializer(serializers.ModelSerializer):
    """
    Serializer for the EMQXDevice model. Converts model instances into JSON format
    and validates incoming data for creating or updating EMQXDevice objects.
    """
    class Meta:
        model = EMQXDevice
        fields = ['id', 'user', 'client_id', 'active', 'last_status', 'last_connected_at']

class UserNotificationSerializer(serializers.ModelSerializer):
    """
    Serializer for the UserNotification model. Maps nested message fields (title and body)
    to flat fields in the serialized output.
    """
    title = serializers.CharField(source='message.title')
    body = serializers.CharField(source='message.body')

    class Meta:
        model = UserNotification
        fields = ['id', 'title', 'body', 'delivered_at']  # include other relevant fields