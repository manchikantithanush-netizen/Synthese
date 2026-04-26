export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // ── CORS headers ──────────────────────────────────────────────────────────
    const cors = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, X-App-Secret",
    };

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: cors });
    }

    // ── Auth check — reject requests without the correct app secret ───────────
    const appSecret = request.headers.get("X-App-Secret");
    if (!appSecret || appSecret !== env.APP_SECRET) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    // ── /weather?lat=XX&lon=YY ────────────────────────────────────────────────
    if (url.pathname === "/weather") {
      const lat = url.searchParams.get("lat");
      const lon = url.searchParams.get("lon");
      if (!lat || !lon) {
        return new Response(JSON.stringify({ error: "Missing lat/lon" }), {
          status: 400,
          headers: { ...cors, "Content-Type": "application/json" },
        });
      }
      const res = await fetch(
        `https://api.weatherapi.com/v1/current.json?key=${env.WEATHER_API_KEY}&q=${lat},${lon}&aqi=no`
      );
      const body = await res.text();
      return new Response(body, {
        status: res.status,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    // ── /github  (GitHub Models AI proxy — POST, forwards body as-is) ─────────
    if (url.pathname === "/github") {
      if (request.method !== "POST") {
        return new Response(JSON.stringify({ error: "POST required" }), {
          status: 405,
          headers: { ...cors, "Content-Type": "application/json" },
        });
      }
      const body = await request.text();
      const res = await fetch(
        "https://models.github.ai/inference/chat/completions",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${env.GITHUB_TOKEN}`,
            "Content-Type": "application/json",
            Accept: "application/vnd.github+json",
          },
          body,
        }
      );
      const resBody = await res.text();
      return new Response(resBody, {
        status: res.status,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    return new Response("OK", { headers: cors });
  },
};
