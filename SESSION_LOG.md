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

*Reported done by the user. Not re-verified after the reinstall: run `sudo bash bootstrap.sh verify` on the server.*

## Continue from here

1. Verify the server: `ssh devlab`, then `sudo bash bootstrap.sh verify`. Expect `passwordauthentication no`, `permitrootlogin no`, ufw active, fail2ban and unattended-upgrades active.
2. Fill in `notes/concepts.md` (the user's own words: why keys beat passwords, why `ufw allow` comes before `enable`).
3. Tick Week 0 in the roadmap tracker.
4. **Start Week 1, Day 1** (filesystem, navigation, file ops, vim, `apt`). Create `notes/week1-day1.md`.
5. Week 1 lab to plan for: LVM on the empty HDD (PV, VG, LV, mkfs, mount, fstab by UUID).

## Session history

### Session 1 (2026-11-04)
- Created the private repo and notes skeleton.
- Walked through SSH hardening, `ufw`, `fail2ban`, `unattended-upgrades`; wrote `notes/day-01.md`.
- Found the Ubuntu install was on the HDD and the SSD held an old Linux Mint. Decided to reinstall on the SSD and wipe both drives.
- Wrote `scripts/bootstrap.sh` (two phases: setup, then `harden`).
- Created this file.
