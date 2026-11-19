# OpenCode Dashboard

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

- List active OpenCode containers in both terminal (TUI) and detached (`serve`) mode
- Start a new `serve` container from a directory you provide
- Stop a running `serve` container from the Actions column
- Remember the last 10 launched directories on disk for one-click relaunch across devices
- Show directory-only autocomplete suggestions while typing a path

## Connect from another computer

`run.sh` publishes each new container's OpenCode server on a Docker-assigned host port. Open the URL shown in the dashboard from another computer, or find the host port with `docker port <container> 4096/tcp` and use the Docker host's LAN address.

If you already have a runner image built with OpenCode v1, rebuild it with `run.sh build` before starting new containers.

The server username and password are both `opencode`. To connect from a remote terminal:

```bash
OPENCODE_PASSWORD=opencode opencode --server http://<docker-host>:<port>
```

Relaunch existing containers to apply the new password.

The password is public and the servers use plain HTTP. Restrict access to trusted devices with a firewall or private network. The dashboard has no authentication; do not expose it or the servers to the internet.

Recent launches are stored in `dashboard/recent-launches.json`.
