const { execSync } = require('child_process');
const path = require('path');
const os = require('os');
const fs = require('fs');

const inputFile = process.argv[2] || 'mobile_user_master_report_template.html';
const outputFile = process.argv[3] || 'mobile_user_master_qa_report.pdf';

const inputAbs = path.resolve(__dirname, inputFile);
const outputAbs = path.resolve(__dirname, outputFile);

const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const tempUserData = path.join(os.tmpdir(), 'chrome_pdf_tmp_' + Date.now());

if (!fs.existsSync(tempUserData)) {
  fs.mkdirSync(tempUserData, { recursive: true });
}

console.log(`Generating PDF from ${inputAbs} -> ${outputAbs}...`);

try {
  const cmd = `"${chromePath}" --headless=new --disable-gpu --no-pdf-header-footer --print-to-pdf="${outputAbs}" --user-data-dir="${tempUserData}" "file:///${inputAbs.replace(/\\/g, '/')}"`;
  execSync(cmd, { stdio: 'inherit' });
  console.log('PDF generated successfully!');
} catch (e) {
  console.error('Error generating PDF:', e);
} finally {
  try {
    fs.rmSync(tempUserData, { recursive: true, force: true });
  } catch (_) {}
}
