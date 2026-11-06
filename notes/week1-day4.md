# Week 1, Day 4: systemd, units, `.service` files, `journalctl`

> Memorize the concepts, look up long flags with `--help` / `man`. Commands in `code` are the ones to know.
> Weak spots from the quiz are listed at the bottom.

---

## 1. What systemd is

**What**

- systemd is **PID 1**, the first process the kernel starts. Every other process descends from it.
- It starts services at boot, supervises them, restarts them on crash, and collects their logs.
- It **adopts orphans** (re-parents them to PID 1) and reaps them when they exit.

**Quick checks**

| Command | Does |
|---|---|
| `ps -p 1` | confirm PID 1 is systemd |
| `pstree -p \| head` | process tree, systemd at the top |

**Orphan vs zombie**

| | State | Cause |
|---|---|---|
| **Orphan** | still running | its parent died, so PID 1 adopts it |
| **Zombie** | already dead | its parent never called `wait()` to collect the exit status |

**Why**: a `.service` starts at boot, restarts on failure and logs to the journal. `nohup` / `tmux` do none of that. `tmux` is for interactive work, a `.service` is for things that must always run.

---

## 2. Units and unit types

**What**: a unit is a small text file describing one thing systemd manages. The name ends with the type (`ssh.service`).

| Type | Manages | Example |
|---|---|---|
| `.service` | a process / daemon | `ssh.service`, `docker.service` |
| `.timer` | runs another unit on a schedule (cron replacement) | `apt-daily.timer` |
| `.target` | a named group of units, a boot stage | `multi-user.target` |
| `.socket` | listens on a socket, starts a service on demand | `docker.socket` |
| `.mount` | a mount point | `home.mount` |

**Where unit files live**

| Path | Who puts files there |
|---|---|
| `/etc/systemd/system/` | **you**. Highest priority, wins on a name clash. |
| `/run/systemd/system/` | runtime-generated, gone after reboot |
| `/lib/systemd/system/` (or `/usr/lib/systemd/system/`) | installed packages, overwritten by updates |

**Rule**: never edit files in `/lib`. Put your own units (or overrides) in `/etc/systemd/system/`.

| Command | Does |
|---|---|
| `systemctl cat ssh` | print the unit file and the path it came from |
| `systemctl list-unit-files` | all installed units and whether they are enabled |

---

## 3. `systemctl`

**Control a running service** (changing things needs `sudo`)

| Command | Does |
|---|---|
| `systemctl start svc` | start now |
| `systemctl stop svc` | stop now |
| `systemctl restart svc` | stop, then start (brief downtime) |
| `systemctl reload svc` | re-read config **without stopping**, if the service supports it (signal such as SIGHUP) |
| `systemctl status svc` | state, PID, last log lines |

**Start vs enable (independent)**

| Command | Effect now | Effect at next boot |
|---|---|---|
| `start` | runs it | no change |
| `stop` | stops it | no change |
| `enable` | no change | will auto-start |
| `disable` | no change | won't auto-start |
| **`enable --now`** | runs it | will auto-start |

**What `enable` does**: creates a **symlink** from the target's `.wants/` folder to your unit file, e.g. `/etc/systemd/system/multi-user.target.wants/myapp.service` -> `/etc/systemd/system/myapp.service`. `disable` removes it. It reads `WantedBy=` from the `[Install]` section.

**Check state** (no `sudo` needed)

| Command | Does |
|---|---|
| `systemctl is-active svc` | prints `active` / `inactive` |
| `systemctl is-enabled svc` | prints `enabled` / `disabled` |
| `systemctl --failed` | list failed units |
| `systemctl list-units --type=service` | services currently loaded |

**`daemon-reload`**

- `sudo systemctl daemon-reload` makes systemd re-read unit files from disk.
- Run it after **creating or editing** a unit file.
- It does **not** start or restart anything. You still run `start` / `restart` after.

**Reading `systemctl status`**: `Loaded:` (file path, enabled/disabled), `Active:` (`active (running)`, `inactive (dead)`, `failed`, and how long), `Main PID:`, and the last log lines at the bottom.

**Why**: `start` is for now, `enable` is for boot. Forgetting `enable` is the classic "it worked before the reboot" bug.

---

## 4. Anatomy of a `.service` file

```ini
[Unit]
Description=My Go API
After=network.target

[Service]
Type=simple
User=joshua
WorkingDirectory=/opt/myapp
ExecStart=/opt/myapp/server
Restart=on-failure
RestartSec=5
Environment=PORT=8080

[Install]
WantedBy=multi-user.target
```

**The three sections**

| Section | Purpose |
|---|---|
| `[Unit]` | description, dependencies, ordering |
| `[Service]` | how to run the process |
| `[Install]` | what `enable` does (`WantedBy=<target>`) |

