import json
import os
from curl_cffi import requests
from datetime import datetime, timezone, timedelta

import gspread
from google.oauth2.service_account import Credentials

AUTH_URL = "https://auth.cocos.capital/auth/v1"
COCOS_API = "https://api.cocos.capital"
SUPABASE_ANON_KEY = (
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.ewogICJyb2xlIjogImFub24iLAogICJpc3MiO"
    "iAic3VwYWJhc2UiLAogICJpYXQiOiAxNzI0NzA5NjAwLAogICJleHAiOiAxODgyNDc2MDAwCn0"
    ".GieFvIDlSbRw6-KvFX8xPEzqzhXgIQ0Hc-ELKvrVirs"
)


def login(email, password, device_token):
    session = requests.Session(impersonate="chrome120")
    session.headers.update({
        "Content-Type": "application/json",
        "apikey": SUPABASE_ANON_KEY,
        "Origin": "https://app.cocos.capital",
        "Referer": "https://app.cocos.capital/",
    })

    # Step 1: login with email + password
    print("Autenticando con email/password...")
    resp = session.post(
        f"{AUTH_URL}/token?grant_type=password",
        json={"email": email, "password": password, "gotrue_meta_security": {}},
    )
    if not resp.ok:
        print(f"ERROR login {resp.status_code}: {resp.text}")
        resp.raise_for_status()
    token_data = resp.json()
    access_token = token_data["access_token"]
    print("Login OK, verificando dispositivo...")

    # Step 2: get a device challenge
    challenge_resp = session.post(
        f"{AUTH_URL}/factors/device/challenge",
        headers={"Authorization": f"Bearer {access_token}"},
        json={},
    )
    if not challenge_resp.ok:
        print(f"ERROR challenge {challenge_resp.status_code}: {challenge_resp.text}")
        challenge_resp.raise_for_status()
    challenge_id = challenge_resp.json()["id"]

    # Step 3: verify device with trusted device token
    verify_resp = session.post(
        f"{AUTH_URL}/factors/device/verify",
        headers={"Authorization": f"Bearer {access_token}"},
        json={"code": device_token, "challenge_id": challenge_id},
    )
    if not verify_resp.ok:
        print(f"ERROR verify {verify_resp.status_code}: {verify_resp.text}")
        verify_resp.raise_for_status()
    full_token = verify_resp.json()["access_token"]
    print("Dispositivo verificado.")
    return full_token


def get_balance(access_token, account_id):
    session = requests.Session(impersonate="chrome120")
    resp = session.get(
        f"{COCOS_API}/api/portfolio/balance?currency=ARS&period=MAX",
        headers={
            "Authorization": f"Bearer {access_token}",
            "x-account-id": account_id,
            "Origin": "https://app.cocos.capital",
            "Referer": "https://app.cocos.capital/",
        },
    )
    if not resp.ok:
        print(f"ERROR balance {resp.status_code}: {resp.text}")
        resp.raise_for_status()
    return resp.json()["totalBalance"]


def main():
    access_token = login(
        os.environ["COCOS_EMAIL"],
        os.environ["COCOS_PASSWORD"],
        os.environ["COCOS_DEVICE_TOKEN"],
    )

    total_balance = get_balance(access_token, os.environ["COCOS_ACCOUNT_ID"])
    print(f"totalBalance: {total_balance}")

    creds_info = json.loads(os.environ["GOOGLE_CREDENTIALS"])
    scopes = ["https://www.googleapis.com/auth/spreadsheets"]
    creds = Credentials.from_service_account_info(creds_info, scopes=scopes)
    client = gspread.authorize(creds)

    sheet = client.open_by_key(os.environ["GOOGLE_SHEETS_ID"]).sheet1
    ars = timezone(timedelta(hours=-3))
    date_str = datetime.now(ars).strftime("%d/%m/%Y")
    sheet.append_row([date_str, total_balance])
    print(f"Fila agregada: {date_str} | {total_balance}")


if __name__ == "__main__":
    main()
