# Cocos Capital Balance Monitor

Scraper automático que hace login en Cocos Capital via Playwright (browser real, evita el bloqueo de Cloudflare) y guarda el `totalBalance` del portfolio en Google Sheets.

Corre cada día hábil a las **18:30 hora Argentina** (21:30 UTC).

## Setup

### 1. Google Sheets + Service Account

1. Ir a [Google Cloud Console](https://console.cloud.google.com)
2. Crear un nuevo proyecto (o usar uno existente)
3. Habilitar la **Google Sheets API**
4. Ir a **IAM & Admin > Service Accounts** y crear una nueva service account
5. Sin roles de IAM (solo necesita acceso al Sheet via compartir directo)
6. Crear una clave JSON para la service account y descargarla
7. Abrir el Google Sheet destino
8. Compartir el Sheet con el email de la service account (el campo `client_email` del JSON) con rol **Editor**
9. Copiar el ID del Sheet de la URL: `https://docs.google.com/spreadsheets/d/SHEET_ID_AQUI/edit`

### 2. GitHub Secrets

En el repositorio: **Settings > Secrets and variables > Actions > New repository secret**

| Secret | Valor |
|--------|-------|
| `COCOS_EMAIL` | `lcouretot@gmail.com` |
| `COCOS_PASSWORD` | Password de Cocos Capital |
| `GOOGLE_SHEETS_ID` | ID del Sheet (de la URL) |
| `GOOGLE_CREDENTIALS` | Contenido completo del archivo JSON de la service account |

Para `GOOGLE_CREDENTIALS`: abrir el archivo JSON descargado, copiar todo el contenido y pegarlo como valor del secret.

### 3. Formato del Google Sheet

El script agrega filas automáticamente:
- **Columna A**: Fecha en formato `DD/MM/YYYY`
- **Columna B**: `totalBalance` como número

No se necesitan headers; las filas se agregan al final.

## Trigger manual

Para probar sin esperar el cron: **Actions > Daily Balance Monitor > Run workflow**

## Test local

```bash
export COCOS_EMAIL="tu@email.com"
export COCOS_PASSWORD="tupassword"
export GOOGLE_SHEETS_ID="id_del_sheet"
export GOOGLE_CREDENTIALS='{"type":"service_account",...}'

pip install -r requirements.txt
playwright install chromium
python scraper.py
```

## Cómo funciona

1. Playwright lanza un browser Chromium headless
2. Navega a `https://app.cocos.capital` y hace login con el formulario web
3. Intercepta la llamada que la propia app hace a `api.cocos.capital/api/portfolio/balance`
4. Extrae `totalBalance` de la respuesta JSON
5. Agrega una fila con fecha y valor al Google Sheet
