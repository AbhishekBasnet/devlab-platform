# Week 4 Day 2: Docker Compose (Plex + ABS lab)

Concepts taught only. The lab (write `docker/media/compose.yml` from a blank file, a comment on every line) is **not done yet**. Rule: the user writes it, Claude explains keys and reviews. Nothing was changed on the running containers.

## Essentials
- Compose describes a multi-container setup in one YAML file (declarative: the end state, not a list of `docker run` commands).
- Compose creates a network for the project automatically, and the **service name is the hostname** on it.
- The `version:` key is obsolete. The command is `docker compose` (v2).
- `depends_on` controls start order, not "ready" order.
- Secrets (NAS password, claim token) go in an `.env` file that is in `.gitignore`, not in the YAML.

## Keys

| Key | Meaning | `docker run` equivalent |
|---|---|---|
| `services:` | top-level map, one entry per container | |
| `image:` | image and tag | the image argument |
| `container_name:` | fixed name | `--name` |
| `restart:` | restart policy, e.g. `unless-stopped` | `--restart` |
| `ports:` | `"HOST:CONTAINER"` | `-p` |
| `volumes:` | bind mounts or named volumes | `-v` |
| `environment:` | variables (`PUID`, `PGID`, `TZ`) | `-e` |
| `env_file:` | variables from a file | `--env-file` |
| `networks:` | which networks to join | `--network` |
| `healthcheck:` | command that says whether it is healthy | `--health-cmd` |
| `depends_on:` | start order | |
| top-level `volumes:` | declares named volumes | `docker volume create` |

## Commands

| Command | Meaning |
|---|---|
| `docker compose up -d` | create and start everything in the background |
| `docker compose down` | stop and remove containers and the network (volumes stay) |
| `docker compose ps` | status |
| `docker compose logs -f SERVICE` | follow logs |
| `docker compose config` | validate the file and print the resolved result |
| `docker compose pull` | fetch newer images |

## Plex and ABS specifics
- **linuxserver.io images** use `PUID` and `PGID` so files on disk are owned by your user, not root. Find the IDs with `id`. The current containers run as root with no PUID/PGID (SESSION_LOG, Session 3).
- **Config lives in `/config`** (database and settings). This is the data the Day 3 backup protects.
- **Media** is a bind mount, read-only (`:ro`) where possible.
- **NAS credentials** are currently in plain text in the CIFS volume options: move them to a `credentials=` file.
- Plex may need host networking or specific ports for local discovery: check the image docs and decide.

## Before the lab
1. Find the current Plex and ABS `docker run` commands or compose file to rewrite from.
2. Write the new file in a separate folder and test with different names and ports before touching the running containers.
