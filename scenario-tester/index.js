const express = require("express");
const scenarios = require("./scenarios");

const app = express();
const port = process.env.PORT || 8083;

app.use(express.json());

// Run a scenario test via API
app.post("/run/:scenario", async (req, res) => {
  const { scenario } = req.params;
  const { target, rps = 5, duration = 30 } = req.body;

  if (!scenarios[scenario]) {
    return res.status(400).json({ error: `Unknown scenario: ${scenario}` });
  }
  if (!target) {
    return res.status(400).json({ error: "Target URL is required" });
  }

  console.log(`▶ Running scenario: ${scenario} against ${target}`);

  try {
    const result = await scenarios[scenario].run({ target, rps, duration });
    res.json({
      message: `Scenario '${scenario}' completed`,
      result,
    });
  } catch (err) {
    res.status(500).json({ error: err.message || "Test failed" });
  }
});

app.get("/", (req, res) => {
  res.send("✅ Scenarios Tester API is running");
});

app.listen(port, () => {
  console.log(`🚀 Scenarios Tester running at http://0.0.0.0:${port}`);
});
