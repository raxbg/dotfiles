#!/usr/bin/env node

const fs = require("node:fs/promises");
const http = require("node:http");
const path = require("node:path");
const { execFile, spawn } = require("node:child_process");
const { promisify } = require("node:util");

const execFileAsync = promisify(execFile);
const HOST = process.env.OPENCODE_DASHBOARD_HOST || "0.0.0.0";
const PORT = Number(process.env.OPENCODE_DASHBOARD_PORT || 31900);
const RUN_SCRIPT_PATH = path.resolve(__dirname, "..", "run.sh");
const INDEX_HTML_PATH = path.resolve(__dirname, "index.html");
let indexHtmlCache = null;

function jsonResponse(res, statusCode, data) {
  res.writeHead(statusCode, {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
  });
  res.end(JSON.stringify(data));
}

function htmlResponse(res, html) {
  res.writeHead(200, {
    "Content-Type": "text/html; charset=utf-8",
    "Cache-Control": "no-store",
  });
  res.end(html);
}

function parseLabels(rawLabels) {
  const labels = {};

  for (const pair of String(rawLabels || "").split(",")) {
    if (!pair) {
      continue;
    }

    const [key, ...rest] = pair.split("=");
    if (!key) {
      continue;
    }

    labels[key] = rest.join("=");
  }

  return labels;
}

async function listServeContainers() {
  const args = [
    "ps",
    "--filter",
    "label=opencode.managed=true",
    "--filter",
    "label=opencode.mode=serve",
    "--format",
    "{{json .}}",
  ];

  const { stdout } = await execFileAsync("docker", args, {
    maxBuffer: 1024 * 1024,
  });
  const lines = stdout
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean);

  const containers = [];

  for (const line of lines) {
    let entry;
    try {
      entry = JSON.parse(line);
    } catch {
      continue;
    }

    const labels = parseLabels(entry.Labels);
    const port = labels["opencode.port"] || "";
    const sourceDir = labels["opencode.source_dir"] || "";

    containers.push({
      id: entry.ID,
      name: entry.Names,
      status: entry.Status,
      runningFor: entry.RunningFor,
      ports: entry.Ports,
      port,
      sourceDir,
    });
  }

  containers.sort((a, b) => a.name.localeCompare(b.name));
  return containers;
}

async function ensureDirectory(dirPath) {
  const resolved = path.resolve(String(dirPath || "").trim());
  if (!resolved) {
    throw new Error("Directory is required.");
  }

  let stat;
  try {
    stat = await fs.stat(resolved);
  } catch {
    throw new Error(`Directory does not exist: ${resolved}`);
  }

  if (!stat.isDirectory()) {
    throw new Error(`Path is not a directory: ${resolved}`);
  }

  return resolved;
}

async function launchServeContainer(directory) {
  const resolvedDirectory = await ensureDirectory(directory);

  const child = spawn("bash", [RUN_SCRIPT_PATH, "serve"], {
    cwd: resolvedDirectory,
    detached: true,
    stdio: "ignore",
  });

  child.unref();
  return { directory: resolvedDirectory };
}

async function stopServeContainer(containerId) {
  const id = String(containerId || "").trim();
  if (!id) {
    throw new Error("Container id is required.");
  }

  const { stdout: matched } = await execFileAsync("docker", [
    "ps",
    "-q",
    "--filter",
    `id=${id}`,
    "--filter",
    "label=opencode.managed=true",
    "--filter",
    "label=opencode.mode=serve",
  ]);

  if (!matched.trim()) {
    throw new Error("Container not found or not managed by OpenCode dashboard.");
  }

  await execFileAsync("docker", ["stop", id]);
  return { id };
}

async function appHtml() {
  if (indexHtmlCache !== null) {
    return indexHtmlCache;
  }

  indexHtmlCache = await fs.readFile(INDEX_HTML_PATH, "utf8");
  return indexHtmlCache;
}

function collectJson(req) {
  return new Promise((resolve, reject) => {
    let body = "";

    req.on("data", (chunk) => {
      body += chunk;
      if (body.length > 1_000_000) {
        reject(new Error("Request payload too large."));
      }
    });

    req.on("end", () => {
      if (!body) {
        resolve({});
        return;
      }

      try {
        resolve(JSON.parse(body));
      } catch {
        reject(new Error("Invalid JSON payload."));
      }
    });

    req.on("error", reject);
  });
}

const server = http.createServer(async (req, res) => {
  const url = new URL(
    req.url || "/",
    `http://${req.headers.host || "localhost"}`,
  );

  if (req.method === "GET" && url.pathname === "/") {
    try {
      const html = await appHtml();
      htmlResponse(res, html);
    } catch (error) {
      jsonResponse(res, 500, {
        error: error.message || "Failed to load dashboard page.",
      });
    }
    return;
  }

  if (req.method === "GET" && url.pathname === "/api/servers") {
    try {
      const servers = await listServeContainers();
      jsonResponse(res, 200, { servers });
    } catch (error) {
      jsonResponse(res, 500, {
        error: error.message || "Failed to query docker.",
      });
    }
    return;
  }

  if (req.method === "POST" && url.pathname === "/api/launch") {
    try {
      const body = await collectJson(req);
      const result = await launchServeContainer(body.directory);
      jsonResponse(res, 202, {
        message: `Launch requested for ${result.directory}.`,
      });
    } catch (error) {
      jsonResponse(res, 400, { error: error.message || "Launch failed." });
    }
    return;
  }

  if (req.method === "POST" && url.pathname === "/api/stop") {
    try {
      const body = await collectJson(req);
      const result = await stopServeContainer(body.id);
      jsonResponse(res, 200, {
        message: `Stopped container ${result.id}.`,
      });
    } catch (error) {
      jsonResponse(res, 400, { error: error.message || "Stop failed." });
    }
    return;
  }

  jsonResponse(res, 404, { error: "Not found." });
});

server.listen(PORT, HOST, () => {
  process.stdout.write(
    `OpenCode dashboard running at http://${HOST}:${PORT}\n`,
  );
});
