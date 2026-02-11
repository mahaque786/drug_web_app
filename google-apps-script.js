/**
 * Google Apps Script for medication logger.
 *
 * Sheet headers expected in row 1:
 * Timestamp | Medication Name (Generic + Formulation) | Dose | Reason
 */

const SHEET_NAME = 'Sheet1';

function doGet(e) {
  const action = (e && e.parameter && e.parameter.action) || '';

  if (action === 'logs') {
    return jsonResponse({ success: true, logs: getLogs_() });
  }

  return jsonResponse({
    success: false,
    error: 'Unsupported action. Use ?action=logs'
  });
}

function doPost(e) {
  try {
    const body = e && e.postData && e.postData.contents ? JSON.parse(e.postData.contents) : {};

    if (body.action !== 'log') {
      return jsonResponse({ success: false, error: 'Unsupported action. Use action="log".' });
    }

    const medicationName = String(body.medicationName || '').trim();
    const dose = Number(body.dose);
    const reason = String(body.reason || '').trim();

    if (!medicationName || !dose || dose <= 0 || !reason) {
      return jsonResponse({ success: false, error: 'Missing or invalid medicationName, dose, or reason.' });
    }

    const sheet = getSheet_();
    const timestamp = new Date();

    sheet.appendRow([
      timestamp,
      medicationName,
      dose,
      reason
    ]);

    return jsonResponse({
      success: true,
      logged: {
        timestamp: timestamp.toISOString(),
        medicationName: medicationName,
        dose: dose,
        reason: reason
      }
    });
  } catch (error) {
    return jsonResponse({
      success: false,
      error: error.message
    });
  }
}

function getLogs_() {
  const sheet = getSheet_();
  const values = sheet.getDataRange().getValues();
  if (values.length <= 1) return [];

  const rows = values.slice(1);
  return rows
    .filter(function (row) {
      return row[0] || row[1] || row[2] || row[3];
    })
    .map(function (row) {
      return {
        timestamp: row[0] instanceof Date ? row[0].toISOString() : String(row[0] || ''),
        medicationName: String(row[1] || ''),
        dose: Number(row[2]) || 0,
        reason: String(row[3] || '')
      };
    });
}

function getSheet_() {
  const spreadsheet = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = spreadsheet.getSheetByName(SHEET_NAME);
  if (!sheet) {
    throw new Error('Sheet not found: ' + SHEET_NAME);
  }
  return sheet;
}

function jsonResponse(obj) {
  return ContentService
    .createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
