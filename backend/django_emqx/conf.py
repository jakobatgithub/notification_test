## django_emqx/conf.py

from django.conf import settings


DEFAULTS = {
    'EMQX_BROKER': "emqx_broker",
    'EMQX_PORT': 8883,
    'EMQX_WEBHOOK_SECRET': settings.SECRET_KEY,
    'EMQX_MAX_RETRIES': 10,  # Maximum retry attempts,
    'EMQX_RETRY_DELAY': 3,   # Wait time in seconds before retrying
}

class EMQXSettings:
    def __getattr__(self, attr):
        if attr not in DEFAULTS:
            raise AttributeError(f"Invalid EMQX setting: '{attr}'")

        return getattr(settings, attr, DEFAULTS[attr])

emqx_settings = EMQXSettings()