// Exercise the real shell orchestrator in isolated Git apps; mock only pnpm.
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const template = path.resolve(__dirname, '../..');
const scripts = ['typecheck', 'lint:bugs', 'lint', 'test:unit', 'build', 'test:smoke',
  'test:integration', 'test:e2e:smoke', 'test:e2e', 'audit', 'check:env', 'test:rt'];

function fixture(t, { configured = true } = {}) {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'verification-profiles-'));
  t.after(() => fs.rmSync(tmp, { recursive: true, force: true }));
  const root = path.join(tmp, 'app');
  const plan = path.join(root, 'plan');
  fs.mkdirSync(root);
  fs.cpSync(template, plan, { recursive: true, filter: src =>
    !src.split(path.sep).includes('.git') && !src.includes(`${path.sep}state${path.sep}evidence`) });
  const bin = path.join(tmp, 'bin'); fs.mkdirSync(bin);
  const calls = path.join(tmp, 'calls');
  fs.writeFileSync(path.join(bin, 'pnpm'), `#!/usr/bin/env node
const fs=require('fs');
const command=process.argv[2]==='install'?'install':process.argv[3];
fs.appendFileSync(process.env.MOCK_CALLS, command+'\\n');
const failures=JSON.parse(process.env.MOCK_FAILURES||'{}');
if(failures[command]) process.exit(failures[command]);
if(command.startsWith('test:') && process.env.MOCK_NO_REPORTS!=='1') {
 fs.mkdirSync('.reports',{recursive:true});
 fs.writeFileSync('.reports/'+command.replaceAll(':','-')+'.json',JSON.stringify({
  numTotalTests:1,testResults:[{assertionResults:[{fullName:(process.env.MOCK_AC_E2E_ONLY==='1' && command!=='test:e2e' ? 'ordinary test' : '[AC-01.01] real flow'),status:'passed'}]}]
 }));
}
`, { mode: 0o755 });
  const env = { ...process.env, PATH: `${bin}${path.delimiter}${process.env.PATH}`, MOCK_CALLS: calls };
  function command(cmd, args, extra = {}) {
    return spawnSync(cmd, args, { cwd: root, env: { ...env, ...extra }, encoding: 'utf8' });
  }
  function git(...args) { const r = command('git', args); assert.equal(r.status, 0, r.stderr); }
  git('init', '-q'); git('config', 'user.name', 'Template test'); git('config', 'user.email', 'test@example.invalid');
  fs.writeFileSync(path.join(root, '.gitignore'), '.reports/\nnode_modules/\n');
  fs.writeFileSync(path.join(plan, 'SPEC.md'), '# Test app\nAC-01.01: saved state survives refresh\n');
  if (configured) {
    fs.writeFileSync(path.join(root, 'package.json'), JSON.stringify({ scripts: Object.fromEntries(scripts.map(s => [s, 'mocked by test harness'])) }));
    fs.writeFileSync(path.join(root, 'pnpm-lock.yaml'), 'lockfileVersion: 9\n');
    fs.mkdirSync(path.join(root, 'src/core'), { recursive: true });
    fs.writeFileSync(path.join(root, 'src/core/flow.test.ts'), "test('[AC-01.01] flow', () => expect(true).toBe(true));\n");
    const r = command('bash', ['plan/scripts/checks/config-hash.sh', '--init']);
    assert.equal(r.status, 0, r.stdout + r.stderr);
  }
  git('add', '.'); git('commit', '-qm', 'fixture setup');
  function verify(stage, profile, args = [], extra = {}) {
    const r = command('bash', ['plan/scripts/verify.sh', '--profile', profile, ...args], {
      STAGE: String(stage), TICKET: 'test', ...extra,
    });
    const evidence = path.join(plan, 'state/evidence/test');
    const attempts = fs.existsSync(evidence) ? fs.readdirSync(evidence).sort((a,b) => Number(a.split('-')[1])-Number(b.split('-')[1])) : [];
    const reportPath = attempts.length ? path.join(evidence, attempts.at(-1), 'verify.json') : '';
    return { ...r, report: reportPath && fs.existsSync(reportPath) ? JSON.parse(fs.readFileSync(reportPath)) : null };
  }
  return { root, plan, env, git, verify, command,
    calls: () => fs.existsSync(calls) ? fs.readFileSync(calls, 'utf8').trim().split('\n') : [] };
}