**Directives explained**

| Directive | Section | Meaning |
|---|---|---|
| `Description=` | Unit | text shown in `status` and logs |
| `After=` / `Before=` | Unit | ordering only (see topic 6) |
| `Wants=` / `Requires=` | Unit | dependencies (see topic 6) |
| `ExecStart=` | Service | the command to run. **Absolute path**: systemd has no shell and no `PATH` search. |
| `User=` / `Group=` | Service | run as this user, not root |
| `WorkingDirectory=` | Service | directory the process starts in |
| `Environment=KEY=val` | Service | set one variable |
| `EnvironmentFile=/path` | Service | load many variables from a file |
| `Restart=` / `RestartSec=` | Service | restart policy (see topic 5) |
| `Type=` | Service | how systemd decides the service has started |
| `WantedBy=` | Install | which target's `.wants/` folder `enable` links into |

**`Type=`**

| Type | Use when |
|---|---|
| `simple` (default) | the process in `ExecStart` stays in the foreground. **Go web server, most apps.** |
| `forking` | old daemons that fork into the background and the parent exits |
| `oneshot` | runs a task and exits (backup script), often paired with a `.timer` |

**Rule**: don't daemonize your own app (no `nohup`, no `&`). Let it run in the foreground and systemd handles the rest.

**No `[Install]` section**: `enable` has nothing to link and warns. The service still works with a manual `start`, but it won't auto-start at boot.

**Order for a new service**

1. Write `/etc/systemd/system/myapp.service`
2. `sudo systemctl daemon-reload`
3. `sudo systemctl enable --now myapp`  (creates the symlink and starts it)
4. `systemctl status myapp`

---

## 5. Restart policy

`Restart=` in `[Service]`. **Default is `no`: a crashed service stays dead.**

| Value | Restarts when |
|---|---|
| `no` (default) | never |
| `on-failure` | non-zero exit, killed by a signal (`kill -9`, crash, OOM), or timeout. **Not** on clean exit 0. |
| `always` | any exit, including clean exit 0 |
| `on-success` | only on clean exit 0 (rare) |

- `on-failure` is the usual choice for an app like the Go server.
- `systemctl stop` is intentional, so it **never** triggers a restart, whatever `Restart=` says.
- After a reboot it comes back only if the service is `enable`d.
- `RestartSec=5` waits 5 seconds before restarting, so a broken app doesn't spin in a tight loop.

**Crash loop / rate limit**

- Default: more than **5 starts in 10 seconds** and systemd gives up. Status `failed`, message `Start request repeated too quickly`.
- Settings (in `[Unit]`): `StartLimitIntervalSec=` (the window), `StartLimitBurst=` (starts allowed in it).
- A longer `RestartSec` only slows the loop. It doesn't fix the crash.

**What to do**

1. `journalctl -u myapp` to find why it crashes
2. fix the cause
3. `sudo systemctl reset-failed myapp`
4. `sudo systemctl start myapp`

**Test a restart policy**: `kill -9 PID` on the service. With `on-failure` it comes back.

---

## 6. Dependencies and ordering

**Two separate questions**

1. **Ordering**: in what sequence do units start?
2. **Dependency**: does unit A need unit B at all?

Each directive answers only one.

| Directive | Answers | Meaning |
|---|---|---|
| `After=B` | ordering | if both are starting, start me after B. **Does not start B.** |
| `Before=B` | ordering | start me before B |
| `Wants=B` | dependency (weak) | start B too. If B fails, I still start. |
| `Requires=B` | dependency (strong) | start B too. If B fails to start, I fail. If B is stopped later, I stop. |

- `Wants=` / `Requires=` **do not set order**. Without `After=`, both start **in parallel**.
- The "I fail if B fails" behavior of `Requires=` is only reliable when `After=` is also set.
- `After=` waits for B's unit to count as *started*, not for the service to be ready. Apps still need to retry connections (or use `Restart=on-failure`).

