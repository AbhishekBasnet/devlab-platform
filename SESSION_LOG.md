# SESSION_LOG.md

> **PROTECTED FILE. Never delete, rename or overwrite this file. Any session may only append to the "Session history" section.**
>
> **Every session:** read this file first. At the end of the session, add an entry and update "Continue from here", then commit and push.

## Server (basic info)

| | |
|---|---|
| Name | `devlab` |
| IP | `192.168.2.158` (reserved in OpenWrt, static lease) |
| User | `joshua` |
| Login | `ssh devlab` (key only, `~/.ssh/config` on the Fedora PC) |
| OS | Ubuntu Server (resolute), on the 119G SSD (LVM, root volume 58G, rest of the group free) |
| HDD | 465G, empty and unmounted. Reserved for the Week 1 LVM lab. |
| Hardware | Lenovo IdeaPad S410 laptop (lid switch set to ignore) |
| PC | Fedora 44 KDE (`/mnt/Projects/Backend/devops/learning/devlab-platform`) |

## Where things are

- Roadmap (the plan): `/mnt/Projects/Backend/devops/devops-roadmap.md`
- Repo (private): `github.com/AbhishekBasnet/devlab-platform`
- Notes: `notes/` (`day-01.md`, `cheatsheet.md`, `concepts.md`, `incidents.md`)
- Setup script: `scripts/bootstrap.sh` (`sudo bash bootstrap.sh`, then `harden`, then `verify`)

## Rules

- **The AI rule from the roadmap:** the user does the labs themselves, from memory and docs. Use AI to explain errors and concepts, not to write the config for them.
- No Claude/Anthropic attribution lines in git commits or PR descriptions.
- Destructive steps (wiping disks, deleting keys) need explicit confirmation first.
- Fedora's `ls` is aliased to `eza`. Use `command ls` for plain `ls`.

## Finished

**Week 0 (setup):** complete.
- Private repo `devlab-platform` with `notes/` created and pushed.
- OS reinstalled on the SSD (the first install was on the HDD). Both drives wiped first.
- Key-based SSH login. Password and root login disabled (checked with `sshd -T`, including the `50-cloud-init.conf` override).
- `ufw` active, SSH only. `fail2ban`, `unattended-upgrades`, `tmux` installed.
- Static IP reserved on OpenWrt, survives reboots.
- GitHub keys cleaned. Only the Fedora key (titled "GitHub CLI") remains.
- Notes written: `day-01.md` (checklist), `incidents.md` (SSH override entry).

*Verified on the new install (2026-11-04) with `sudo bash bootstrap.sh verify`: `permitrootlogin no`, `passwordauthentication no`, ufw active (OpenSSH only), fail2ban and unattended-upgrades active, IP 192.168.2.158 on `enp1s0`.*

## Continue from here

Mode for Week 1: quiz-only, no labs. The user answers, Claude grades and says plainly when something is wrong or unknown. Notes are written only when the user says so.

1. Fill in `notes/concepts.md` (the user's own words: why keys beat passwords, why `ufw allow` comes before `enable`). Still empty.
2. **Week 1 Day 1:** quizzed and finished. Notes in `notes/week1-day1.md`. Still open: why a hard link can't cross filesystems.
3. **Week 1 Day 2** (users, groups, `sudo`, permissions, `umask`, special bits): taught and quizzed once, finished for now. No notes file by request. **The user will requiz later.** Weak spots from the first quiz: `usermod -aG group user` syntax and what `-a` does, what `/etc/passwd` holds vs `/etc/shadow`, `sudo` vs `su` and why `visudo`, setgid on a directory (new files inherit the folder's group), sticky bit, reading `---s--x--x`, directories start at 777 for umask.
4. **Next: Week 1 Day 3** (processes, signals, `top`/`htop`, `tmux`, background jobs). Quiz format.
5. Then D4 (systemd), D5 (disks, LVM, swap), weekend (logs, `dmesg`, time sync).
6. LVM lab on the empty HDD is optional. Needs explicit confirmation before touching the disk.

## Session history

### Session 1 (2026-11-04)
- Created the private repo and notes skeleton.
- Walked through SSH hardening, `ufw`, `fail2ban`, `unattended-upgrades`; wrote `notes/day-01.md`.
- Found the Ubuntu install was on the HDD and the SSD held an old Linux Mint. Decided to reinstall on the SSD and wipe both drives.
- Wrote `scripts/bootstrap.sh` (two phases: setup, then `harden`).
- Created this file.

### Session 2 (2026-11-04)
- Read the log and roadmap. Week 0 was already verified, so no server work this session.
- Ticked Week 0 in the roadmap tracker (`devops-roadmap.md`).
- Created the skeleton `notes/week1-day1.md` (tasks and empty note sections, no answers, per the AI rule).
- Left `notes/concepts.md` for the user to write.

### Session 3 (2026-11-04 to 2026-11-05)
- Switched to quiz-only mode for Week 1 (no labs).
- Quizzed Day 1 (filesystem, `apt`, links). Corrections written to `notes/week1-day1.md` and committed.
- Taught and quizzed Day 2. Main confusions worked through: octal vs letter `chmod`, `umask`, numeric UIDs, `/etc/passwd` vs `/etc/shadow`, setuid/setgid/sticky (file vs directory), what `sudo` does as a setuid program. First quiz about 4 of 9. User will requiz later; no notes file.
- Inspected the Fedora Plex and ABS containers (read-only). Plex and ABS run as root inside Docker (no `PUID`/`PGID`). NAS volumes are CIFS with the credentials in plain text in the Docker volume options, so the NAS password should be changed and moved to a `credentials=` file.
