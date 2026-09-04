// Serialize evidence safely, including caller-provided command arguments.
const fs = require('fs');
const [out, stage, ticket, profile, commit, fresh, fail, secs, dirty, ...command] = process.argv.slice(2);
const checks = fs.readFileSync(`${out}/checks.tsv`, 'utf8').trim().split('\n').filter(Boolean).map(line => {
  const [name, status, reason, duration] = line.split('\t');
  return { name, status, ...(reason ? { reason } : {}), secs: Number(duration) };
});
fs.writeFileSync(`${out}/verify.json`, JSON.stringify({
  stage: Number(stage), ticket, profile, commit, dirty: Boolean(dirty),
  fresh: fresh === '1', passed: fail === '0',
  certification: fail !== '0' ? 'none' : profile === 'ticket' ? 'local-only' : profile,
  secs: Number(secs), ...(command.length ? { command } : {}), checks,
}, null, 2) + '\n');
