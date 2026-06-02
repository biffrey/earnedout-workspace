<?php
// ============================================================================
// SMB Steward — Airtable relay
// ----------------------------------------------------------------------------
// The dashboard (index.html) calls this script. This script:
//   1. Reads the token from config.php (server-side only).
//   2. Fetches all records from the Master Deal Pipeline (paginated).
//   3. Reshapes each record so the dashboard's existing JS can consume it.
//   4. Returns one combined JSON document.
//
// Same-origin call (no CORS needed). The .htaccess on the folder also
// password-protects this endpoint via HTTP Basic Auth.
// ============================================================================

require __DIR__ . '/config.php';

// Make sure browsers and any CDN/cache layer never serve stale data.
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('Pragma: no-cache');
header('Content-Type: application/json; charset=utf-8');

// Optional shared-secret check (skipped when the placeholder hasn't been changed).
if (defined('RELAY_SHARED_SECRET')
    && RELAY_SHARED_SECRET !== ''
    && RELAY_SHARED_SECRET !== 'OPTIONAL_RELAY_SECRET_HERE') {
    $sent = isset($_SERVER['HTTP_X_RELAY_SECRET']) ? $_SERVER['HTTP_X_RELAY_SECRET'] : '';
    if (!hash_equals(RELAY_SHARED_SECRET, $sent)) {
        http_response_code(403);
        echo json_encode(['error' => 'forbidden']);
        exit;
    }
}

// Fields the dashboard renders. Listed by Airtable field ID for stability
// against field renames in the base.
$fields = [
    'fldquYtYnHJ1YzUR7', // Business Name
    'fld2ipICYNLjaDm39', // Lead Score
    'fldyJH0ZsOJD29wEg', // Industry Match
    'fldkVBunWYKdXkgpB', // Business Address
    'fldhqAXiAWh2ktXln', // Asking Price
    'fldw0xk1YBkmP7sBD', // Disposition
    'fldiGyXTk6Ybb6J1L', // Source
    'fldTRaz0PzBYS9ICl', // Website
    'fld9InVXs4RqgtNDo', // Prospect Eval Report
];

$all = [];
$offset = '';
$maxPages = 25; // safety cap; 400 records / 100 per page = 4 pages typical

for ($p = 0; $p < $maxPages; $p++) {
    $qs = [
        'pageSize'              => 100,
        'returnFieldsByFieldId' => 'true',
    ];
    foreach ($fields as $i => $f) {
        $qs["fields[$i]"] = $f;
    }
    if ($offset !== '') {
        $qs['offset'] = $offset;
    }
    $url = 'https://api.airtable.com/v0/' . AIRTABLE_BASE . '/' . AIRTABLE_TABLE
         . '?' . http_build_query($qs);

    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER     => ['Authorization: Bearer ' . AIRTABLE_TOKEN],
        CURLOPT_TIMEOUT        => 25,
        CURLOPT_CONNECTTIMEOUT => 8,
    ]);
    $body   = curl_exec($ch);
    $status = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $err    = curl_error($ch);
    curl_close($ch);

    if ($body === false || $status >= 400) {
        http_response_code($status ?: 502);
        echo json_encode([
            'error'  => 'airtable_error',
            'status' => $status,
            'detail' => $err ?: ('http ' . $status),
        ]);
        exit;
    }

    $data = json_decode($body, true);
    if (!is_array($data) || !isset($data['records'])) {
        http_response_code(502);
        echo json_encode(['error' => 'bad_airtable_response']);
        exit;
    }

    foreach ($data['records'] as $rec) {
        // Reshape: dashboard JS expects record.cellValuesByFieldId, mirroring
        // the original Cowork-bridge shape. Airtable's REST returns the same
        // map under .fields (because we passed returnFieldsByFieldId=true).
        $rec['cellValuesByFieldId'] = isset($rec['fields']) ? $rec['fields'] : [];
        unset($rec['fields']);
        $all[] = $rec;
    }

    if (empty($data['offset'])) {
        break;
    }
    $offset = $data['offset'];
}

echo json_encode(['records' => $all]);
