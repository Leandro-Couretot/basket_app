#!/usr/bin/env python3
"""Lee el historial de Google Sheets y genera un reporte markdown."""

import json
import os
from datetime import datetime, timezone, timedelta

import gspread
from google.oauth2.service_account import Credentials

SCOPES = ["https://www.googleapis.com/auth/spreadsheets"]
ARS = timezone(timedelta(hours=-3))


def get_history():
    creds_info = json.loads(os.environ["GOOGLE_CREDENTIALS"])
    creds = Credentials.from_service_account_info(creds_info, scopes=SCOPES)
    client = gspread.authorize(creds)
    sheet = client.open_by_key(os.environ["GOOGLE_SHEETS_ID"]).sheet1
    return sheet.get_all_values()


def parse_records(rows):
    parsed = []
    for row in rows:
        if len(row) >= 2:
            try:
                balance = float(str(row[1]).replace(",", "."))
                parsed.append((row[0].strip(), balance))
            except ValueError:
                continue
    return parsed


def sparkline(values, width=40):
    bars = "▁▂▃▄▅▆▇█"
    recent = values[-width:]
    min_v, max_v = min(recent), max(recent)
    if max_v == min_v:
        return bars[4] * len(recent)
    return "".join(bars[int((v - min_v) / (max_v - min_v) * 7)] for v in recent)


def fmt_ars(amount):
    s = f"{amount:,.2f}"
    return "$" + s.replace(",", "X").replace(".", ",").replace("X", ".")


def generate_report(records):
    if not records:
        return "# Sin datos históricos disponibles."

    dates = [r[0] for r in records]
    balances = [r[1] for r in records]

    current = balances[-1]
    first = balances[0]
    max_b = max(balances)
    min_b = min(balances)
    change_abs = current - first
    change_pct = (change_abs / first * 100) if first else 0
    trend = "📈" if change_abs >= 0 else "📉"
    chart = sparkline(balances)
    now = datetime.now(ARS).strftime("%d/%m/%Y %H:%M")

    lines = [
        f"# {trend} Balance Cocos Capital",
        "",
        f"> Reporte generado automáticamente por **GitHub Actions** — {now} ART",
        "",
        "## Balance actual",
        "",
        "| Métrica | Valor |",
        "|:--------|------:|",
        f"| **Balance actual** | **{fmt_ars(current)}** |",
        f"| Variación total | {fmt_ars(change_abs)} ({change_pct:+.2f}%) |",
        f"| Máximo histórico | {fmt_ars(max_b)} |",
        f"| Mínimo histórico | {fmt_ars(min_b)} |",
        f"| Días registrados | {len(balances)} |",
        f"| Primer registro | {dates[0]} |",
        "",
        "## Evolución",
        "",
        "```",
        chart,
        "```",
        f"*Últimos {min(40, len(balances))} registros*",
        "",
        "## Últimos 10 días",
        "",
        "| Fecha | Balance | Variación |",
        "|:------|--------:|----------:|",
    ]

    recent = list(zip(dates, balances))[-10:]
    for i, (date, balance) in enumerate(recent):
        if i > 0:
            prev = recent[i - 1][1]
            var = balance - prev
            var_str = f"{fmt_ars(var)} ({var / prev * 100:+.2f}%)" if prev else "—"
        else:
            var_str = "—"
        lines.append(f"| {date} | {fmt_ars(balance)} | {var_str} |")

    lines += [
        "",
        "---",
        "*Datos almacenados en Google Sheets · Automatizado con GitHub Actions*",
    ]

    return "\n".join(lines)


if __name__ == "__main__":
    rows = get_history()
    records = parse_records(rows)
    report = generate_report(records)

    with open("report.md", "w") as f:
        f.write(report)

    print(f"Reporte generado: {len(records)} registros encontrados.")
    print("---")
    print(report[:1000])
