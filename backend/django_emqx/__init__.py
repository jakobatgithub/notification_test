_mqtt_client = None

def get_mqtt_client():
    global _mqtt_client
    if _mqtt_client is None:
        from .conf import emqx_settings as settings
        from .mqtt import MQTTClient
        _mqtt_client = MQTTClient(broker=settings.DJANGO_EMQX['BROKER'], port=settings.DJANGO_EMQX['PORT'])
    return _mqtt_client