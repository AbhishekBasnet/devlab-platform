# Week 4 Day 1: How containers work, images, `docker run`

Topics: 1 container vs VM, 2 namespaces, 3 cgroups, 4 images/layers/registries/tags, 5 `docker run` flags, 6 daily commands. Check scores and mistakes are at the end.

## Essentials
- A container is a normal Linux process that the kernel isolates with **namespaces** (what it sees), limits with **cgroups** (what it uses), and gives its own filesystem from an **image**.
- Containers share the host kernel: fast and light, but less isolated than a VM. Docker on Mac/Windows hides a Linux VM.
- Image = read-only layers. Container = image + a thin **writable layer**. `docker rm` deletes that layer, so data you care about goes in a **volume**.
- `-p HOST:CONTAINER` publishes a port. `EXPOSE` only documents it.
- Never deploy `:latest`: use a version tag, a git SHA, or a digest.
- Exit code **137** = killed (SIGKILL, often out of memory). **143** = SIGTERM.

## 1. Container vs VM

| | VM | Container |
|---|---|---|
| Kernel | its own guest kernel on a hypervisor | shares the host kernel |
| Size | GBs | MBs |
| Start time | seconds to minutes (boots an OS) | milliseconds (starts a process) |
| Isolation | strong | weaker (a kernel bug affects all) |

## 2. Namespaces (what a process can *see*)

| Namespace | Isolates | Effect |
|---|---|---|
| `pid` | process IDs | the main process is PID 1 and sees only its own processes |
| `net` | network stack | own interfaces, IP, ports, routes |
| `mnt` | mount points | own filesystem tree (the image) |
| `uts` | hostname | own hostname |
| `ipc` | shared memory, queues | no IPC with host processes |
| `user` | UIDs and GIDs | root inside can map to an unprivileged user outside |

The same process has two real PIDs: 1 inside, something like 48213 on the host (`docker top <c>`, `ps aux`).

## 3. cgroups (what a process can *use*)

| Flag | Limit |
|---|---|
| `--cpus 1.5` | CPU |
| `--memory 512m` | RAM; over the limit, the OOM killer kills it (exit 137) |
| `--pids-limit N` | number of processes |

Extra security layers: dropped Linux **capabilities** and **seccomp** syscall filtering.

## 4. Images, layers, registries, tags

```dockerfile
FROM node:20-alpine          # base layers (OS + Node)
WORKDIR /app                 # metadata
COPY package*.json ./        # layer A
RUN npm ci                   # layer B: node_modules
COPY . .                     # layer C: source code
CMD ["node", "server.js"]    # metadata only
```
- Each `RUN`, `COPY`, `ADD` adds one layer holding only the difference.
- Layers are cached and shared. Docker rebuilds from the first changed layer, so copy dependency files **before** the source.
- Copy-on-write: a change to a file from a lower layer is copied into the container's writable layer first.
- Postgres is a **separate container** from its own image. Its data lives in a volume, not a layer.

| Term | Meaning |
|---|---|
| registry | stores images: Docker Hub (default), GHCR `ghcr.io`, ECR |
| name | `registry/namespace/name:tag`, e.g. `ghcr.io/you/app:1.2.0` (no tag = `latest`) |
| tag | a movable label (`latest` is not special) |
| digest | `app@sha256:...`, exact content, never changes |

| Command | Meaning |
|---|---|
| `docker pull image:tag` | download an image |
| `docker images` | list local images |
| `docker tag src dst` | add another name |
| `docker push name:tag` | upload to a registry |

## 5. `docker run` flags

`docker run [flags] IMAGE [command]`

| Flag | Meaning | Example |
|---|---|---|
| `-d` | detached (background) | `docker run -d nginx` |
| `-it` | `-i` keep stdin open, `-t` terminal: interactive shell | `docker run -it alpine sh` |
| `-p HOST:CONTAINER` | publish a port | `-p 8080:80` |
| `-v SRC:DEST` | named volume or bind mount | `-v pgdata:/var/lib/postgresql/data` |
| `-e KEY=VAL` | set an environment variable | `-e TZ=Asia/Kathmandu` |
| `--env-file FILE` | load variables from a file | `--env-file .env` |
| `--name NAME` | fixed container name | `--name web` |
| `--restart POLICY` | `no` (default), `on-failure`, `always`, `unless-stopped` | `--restart unless-stopped` |
| `--rm` | delete the container when it exits | one-off tests |
| `--network NET` | attach to a network | `--network mynet` |
| `--memory`, `--cpus` | cgroup limits | `--memory 512m` |
| `-u UID:GID` | run as a given user, not root | `-u 1000:1000` |

Gotchas:
- `-p` publishes, `EXPOSE` only documents. Without `-p` the host cannot reach the port.
- `-p 127.0.0.1:5432:5432` keeps a port private. A plain `-p 5432:5432` listens on all interfaces, and Docker's iptables rules **bypass ufw**.
- `unless-stopped` vs `always`: both restart after crash or reboot, but `unless-stopped` stays stopped if you stopped it manually.
- Anything after the image name is the command and overrides the image's `CMD`.

## 6. Daily commands

| Command | Use |
|---|---|
| `docker ps` / `docker ps -a` | running containers / including stopped ones |
| `docker logs -f NAME` | follow output (`--tail 100` for the last lines) |
| `docker exec -it NAME sh` | shell inside a running container |
| `docker inspect NAME` | full JSON: IP, mounts, env, restart policy |
| `docker stats` | live CPU, memory, I/O per container |
| `docker stop` / `start` / `restart NAME` | `stop` sends SIGTERM, waits 10 s, then SIGKILL |
| `docker rm NAME` / `rm -f NAME` | delete a container (`-f` kills it first) |
| `docker rmi IMAGE` | delete an image |
| `docker system df` | space used by images, containers, volumes |
| `docker system prune` | delete stopped containers, unused networks, dangling images |

Debug order for a broken container: `docker ps -a` (status and exit code), `docker logs`, `docker inspect`, `docker exec`.

## Quiz results (about 2/4) and mistakes
1. **Data lost on delete: correct.** Add that the data was in the container's writable layer. Fix: a named volume or bind mount.
2. **`-p 8080:80` vs `EXPOSE 80`: backwards.** `-p HOST:CONTAINER`: 8080 is the host port, 80 is inside the container. `EXPOSE` only documents.
3. **Restart loop, first two commands: half right.** First `docker ps -a` (exit code), then `docker logs`.
4. **Why not `:latest`: correct.** Add: silent changes on redeploy, no rollback target. Pin a version, SHA or digest.

Still to practise: write the flag to reach container port 3000 from host port 9000, localhost only (`-p 127.0.0.1:9000:3000`).
