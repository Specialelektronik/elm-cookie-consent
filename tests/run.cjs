const assert = require('node:assert/strict');
const { Elm } = require(process.argv[2]);
const app = Elm.Main.init();
app.ports.results.subscribe(checks => {
  for (const check of checks) assert.equal(check.passed, true, check.name);
  console.log(`${checks.length} consent checks passed.`);
});
