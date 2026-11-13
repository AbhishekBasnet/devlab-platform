# Week 4 Day 5: Storage, networks, logging, cleanup, Podman

## The user's four rules (their words, tidied)
- `docker compose down -v` deletes the persistent (named) volumes too. Be careful.
- Docker bypasses ufw: it writes its own iptables rules ahead of ufw's. `-p 5432:5432` exposes the port to the LAN.
- The `json-file` log driver has no size limit by default, so container logs can fill the disk.
- Pruning also deletes stopped containers (and what is unused after them). Be careful.

## Storage
- Anything written outside a mount goes into the container's **writable layer**, deleted on `docker rm`.
- Look at the **left side of `-v`**: starts with `/` or `./` = **bind mount** (host path); just a name = **named volume**. Order is `HOST:CONTAINER`, same as `-p`.

| Type | Where | Use for |
|---|---|---|
| Named volume | `/var/lib/docker/volumes/NAME/_data`, Docker-managed | databases, app data |
| Bind mount | a host path you choose | NAS media (mount the NAS on the host first, then bind the folder), config you edit |
| tmpfs | RAM only | scratch data, secrets that must not touch disk |

- Bind mounts need the container user to have permission on the host folder (PUID/PGID). On Fedora (SELinux) add `:Z` (private) or `:z` (shared).

## Networks
- Drivers: `bridge` (default), `host` (no isolation, no `-p`), `none`.
- **Default bridge has no Docker DNS**, so container names do not resolve (only IPs, which change). **User-defined networks** (and Compose) have it at `127.0.0.11`, so `app` connects to `db:5432`.
- Same-network traffic needs no `-p`. Publish only the front door (nginx).
- `-p 127.0.0.1:9000:3000` = host loopback `:9000` to container `:3000`, reachable only from the host itself.
- Commands: `docker network ls`, `inspect`, `create`, `rm`.

## Logging
- Apps write to **stdout/stderr**. `docker logs` shows them. A log folder inside the container is lost on `rm`.
- A bind-mounted log folder works but needs `logrotate` and `docker logs` shows nothing.
- Limit: `--log-opt max-size=10m --log-opt max-file=3`, or in `daemon.json`. The daemon must be restarted to read `daemon.json`, and **existing containers must be recreated**.
- Restart loop: `docker ps -a` (exit code: `137` killed/OOM, `1` app error, `0` clean) then `docker logs --tail 50 NAME`.
- `docker logs` flags: `-f` follow, `-t` timestamps, `-n`/`--tail`, `--since`, `--until`.

## Cleanup
- Look first: `docker system df` (and `-v`).
- `container prune`, `image prune` (dangling only), `image prune -a`, `network prune`, `builder prune`, `volume prune`, `system prune` (leaves volumes alone).
- **Dangling** = untagged image (`<none>:<none>`). **Unused** = no container uses it. Different things.
- A stopped container still holds its volume. The risk is the order: prune removes the stopped container, then the volume is orphaned. On Docker 23+ volume prune only removes anonymous volumes unless `-a` (check `docker volume prune --help`).

## Docker vs Podman
- Docker: root daemon `dockerd`; `docker` group is root-equivalent. Podman: daemonless, rootless by default, Fedora's default, almost the same CLI, same OCI images.
- Rootless limits: ports under 1024, UID mapping on bind mounts. Rootless is the safer default.
- Docker dominates for history and ecosystem (tutorials, Compose, CI). Kubernetes uses containerd/CRI-O, not the Docker daemon.

## Weak spots to requiz
Bind vs volume syntax and what survives `rm`; why the default bridge has no name resolution; `127.0.0.1` in `-p`; stdout logging and rotation (new containers only); dangling vs unused; what rootless limits; `:Z` vs `:z`.
