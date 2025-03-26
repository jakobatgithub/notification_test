_mqtt_client = None

def get_mqtt_client():
    global _mqtt_client
    if _mqtt_client is None:
        from .mqtt import MQTTClient
        from django.conf import settings
        _mqtt_client = MQTTClient(broker=settings.EMQX_BROKER, port=settings.EMQX_PORT)
    return _mqtt_client