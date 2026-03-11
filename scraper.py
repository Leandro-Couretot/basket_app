import json
import os
import requests
from datetime import datetime, timezone, timedelta

import gspread
from google.oauth2.service_account import Credentials

AUTH_URL = "https://auth.cocos.capital/auth/v1"
COCOS_API = "https://api.cocos.capital"


def login(email, password, device_token):
    session = requests.Session()
    session.headers.update({
        "Content-Type": "application/json",
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36",
        "Origin": "https://app.cocos.capital",
        "Referer": "https://app.cocos.capital/",
    })

    # Step 1: login with email + password
    print("Autenticando con email/password...")
    resp = session.post(
        f"{AUTH_URL}/token?grant_type=password",
        json={"email": email, "password": password, "gotrue_meta_security": {}},
    )
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
    challenge_resp.raise_for_status()
    challenge_id = challenge_resp.json()["id"]

    # Step 3: verify device with trusted device token
    verify_resp = session.post(
        f"{AUTH_URL}/factors/device/verify",
        headers={"Authorization": f"Bearer {access_token}"},
        json={"code": device_token, "challenge_id": challenge_id},
    )
    verify_resp.raise_for_status()
    full_token = verify_resp.json()["access_token"]
    print("Dispositivo verificado.")
    return full_token


def get_balance(access_token, account_id):
    resp = requests.get(
        f"{COCOS_API}/api/portfolio/balance?currency=ARS&period=MAX",
        headers={
            "Authorization": f"Bearer {access_token}",
            "x-account-id": account_id,
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36",
            "Origin": "https://app.cocos.capital",
            "Referer": "https://app.cocos.capital/",
        },
    )
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
