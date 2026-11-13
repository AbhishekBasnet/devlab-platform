# Week 3 Day 3: Backup script with rotation

Taught as concepts only (quiz-only mode, no script written). The check questions at the end are still unanswered.

Goal: a script that runs daily without you, makes a compressed copy of the Plex and ABS **config** dirs, keeps only the newest 7 copies, and fails loudly if something breaks.

## Essentials
- Back up **config**, not media. Config (library database, users, settings) is small and cannot be re-downloaded. Media is huge and already lives on the NAS.
- A backup on the same disk is not a real backup: if the disk dies, both die. Rule of thumb **3-2-1**: 3 copies, 2 kinds of storage, 1 off-site.
- Name archives `YYYY-MM-DD.tar.gz` so alphabetical order is date order. Rotation depends on this.
- Write to `NAME.partial`, then `mv` to the real name. A rename is instant, so a half-written file never looks like a real backup.
- Rotate by **count** (keep the newest 7), not by age. If the server is off for 10 days, `-mtime +7` would delete everything.
- Exit `0` on success, non-zero on failure. cron and systemd read the exit code. A script that fails but exits 0 is worse than no script.

## 1. What to back up, and where

| Question | Answer |
|---|---|
| What? | The Plex and ABS config dirs only |
| Why not media? | Too big, and it is already on the NAS |
| Where to? | `/backups/YYYY-MM-DD.tar.gz` (copy to the NAS or cloud later for the off-site copy) |

## 2. Making the archive

```bash
tar -czf /backups/2026-11-07.tar.gz /path/plex /path/abs
```

| Item | Meaning |
|---|---|
| `tar` | bundles many files into one archive |
| `-c` | create |
| `-z` | compress with gzip |
| `-f FILE` | name of the output file |
| `date +%F` | prints `2026-11-07` (year-month-day) |

## 3. No half-written backups

If `tar` fails halfway, `2026-11-07.tar.gz` would exist but be broken. Nobody notices at 3 a.m., and a week later you restore from it.

```bash
tmp="$final.partial"
trap 'rm -f "$tmp"' EXIT     # delete the partial file if the script dies
tar -czf "$tmp" -- "$@"
mv "$tmp" "$final"           # only reached if tar succeeded
```

## 4. Rotation (keep the last 7)

```bash
find /backups -maxdepth 1 -name '????-??-??.tar.gz' | sort -r | tail -n +8
```
1. `find` lists the backups.
2. `sort -r` puts the newest first (works because of the date names).
3. `tail -n +8` means "start at line 8": everything except the newest 7. Those are the ones to delete.

Preview that list first. Only then add the delete (`xargs rm` or a loop with `rm --`).

| Approach | Problem |
|---|---|
| `find -mtime +7 -delete` | If the server was off for 10 days, it deletes every backup |
| `sort -r \| tail -n +8` | Always leaves 7 copies, whatever the dates |

## 5. Logging and exit codes
- Write a timestamped line for start, success, each deletion, and every error (`>> /var/log/backup.log`).
- Exit non-zero on any failure so cron/systemd can report it.
- Check the source dirs exist **before** running `tar`.

## 6. Safety review checklist (from `week3-bash.md`)
- Quote every `"$var"`.
- `set -euo pipefail` as the second line.
- `"${BACKUP_DIR:?not set}"` so an empty variable cannot turn a delete into `rm /*`.
- Absolute paths everywhere: cron has a minimal `PATH` and a different working directory.
- Run the delete selector with no delete first, then add the delete.

## Check questions (unanswered)
1. Why is a backup on the same disk not safe, and what is one fix?
2. Why write to `.partial` and then `mv`?
3. Why does `sort -r | tail -n +8` pick the right files to delete, and why is it safer than `-mtime +7`?