**The usual pairing (inside `myapp.service`'s `[Unit]`; `postgresql.service` is a different, existing service)**

```ini
[Unit]
Wants=postgresql.service
After=postgresql.service
```

Use `Requires=` instead of `Wants=` if the app is useless without it.

**Network targets**

| Target | Means | Use for |
|---|---|---|
| `network.target` | network stack configured, **not** connectivity | a service that just listens on a port |
| `network-online.target` | network actually reachable | a service that contacts other machines at start |

```ini
After=network-online.target
Wants=network-online.target
```

**Summary**

| You want | Use |
|---|---|
| a start order | `After=` / `Before=` |
| pull another unit in (optional) | `Wants=` |
| pull another unit in (mandatory) | `Requires=` |
| pulled in **and** ordered | `Wants=`/`Requires=` plus `After=` |

Docker example: `After=docker.service` + `Wants=docker.service`.

---

## 7. Targets

**What**: a `.target` runs no process. It is a **named group of units** marking a boot stage. A target is *reached* (active) once its units are up.

| Target | Meaning |
|---|---|
| `multi-user.target` | normal server mode: network, services, text login, no GUI. **`devlab` boots to this.** |
| `graphical.target` | `multi-user` plus display manager / GUI. The Fedora PC boots to this. |
| `network.target` | network stack configured |
| `network-online.target` | network actually reachable |
| `rescue.target` | single-user mode with basic services, for repairs |
| `emergency.target` | bare minimum, root shell, root filesystem read-only |
| `reboot.target` / `poweroff.target` | reboot / shutdown stages |

**Old runlevels (memorize)**

| Runlevel | Target |
|---|---|
| 0 | `poweroff.target` |
| 1 | `rescue.target` |
| 3 | `multi-user.target` |
| 5 | `graphical.target` |
| 6 | `reboot.target` |

**Commands**

| Command | Does |
|---|---|
| `systemctl get-default` | the target the system boots to |
| `sudo systemctl set-default multi-user.target` | change the default target |
| `sudo systemctl isolate rescue.target` | switch to that stage now (stops units that don't belong; can drop your SSH session) |

**How it connects**

- `WantedBy=multi-user.target` is only read by `enable`, which creates the symlink in `multi-user.target.wants/`.
- At boot systemd reaches the target and starts everything linked in its `.wants/`. It does **not** read `WantedBy=` at boot.
- Ordering comes from `After=`/`Before=` and from target-to-target links (`graphical` requires and follows `multi-user`), not from `WantedBy=`.
- See the symlinks: `command ls -l /etc/systemd/system/multi-user.target.wants/` (use `command ls`, `ls` is aliased to `eza`).

**Broken boot (bad `fstab`)**: boot into `rescue.target` or `emergency.target` and fix `/etc/fstab`. systemd often drops into emergency mode by itself when a mount fails.

---

## 8. `journalctl`

`journald` collects logs from services, the kernel and the system. `journalctl` reads them.

**First two commands for any broken service**

1. `systemctl status svc`
2. `journalctl -u svc`

**Core**

| Command | Shows |
|---|---|
| `journalctl` | everything, oldest first |
| `journalctl -u svc` | one unit |
| `journalctl -u svc -f` | **follow** live (like `tail -f`) |
| `journalctl -b` | current boot only |
| `journalctl -b -1` | previous boot (needs a persistent journal) |
| `journalctl -e` | jump to the end |
| `journalctl -n 50` | last 50 lines |
| `journalctl -r` | newest first (reverse) |
| `journalctl -k` | kernel messages only (like `dmesg`) |
| `journalctl --no-pager` | print straight to the terminal (for piping into `grep`) |
| `journalctl -o cat` | message text only, no metadata |
| `journalctl -o json` | structured JSON output |

**Filter by time**

| Option | Meaning |
|---|---|
| `--since "1 hour ago"` | last hour |
| `--since today` | since midnight |
| `--since "2026-11-05 10:00" --until "2026-11-05 11:00"` | a window |

**Filter by priority**: `-p LEVEL` shows that level **and everything more severe**.

| Level | Name |
|---|---|
| 0 | emerg |
| 1 | alert |
| 2 | crit |
| 3 | err |
| 4 | warning |
| 5 | notice |
| 6 | info |
| 7 | debug |

Example: `journalctl -u myapp -p err -b` = errors from `myapp` this boot.

**Journal size and cleanup**

| Command | Does |
|---|---|
| `journalctl --disk-usage` | space the journal uses |
| `sudo journalctl --vacuum-time=7d` | delete entries older than 7 days |
| `sudo journalctl --vacuum-size=500M` | cap total size |

**Permissions**: a normal user sees only their own logs. To read system logs without `sudo`: `sudo usermod -aG systemd-journal USER` (Day 2: `-a` appends, without it you replace all groups).

**Persistence**: if `/var/log/journal/` exists, logs survive reboots. If not, they live in memory (`/run/log/journal/`) and vanish at reboot, so `-b -1` has nothing.

**Typical troubleshooting flow**

1. `systemctl status myapp` shows `failed`
2. `journalctl -u myapp -n 50 --no-pager` (the error is usually in the last lines)
3. fix the cause; `daemon-reload` if the unit file changed; `restart`
4. `journalctl -u myapp -f` to watch it come back

---

## 9. Boot order

**UEFI/BIOS -> GRUB -> kernel -> initramfs -> systemd (PID 1) -> targets**

| Step | What happens |
|---|---|
| 1. UEFI/BIOS | firmware self-check (POST), finds the boot device, loads the bootloader |
| 2. GRUB | boot menu, loads the **kernel** and **initramfs** into memory, passes kernel parameters |
| 3. Kernel | initializes hardware, uses the initramfs to reach and mount the real root filesystem |
| 4. initramfs | small temporary filesystem in memory with the drivers/tools (disk, LVM, encryption) needed to find the real root |
| 5. systemd | started by the kernel as PID 1; mounts filesystems from `fstab`, starts units |
| 6. Targets | works toward the default target (`multi-user.target` on `devlab`), starts everything linked there |
| 7. Login | `sshd` is up, login prompt appears |

**Why initramfs**: the kernel needs drivers to read the disk, but the drivers are on the disk. The initramfs is loaded into memory with just enough to reach the real root. UEFI boots from the EFI system partition (ESP), BIOS from the disk's first sector (MBR).

**Where failures show up**

| Symptom | Stage | Try |
|---|---|---|
| nothing displays, no boot device | UEFI/BIOS | check boot order and the disk |
| GRUB prompt / "file not found" | GRUB | repair or reinstall the bootloader |
| kernel panic / can't mount root | kernel / initramfs | boot an older kernel from GRUB, regenerate the initramfs |
| drops to emergency shell | systemd | usually a bad `fstab` entry; `journalctl -xb` and fix it |
| boots but a service is missing | targets | `systemctl --failed`, `journalctl -u svc` |

| Command | Does |
|---|---|
| `systemd-analyze` | total boot time |
| `systemd-analyze blame` | units sorted by how long they took to start |
| `journalctl -b` / `journalctl -xb` | this boot's logs (`-x` adds explanations) |

---

## 10. systemd timers (bridge to Week 3)

A `.timer` runs a `.service` on a schedule. Two files with the same name: `backup.service` (the job, usually `Type=oneshot`) and `backup.timer` (the trigger).

```ini
[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

| Item | Meaning |
|---|---|
| `OnCalendar=` | the schedule, e.g. `daily`, `Mon *-*-* 02:00:00` |
| `Persistent=true` | if the machine was off at the scheduled time, run it at next boot (cron can't do this) |
| `systemctl enable --now backup.timer` | enable the **timer**, not the service |
| `systemctl list-timers` | what is scheduled and when it last ran |

**Why over cron**: logs in the journal, missed runs caught up, dependencies and restart policy work, schedule visible with `list-timers`.

---

## One-page essentials

- systemd = PID 1. Adopts orphans. Zombie = dead, parent didn't `wait()`. Orphan = alive, parent died.
- Own units go in `/etc/systemd/system/`. Never edit `/lib/systemd/system/`.
- New service: write file -> `daemon-reload` -> `enable --now` -> `status`.
- `start` = now, `enable` = at boot, `enable --now` = both. `daemon-reload` does not restart anything.
- `enable` creates the symlink (from `WantedBy=`). `daemon-reload` does not.
- `ExecStart=` needs an absolute path (no shell, no `PATH`).
- `Type=simple` for a Go server, `oneshot` for a one-time script.
- `Restart=` default is `no`. Use `on-failure` + `RestartSec=5`. `systemctl stop` never triggers a restart.
- "Start request repeated too quickly" = crash loop. Read the journal, fix, `reset-failed`, `start`.
- `After=` is ordering only. `Wants=`/`Requires=` pull in only. Use both.
- `network-online.target` when the service must reach other machines.
- Targets: runlevel 3 = `multi-user`, 5 = `graphical`, 1 = `rescue`, 0 = `poweroff`, 6 = `reboot`. Broken `fstab` -> `rescue`/`emergency`.
- Broken service: `systemctl status svc`, then `journalctl -u svc -n 50 --no-pager`.
- Boot: UEFI -> GRUB -> kernel -> initramfs -> systemd -> targets.

---

## Quiz mistakes / weak spots (requiz later)

- Orphan vs zombie wording (zombie is already dead; orphan is alive and adopted by PID 1).
- `daemon-reload` is the step before a new unit is known, and it does not start anything. `enable` creates the symlink, not you and not `daemon-reload`.
- `enable --now` is the single command for "start now and at boot".
- Why `ExecStart=` needs an absolute path (no shell, no `PATH`), not "because the service reads the file path".
- `Type=` (simple / forking / oneshot) was not known at first.
- `WantedBy=` names a **target**, not the service. systemd follows the `.wants/` symlinks at boot and does not read `WantedBy=`.
- `Requires=` alone does not order anything (parallel start). Pair it with `After=`.
- Runlevel 3 = `multi-user.target` (not 0). Broken `fstab` -> `rescue`/`emergency` target, not `multi-user`.
- Boot sequence needs the firmware step first (UEFI/BIOS) and targets last.
