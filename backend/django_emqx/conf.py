## django_emqx/conf.py

import os

from django.conf import settings


DJANGO_EMQX_DEFAULTS = {
    'BROKER': "emqx_broker",
    'PORT': 8883,
    'WEBHOOK_SECRET': os.environ.get("EMQX_WEBHOOK_SECRET"),
    'MAX_RETRIES': 10,  # Maximum retry attempts,
    'RETRY_DELAY': 3,   # Wait time in seconds before retrying
}

class EMQXSettings:
    def __init__(self):
        user_settings = getattr(settings, "DJANGO_EMQX", {}) or {}
        self.DJANGO_EMQX = {**DJANGO_EMQX_DEFAULTS, **user_settings}

emqx_settings = EMQXSettings()
print(f"EMQX settings: {emqx_settings.__dict__}")