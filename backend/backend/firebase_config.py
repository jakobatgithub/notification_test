import firebase_admin
from firebase_admin import credentials, messaging

cred = credentials.Certificate("backend/prosumiotest-firebase-adminsdk-9nzkc-13375b0089.json")
firebase_admin.initialize_app(cred)