test('Stage 0 records focused evidence without requiring stack, CI, or baseline', t => {
  const f = fixture(t, { configured: false });
  const r = f.verify(0, 'ticket', ['--', 'node', '-e', 'console.log("startup check")']);
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert.equal(r.report.certification, 'local-only');
  assert.equal(r.report.checks.find(c => c.name === 'build').status, 'deferred');
  assert.equal(r.report.checks.find(c => c.name === 'config-integrity').status, 'deferred');
  assert.deepEqual(f.calls(), []);
});

test('ticket preserves caches/reports and runs only selected package script', t => {
  const f = fixture(t);
  for (const dir of ['node_modules', '.next', '.reports']) {
    fs.mkdirSync(path.join(f.root, dir)); fs.writeFileSync(path.join(f.root, dir, 'sentinel.json'), '{}');
  }
  const r = f.verify(1, 'ticket', ['--', 'pnpm', 'run', 'typecheck']);
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert.deepEqual(f.calls(), ['typecheck']);
  for (const dir of ['node_modules', '.next', '.reports']) assert.ok(fs.existsSync(path.join(f.root, dir, 'sentinel.json')));
  assert.equal(r.report.fresh, false);
});

test('ticket requires a command, rejects fresh mode, and reports focused failures', t => {
  const f = fixture(t);
  assert.equal(f.verify(1, 'ticket').status, 2);
  assert.equal(f.verify(1, 'ticket', ['--fresh', '--', 'node', '-e', '']).status, 2);
  const r = f.verify(1, 'ticket', ['--', 'node', '-e', 'process.exit(7)']);
  assert.equal(r.status, 1);
  assert.equal(r.report.certification, 'none');
  assert.equal(r.report.checks.find(c => c.name === 'focused-check').reason, 'exit 7');
});

test('missing required milestone checks fail instead of producing a false pass', t => {
  const f = fixture(t, { configured: false });
  const r = f.verify(1, 'milestone');
  assert.equal(r.status, 1, r.stdout + r.stderr);
  assert.equal(r.report.passed, false);
  assert.equal(r.report.checks.find(c => c.name === 'build').reason, 'required check not configured');
  assert.equal(r.report.checks.find(c => c.name === 'config-integrity').status, 'fail');
});

test('milestone gathers independent failures and blocks build-dependent suites', t => {
  const f = fixture(t);
  const r = f.verify(3, 'milestone', [], { MOCK_FAILURES: JSON.stringify({ typecheck: 1, build: 1, audit: 2 }) });
  assert.equal(r.status, 1, r.stdout + r.stderr);
  for (const name of ['typecheck', 'build', 'security-audit']) assert.equal(r.report.checks.find(c => c.name === name).status, 'fail');
  for (const name of ['golden-demo-smoke', 'smoke-e2e', 'full-e2e']) assert.equal(r.report.checks.find(c => c.name === name).status, 'blocked');
  assert.ok(f.calls().includes('test:integration'));
  assert.ok(f.calls().includes('check:env'));
  assert.ok(!f.calls().includes('test:e2e'));
  assert.ok(!f.calls().includes('install'));
});

test('milestone clears stale reports; strict coverage cannot credit an old result', t => {
  const f = fixture(t);
  fs.mkdirSync(path.join(f.root, '.reports'));
  fs.writeFileSync(path.join(f.root, '.reports/old.json'), JSON.stringify({ status: 'passed', title: '[AC-01.01]' }));
  const r = f.verify(3, 'milestone', [], { MOCK_NO_REPORTS: '1' });
  assert.equal(r.status, 1, r.stdout + r.stderr);
  assert.ok(!fs.existsSync(path.join(f.root, '.reports/old.json')));
  assert.equal(r.report.checks.find(c => c.name === 'ac-coverage-strict').status, 'fail');
});

