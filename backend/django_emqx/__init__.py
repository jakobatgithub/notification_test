_mqtt_client = None

def get_mqtt_client():
    global _mqtt_client
    if _mqtt_client is None:
        from .conf import emqx_settings
        from .mqtt import MQTTClient
        _mqtt_client = MQTTClient(broker=emqx_settings.EMQX_BROKER, port=emqx_settings.EMQX_PORT)
    return _mqtt_client