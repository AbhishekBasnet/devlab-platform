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
4. **Week 1 Day 3** (processes, signals, `top`/`htop`, `tmux`, background jobs): **finished** (2026-11-05). Notes in `notes/week1-day3.md` (commands, flag meanings, one-page essentials list, quiz mistakes). Quizzed 3 times: concepts solid, command syntax weaker. The user will requiz later. Weak spots: you can't move an already-running job into `tmux` (use `Ctrl+Z`, `bg`, `disown`), SIGKILL can't be caught so no cleanup, ways to survive an SSH drop (`nohup`, `disown`, `tmux`), load average counts processes not cores (compare to `nproc`), exact order of `tmux new -s` / `tmux a -t`, `nice -n 10 cmd` and `renice -n 5 -p PID`, `nohup cmd > out.log 2>&1 &`.
5. **Week 1 Day 4** (systemd: units, `systemctl`, `.service` files, restart policy, dependencies, targets, `journalctl`, boot order, timers): **finished** (2026-11-06), notes in `notes/week1-day4.md`. Only a per-topic mini quiz was done, no final scenario quiz. **The user will requiz later.** Weak spots: `daemon-reload` vs `enable` (`enable` creates the symlink, `daemon-reload` starts nothing), `enable --now`, why `ExecStart=` needs an absolute path (no shell, no `PATH`), `Type=simple|forking|oneshot`, `WantedBy=` names a target and is only read by `enable`, `Requires=` alone does not order (pair with `After=`), runlevel 3 = `multi-user.target`, broken `fstab` -> `rescue`/`emergency` target, boot sequence starts with UEFI/BIOS and ends with targets. Orphan (alive, adopted by PID 1) vs zombie (dead, parent never `wait()`ed) wording.
6. **Week 1 Day 5** (disks: `df`/`du`/`lsblk`/`mount`/`fstab`, LVM, swap): **taught topics 1 to 7** (2026-11-06), notes in `notes/week1-day5.md`. **Still to do: the topic 8 final scenario quiz** (8 questions, unanswered) and the unanswered checks 3 to 7. Weak spots so far: mounting is the third step (partition, `mkfs`, `mount`), "can't create files but space is free" = inodes (`df -i`), `du -x` means one filesystem (not "biggest first"). Then weekend (logs, `dmesg`, time sync, break-it drills).
7. LVM lab on the empty HDD is optional. Needs explicit confirmation before touching the disk.

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

### Session 4 (2026-11-05)
- Week 1 Day 3 (processes, signals, `top`/`htop`, `tmux`, background jobs): taught, written up and quizzed. **Day 3 is finished.**
- Wrote `notes/week1-day3.md`: ten topics, each with what/why/where used, need-to-know command tables, flag explanations, a one-page essentials list, and the user's quiz mistakes. Fixed blank lines so the tables render in Okular.
- Replaced hard-to-read `ps aux --sort ... | head` with clean versions (`ps -eo pid,user,%cpu,%mem,comm --sort=-%mem | head`, `top -bn1`, `pgrep -l`).
- Quizzed three times: concept quiz, essentials quiz (about 6.5 of 12), scenario quiz (about 7 of 10). Concepts good. Exact command syntax weak.
- Agreed approach: memorize only the short daily commands and the concepts; use `--help`, `man`, and aliases for long ones. Later requizzes are scenario-based (what to do and which tool), not exact flags.
- Note for later: the Firefox `bwrap <defunct>` zombie on the Fedora PC is harmless (parent is Firefox).

### Session 5 (2026-11-06)
- Week 1 Day 4 (systemd): taught topics 1 to 10 in order (what systemd is, unit types and paths, `systemctl`, `.service` anatomy, restart policy, dependencies and ordering, targets, `journalctl`, boot order, timers) with a short check after most topics.
- Scores per topic: about 2.5/3, 3/3, 2.5/4, 1.5/5 (the `.service` anatomy topic, weakest), 4/5, 3/5 (targets). The `journalctl` and boot-order checks were skipped or half answered by choice (the user can look up commands).
- Clarified two confusions: the dependency examples (`myapp.service` is the file being written, `postgresql.service` is a separate existing service), and `Requires=` without `After=` (starts in parallel, no waiting).
- Wrote `notes/week1-day4.md` (commands, flag tables, one-page essentials, quiz weak spots) and pushed it.
- Also committed the Day 3 note and the Session 4 log entry that were left uncommitted.
- No labs this week (quiz-only mode), so nothing was deployed on `devlab`.
- **Day 4 (systemd) marked finished** at the end of this session. No final scenario quiz was done; the user will requiz later.

### Session 6 (2026-11-06)
- Week 1 Day 5 (disks): taught block device/partition/filesystem, `lsblk`/`blkid`/`df`/`du`, mounting, `fstab` (including `nofail`), full-disk troubleshooting (deleted-but-open files, inodes), LVM, swap, `swappiness` and the OOM killer.
- Check scores: about 2.7/3 (layers) and 1/3 (seeing disks). The later checks and the final scenario quiz were not answered, so they carry over to the next session.
- Wrote `notes/week1-day5.md`, topic by topic as the user asked.
- No labs (quiz-only mode), so nothing was changed on `devlab`.
