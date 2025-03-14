import time

from django.conf import settings

import paho.mqtt.client as mqtt

from notifications.utils import generate_backend_mqtt_token


class MQTTClient:
    def __init__(self, broker, port=1883, keepalive=60):
        mqtt_token = generate_backend_mqtt_token()
        self.client = mqtt.Client()
        self.client.username_pw_set(username='backend', password=mqtt_token)  # Use JWT as password
        for attempt in range(settings.MAX_RETRIES):
            try:
                print(f"🔄 Attempt {attempt + 1}: Connecting to MQTT broker...")
                self.client.connect(broker, port, keepalive)
                self.client.loop_start()
                print("✅ Successfully connected to MQTT broker!")
                return
            except ConnectionRefusedError:
                print(f"⏳ Connection refused, retrying in {settings.RETRY_DELAY} seconds...")
                time.sleep(settings.RETRY_DELAY)

        print("❌ Failed to connect after multiple attempts. Check EMQX logs.")

    def publish(self, topic, payload, qos=1):
        self.client.publish(topic, payload, qos)

    def disconnect(self):
        self.client.loop_stop()
        self.client.disconnect()
