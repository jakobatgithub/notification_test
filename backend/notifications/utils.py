import urllib.request
import json
import base64

from django.conf import settings

def get_emqx_clients():
    username = settings.EMQX_API_KEY
    password = settings.EMQX_API_SECRET
    
    url = f"{settings.EMQX_BROKER_URL}/api/v5/clients"

    req = urllib.request.Request(url)
    req.add_header('Content-Type', 'application/json')

    auth_header = "Basic " + base64.b64encode((username + ":" + password).encode()).decode()
    req.add_header('Authorization', auth_header)

    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read().decode())

    return data