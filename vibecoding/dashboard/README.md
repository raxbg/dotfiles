# OpenCode Serve Dashboard

Run the dashboard:

```bash
./dashboard.sh
```

Optional host and port:

```bash
OPENCODE_DASHBOARD_HOST=127.0.0.1 OPENCODE_DASHBOARD_PORT=31900 ./dashboard.sh
```

Then open `http://127.0.0.1:31900`.

The dashboard can:

- List active OpenCode containers launched in `serve` mode
- Start a new `serve` container from a directory you provide
- Stop a running `serve` container from the Actions column
- Remember the last 10 launched directories on disk for one-click relaunch across devices
- Show directory-only autocomplete suggestions while typing a path

It discovers containers through docker labels added by `run.sh` in `serve` mode.

Recent launches are stored in `dashboard/recent-launches.json`.
