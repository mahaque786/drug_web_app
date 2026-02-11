# Google Apps Script setup

1. Open your Google Sheet.
2. Click **Extensions → Apps Script**.
3. Paste in the code from `google-apps-script.js`.
4. Update `SHEET_NAME` if your tab is not named `Sheet1`.
5. Save.
6. Deploy as Web App:
   - **Deploy → New deployment → Web app**
   - Execute as: **Me**
   - Who has access: **Anyone** (or Anyone with link)
7. Copy the web app URL and paste it into the app's **Apps Script Web App URL** field.
8. Click **Save URL** in the app.

## API contract used by the web app

- `GET <WEB_APP_URL>?action=logs`
  - returns `{ success: true, logs: [{ timestamp, medicationName, dose, reason }] }`

- `POST <WEB_APP_URL>` with JSON body:
  - `{ "action": "log", "medicationName": "...", "dose": 10, "reason": "..." }`
  - returns `{ success: true, logged: { timestamp, medicationName, dose, reason } }`
