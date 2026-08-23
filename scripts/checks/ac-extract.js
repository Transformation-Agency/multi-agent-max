// ac-extract.js — print AC ids (AC-x.y) found in the titles of PASSING tests in a JSON results file.
// Handles vitest/jest (assertionResults/testResults) and playwright (suites/specs/tests) shapes heuristically.
const fs = require("fs");
const r = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const out = new Set();
const walk = (n, path) => {
  if (!n || typeof n !== "object") return;
  const title = [path, n.title || n.name || n.fullName || ""].filter(Boolean).join(" ");
  const ok = n.status === "passed" || n.outcome === "expected" || n.state === "passed" || n.ok === true;
  if (ok) (title.match(/AC-\d+\.\d+/g) || []).forEach((a) => out.add(a));
  for (const k of ["suites", "specs", "tests", "assertionResults", "testResults", "children", "results"])
    if (Array.isArray(n[k])) n[k].forEach((c) => walk(c, title));
};
walk(r, "");
console.log([...out].join("\n"));
