import asyncio
import json
import os
from datetime import datetime, timezone, timedelta

import gspread
from google.oauth2.service_account import Credentials
from playwright.async_api import async_playwright
from playwright_stealth import stealth_async


async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch(
            headless=True,
            args=[
                "--no-sandbox",
                "--disable-dev-shm-usage",
                "--disable-blink-features=AutomationControlled",
            ],
        )
        context = await browser.new_context(
            user_agent=(
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
                "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
            ),
            viewport={"width": 1280, "height": 720},
        )
        page = await context.new_page()
        await stealth_async(page)

        print("Navegando a Cocos Capital...")
        await page.goto("https://app.cocos.capital", wait_until="networkidle", timeout=60000)

        # Esperar hasta 60s a que aparezca el campo email
        print("Esperando formulario de login...")
        try:
            await page.wait_for_selector('input[type="email"]', timeout=60000)
        except Exception:
            await page.screenshot(path="debug_login.png", full_page=True)
            print("ERROR: no apareció el formulario. Screenshot guardado en debug_login.png")
            print(f"URL actual: {page.url}")
            print(f"Título: {await page.title()}")
            raise

        async with page.expect_response(
            lambda r: "api.cocos.capital/api/portfolio/balance" in r.url
            and r.status == 200,
            timeout=60000,
        ) as response_info:
            await page.fill('input[type="email"]', os.environ["COCOS_EMAIL"])
            await page.fill('input[type="password"]', os.environ["COCOS_PASSWORD"])
            await page.click('button[type="submit"]')
            await page.wait_for_load_state("networkidle", timeout=60000)

        response = await response_info.value
        data = await response.json()
        total_balance = data["totalBalance"]
        print(f"totalBalance: {total_balance}")

        await browser.close()

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
    asyncio.run(main())