test('full milestone passes and computes coverage after full e2e', t => {
  const f = fixture(t);
  const r = f.verify(3, 'milestone', [], { MOCK_AC_E2E_ONLY: '1' });
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert.equal(r.report.certification, 'milestone');
  const names = r.report.checks.map(c => c.name);
  assert.ok(names.indexOf('ac-coverage-strict') > names.indexOf('full-e2e'));
  assert.ok(!f.calls().includes('install'));
});

test('release cannot downgrade profile or omit clean installation', t => {
  const f = fixture(t);
  assert.equal(f.verify(4, 'milestone').status, 2);
  assert.equal(f.verify(4, 'release').status, 2);
  assert.equal(f.verify(3, 'release', ['--fresh']).status, 2);
  assert.deepEqual(f.calls(), []);
});

test('fresh release catches staged/untracked changes before installing', t => {
  const f = fixture(t);
  fs.writeFileSync(path.join(f.root, 'new.ts'), 'export const value=1;');
  assert.equal(f.verify(4, 'release', ['--fresh']).status, 1);
  f.git('add', 'new.ts');
  assert.equal(f.verify(4, 'release', ['--fresh']).status, 1);
  assert.deepEqual(f.calls(), []);
});

test('release installs once; a failed install blocks later checks', t => {
  const f = fixture(t);
  const r = f.verify(4, 'release', ['--fresh'], { MOCK_FAILURES: '{"install":1}' });
  assert.equal(r.status, 1);
  assert.deepEqual(f.calls(), ['install']);
  assert.equal(r.report.checks.find(c => c.name === 'remaining-checks').status, 'blocked');
});

test('clean release succeeds with required checks and fresh evidence', t => {
  const f = fixture(t);
  const r = f.verify(4, 'release', ['--fresh']);
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert.equal(r.report.certification, 'release');
  assert.equal(r.report.fresh, true);
  assert.equal(r.report.dirty, false);
  assert.equal(f.calls().filter(c => c === 'install').length, 1);
});

test('append-only debt closure resolves an open record without deleting history', t => {
  const f = fixture(t);
  const debt = path.join(f.plan, 'state/DEBT.md');
  fs.writeFileSync(debt, '# DEBT\n## Open\n| D-001 | T-012 | src/a.ts | shortcut | repair | 3 |\n## Closed / accepted\n');
  assert.equal(f.command('bash', ['plan/scripts/checks/debt.sh', '--must-be-empty']).status, 1);
  fs.appendFileSync(debt, '| D-999 | worker | abc123 | closed |\n');
  assert.equal(f.command('bash', ['plan/scripts/checks/debt.sh', '--must-be-empty']).status, 1);
  fs.appendFileSync(debt, '| D-001 | human | abc123 | deferred-accepted: approved rationale |\n');
  assert.equal(f.command('bash', ['plan/scripts/checks/debt.sh', '--must-be-empty']).status, 0);
});

test('configured performance and red-team checks cannot silently disappear', t => {
  const f = fixture(t);
  fs.writeFileSync(path.join(f.plan, 'perf-budgets.json'), '{}');
  fs.writeFileSync(path.join(f.plan, 'tickets/RT-01.md'), '# Regression required\n');
  const pkgPath = path.join(f.root, 'package.json');
  const pkg = JSON.parse(fs.readFileSync(pkgPath)); delete pkg.scripts['test:rt'];
  fs.writeFileSync(pkgPath, JSON.stringify(pkg));
  const r = f.verify(3, 'milestone');
  assert.equal(r.status, 1, r.stdout + r.stderr);
  assert.equal(r.report.checks.find(c => c.name === 'perf-budget').status, 'fail');
  assert.equal(r.report.checks.find(c => c.name === 'red-team-regressions').reason, 'required check not configured');
});

test('config integrity includes the evidence serializer', t => {
  const f = fixture(t);
  fs.appendFileSync(path.join(f.plan, 'scripts/checks/verify-report.js'), '\n// changed configuration\n');
  const r = f.verify(1, 'ticket', ['--', 'node', '-e', 'console.log("focused check")']);
  assert.equal(r.status, 1, r.stdout + r.stderr);
  assert.equal(r.report.checks.find(c => c.name === 'config-integrity').status, 'fail');
});
