// s8_dashboard SELF-TEST — headless Chromium render check.
// Loads the Jinja2-rendered dashboard, captures console + page errors,
// screenshots it, and confirms the layout actually laid out (non-zero
// bounding boxes for header + all four sections + the data tables).
const { chromium } = require(process.env.HOME + '/pw/node_modules/playwright');

const RENDER = '/sessions/great-friendly-shannon/mnt/outputs/dashboard_render.html';
const SHOT   = '/sessions/great-friendly-shannon/mnt/outputs/dashboard_render.png';

(async () => {
  const consoleErrors = [];
  const consoleAll = [];
  const pageErrors = [];

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1366, height: 1100 } });

  page.on('console', msg => {
    consoleAll.push(`[${msg.type()}] ${msg.text()}`);
    if (msg.type() === 'error') consoleErrors.push(msg.text());
  });
  page.on('pageerror', err => pageErrors.push(String(err)));

  const resp = await page.goto('file://' + RENDER, { waitUntil: 'load' });
  await page.waitForTimeout(400);

  // Layout probes — element must exist and have a non-zero rendered box.
  async function box(sel) {
    const el = await page.$(sel);
    if (!el) return null;
    return await el.boundingBox();
  }
  const probes = {
    'header.banner'       : await box('header.banner'),
    'section#section-a'   : await box('section#section-a'),
    'section#section-b'   : await box('section#section-b'),
    'section#section-c'   : await box('section#section-c'),
    'section#section-d'   : await box('section#section-d'),
    'section-a table'     : await box('#section-a table'),
    'section-d .summary-grid' : await box('#section-d .summary-grid'),
  };
  // Count rendered data rows in each section table body.
  const rowCounts = await page.evaluate(() => {
    const c = s => document.querySelectorAll(s).length;
    return {
      a: c('#section-a tbody tr'),
      b: c('#section-b tbody tr'),
      c: c('#section-c tbody tr'),
      priceDropBadges: c('.chip.price-drop'),
      manualChips: c('.chip.manual'),
      statCards: c('.stat-card'),
    };
  });
  const docHeight = await page.evaluate(() => document.body.scrollHeight);

  await page.screenshot({ path: SHOT, fullPage: true });
  const fs = require('fs');
  const shotBytes = fs.statSync(SHOT).size;

  await browser.close();

  // ---- verdict ----
  let ok = true;
  const line = (label, pass, detail='') => {
    if (!pass) ok = false;
    console.log((pass ? 'PASS ' : 'FAIL ') + label + (detail ? ' :: ' + detail : ''));
  };

  line('page loaded (HTTP-equiv ok for file://)', !!resp);
  line('no page (uncaught JS) errors', pageErrors.length === 0, JSON.stringify(pageErrors));
  line('no console errors', consoleErrors.length === 0, JSON.stringify(consoleErrors));
  for (const [sel, bb] of Object.entries(probes)) {
    line(`laid out: ${sel}`, bb && bb.width > 0 && bb.height > 0,
         bb ? `${Math.round(bb.width)}x${Math.round(bb.height)}` : 'NOT FOUND');
  }
  line('section A rendered 4 lead rows', rowCounts.a === 4, `rows=${rowCounts.a}`);
  line('section B rendered 2 lead rows', rowCounts.b === 2, `rows=${rowCounts.b}`);
  line('section C rendered 1 lead row',  rowCounts.c === 1, `rows=${rowCounts.c}`);
  line('price-drop badge present', rowCounts.priceDropBadges >= 1, `count=${rowCounts.priceDropBadges}`);
  line('manual chip present', rowCounts.manualChips >= 1, `count=${rowCounts.manualChips}`);
  line('4 stat cards in header', rowCounts.statCards === 4, `count=${rowCounts.statCards}`);
  line('document has real height', docHeight > 800, `scrollHeight=${docHeight}px`);
  line('screenshot file non-empty', shotBytes > 0, `${shotBytes} bytes -> ${SHOT}`);

  console.log('\nconsole messages observed (' + consoleAll.length + '):');
  consoleAll.forEach(m => console.log('  ' + m));
  console.log('\n=== ' + (ok ? 'ALL RENDER CHECKS PASS' : 'RENDER CHECKS FAILED') + ' ===');
  process.exit(ok ? 0 : 1);
})().catch(e => { console.error('SMOKE TEST CRASHED:', e); process.exit(2); });
