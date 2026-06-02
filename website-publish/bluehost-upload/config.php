<?php
// ============================================================================
// SMB Steward — Airtable relay configuration
// ----------------------------------------------------------------------------
// This file holds the Airtable Personal Access Token used by airtable.php.
// It MUST live in the same folder as airtable.php on the server.
//
// SAFETY: Because this is a .php file, even if someone requests it directly
// the web server EXECUTES it and returns nothing. The token never leaves the
// server. The .htaccess in this folder also requires Basic Auth, so an
// unauthenticated request never reaches PHP at all.
//
// REPLACE EACH "_HERE" PLACEHOLDER WITH YOUR REAL VALUES.
// ============================================================================

// Airtable Personal Access Token.
// Create at:  https://airtable.com/create/tokens
// Required scope:        data.records:read
// Required base access:  the EarnedOut "Master Deal Pipeline" base only.
const AIRTABLE_TOKEN = 'AIRTABLE_TOKEN_HERE';

// IDs of the EarnedOut Master Deal Pipeline base and the Master Deal Pipeline
// table inside it. These are stable; do not change unless Airtable was reset.
const AIRTABLE_BASE  = 'appOsvuyy5eK43QTx';
const AIRTABLE_TABLE = 'tblSmNrHROMLm7vOS';

// Optional second-layer secret. The dashboard sends this in an X-Relay-Secret
// header; the relay rejects any request without it. The Basic Auth folder
// password already provides primary protection; this is a tiny extra defense
// against bots that find /SMBSSearch001/airtable.php and try to call it.
// Leave the placeholder value to disable the check.
const RELAY_SHARED_SECRET = 'OPTIONAL_RELAY_SECRET_HERE';
