#!/usr/bin/env python3
"""Escribe un balance en Google Sheets y muestra el historial."""

import json
import os
from datetime import datetime, timezone, timedelta

import gspread
from google.oauth2.service_account import Credentials

SCOPES = ["https://www.googleapis.com/auth/spreadsheets"]
ARS = timezone(timedelta(hours=-3))


def get_sheet():
    creds_info = json.loads(os.environ["GOOGLE_CREDENTIALS"])
    creds = Credentials.from_service_account_info(creds_info, scopes=SCOPES)
    client = gspread.authorize(creds)
    return client.open_by_key(os.environ["GOOGLE_SHEETS_ID"]).sheet1


def main():
    balance = float(os.environ["BALANCE"])
    sheet = get_sheet()

    date_str = datetime.now(ARS).strftime("%d/%m/%Y")
    sheet.append_row([date_str, balance])
    print(f"Fila agregada: {date_str} | {balance}")

    # Leer todo el historial para mostrarlo
    rows = sheet.get_all_values()
    print(f"\nHistorial completo ({len(rows)} registros):")
    for row in rows:
        print(f"  {row[0]}  →  {row[1]}")


if __name__ == "__main__":
    main()
