## django_emqx/mqtt.py

import time

from django.conf import settings

import paho.mqtt.client as mqtt

from .utils import generate_backend_mqtt_token


class MQTTClient:
    """
    A wrapper class for managing MQTT client connections, publishing messages, 
    and handling reconnections using the Paho MQTT library.
    """

    def __init__(self, broker, port=1883, keepalive=60):
        """
        Initialize the MQTT client and attempt to connect to the broker.

        Args:
            broker (str): The MQTT broker address.
            port (int, optional): The port to connect to. Defaults to 1883.
            keepalive (int, optional): The keepalive interval in seconds. Defaults to 60.
        """
        self.client = mqtt.Client()
        self.client.tls_set("certs/ca.crt")
        self.client.tls_insecure_set(True)
        self.client.on_connect = self.on_connect
        self.client.on_disconnect = self.on_disconnect

        mqtt_token = generate_backend_mqtt_token()
        self.client.username_pw_set(username='backend', password=mqtt_token)  # Use JWT as password
        
        for attempt in range(settings.DJANGO_EMQX['MAX_RETRIES']):
            try:
                print(f"🔄 Attempt {attempt + 1}: Connecting to MQTT broker...")
                self.client.connect_async(broker, port, keepalive)
                self.client.loop_start()
                print("✅ Successfully connected to MQTT broker!")
                return
            except ConnectionRefusedError:
                print(f"⏳ Connection refused, retrying in {settings.settings.DJANGO_EMQX['RETRY_DELAY']} seconds...")
                time.sleep(settings.settings.DJANGO_EMQX['RETRY_DELAY'])

        print("❌ Failed to connect after multiple attempts. Check EMQX logs.")

    def on_connect(self, client, userdata, flags, rc):
        """
        Callback for when the client connects to the broker.

        Args:
            client: The MQTT client instance.
            userdata: User-defined data of any type.
            flags: Response flags sent by the broker.
            rc (int): The connection result code.
        """
        if rc == 0:
            print("✅ MQTT connected successfully")
        else:
            print(f"❌ MQTT failed to connect, return code {rc}")

    def on_disconnect(self, client, userdata, rc):
        """
        Callback for when the client disconnects from the broker.

        Args:
            client: The MQTT client instance.
            userdata: User-defined data of any type.
            rc (int): The disconnection result code.
        """
        print("🔄 MQTT disconnected, attempting to reconnect...")
        self.client.reconnect()  # Automatically try to reconnect

    def publish(self, topic, payload, qos=1):
        """
        Publish a message to a specific MQTT topic.

        Args:
            topic (str): The topic to publish the message to.
            payload (str): The message payload.
            qos (int, optional): The Quality of Service level. Defaults to 1.
        """
        self.client.publish(topic, payload, qos)

    def disconnect(self):
        """
        Disconnect the MQTT client and stop the network loop.
        """
        self.client.loop_stop()
        self.client.disconnect()
