const axios = require("axios");

async function run({ target , rps, duration }) {
  console.log(`Load testing [Readiness] on ${target} with ${rps} RPS for ${duration} seconds...`);

  let total = 0;
  const statusCounts = {};

  const sendRequest = async () => {
    try {
      const res = await axios.get(target);
      const code = res.status;
      statusCounts[code] = (statusCounts[code] || 0) + 1;
    } catch (err) {
      if (err.response) {
        const code = err.response.status;
        statusCounts[code] = (statusCounts[code] || 0) + 1;
      } else {
        statusCounts["NO_RESPONSE"] = (statusCounts["NO_RESPONSE"] || 0) + 1;
      }
    } finally {
      total++;
    }
  };

  return new Promise((resolve) => {
    const interval = setInterval(() => {
      for (let i = 0; i < rps; i++) sendRequest();
    }, 1000);

    setTimeout(() => {
      clearInterval(interval);
      const result = {
        totalRequests: total,
        statusCounts,
      };
      console.log("--- Results ---");
      console.log(result);
      resolve(result);
    }, duration * 1000);
  });
}

module.exports = { run };
