import time

from django.conf import settings

import paho.mqtt.client as mqtt

from .utils import generate_backend_mqtt_token


class MQTTClient:
    def __init__(self, broker, port=1883, keepalive=60):
        self.client = mqtt.Client()
        self.client.tls_set("certs/ca.crt")
        self.client.tls_insecure_set(True)
        self.client.on_connect = self.on_connect
        self.client.on_disconnect = self.on_disconnect

        mqtt_token = generate_backend_mqtt_token()
        self.client.username_pw_set(username='backend', password=mqtt_token)  # Use JWT as password
        
        for attempt in range(settings.MAX_RETRIES):
            try:
                print(f"🔄 Attempt {attempt + 1}: Connecting to MQTT broker...")
                self.client.connect_async(broker, port, keepalive)
                self.client.loop_start()
                print("✅ Successfully connected to MQTT broker!")
                return
            except ConnectionRefusedError:
                print(f"⏳ Connection refused, retrying in {settings.RETRY_DELAY} seconds...")
                time.sleep(settings.RETRY_DELAY)

        print("❌ Failed to connect after multiple attempts. Check EMQX logs.")

    def on_connect(self, client, userdata, flags, rc):
        if rc == 0:
            print("✅ MQTT connected successfully")
        else:
            print(f"❌ MQTT failed to connect, return code {rc}")

    def on_disconnect(self, client, userdata, rc):
        print("🔄 MQTT disconnected, attempting to reconnect...")
        self.client.reconnect()  # Automatically try to reconnect

    def publish(self, topic, payload, qos=1):
        self.client.publish(topic, payload, qos)

    def disconnect(self):
        self.client.loop_stop()
        self.client.disconnect()
