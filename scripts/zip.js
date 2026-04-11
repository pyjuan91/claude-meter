const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const root = path.resolve(__dirname, '..');
const srcDir = path.join(root, 'src');
const version = require(path.join(root, 'package.json')).version;
const platform = process.argv[2]; // 'chrome', 'firefox', or undefined (both)

function buildZip(target) {
  const manifest = JSON.parse(fs.readFileSync(path.join(srcDir, 'manifest.json'), 'utf8'));

  if (target === 'chrome') {
    // Chrome/Edge: remove scripts (MV2 field) and browser_specific_settings (gecko only)
    delete manifest.background.scripts;
    delete manifest.browser_specific_settings;
  }

  // Write patched manifest to a temp file
  const tmpManifest = path.join(srcDir, 'manifest.json.tmp');
  fs.writeFileSync(tmpManifest, JSON.stringify(manifest, null, 2) + '\n');

  const suffix = target === 'chrome' ? '-chrome' : '-firefox';
  const zipName = `claude-meter-v${version}${suffix}.zip`;
  const zipPath = path.join(root, zipName);

  // Remove old zip if exists
  if (fs.existsSync(zipPath)) fs.unlinkSync(zipPath);

  // Create zip using the temp manifest
  execSync(
    `cd "${srcDir}" && cp manifest.json manifest.json.bak && mv manifest.json.tmp manifest.json && zip -r "${zipPath}" manifest.json *.js *.css *.html icons/ && mv manifest.json.bak manifest.json`,
    { stdio: 'inherit' }
  );

  console.log(`\n  ${zipName}`);
}

if (!platform || platform === 'chrome') buildZip('chrome');
if (!platform || platform === 'firefox') buildZip('firefox');

if (!platform) console.log('\nBoth zips created.');
