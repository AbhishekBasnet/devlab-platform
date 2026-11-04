# Week 1, Day 1: Filesystem, navigation, file ops, vim, apt

> Quiz-style review (no labs). Confusions and corrections below.
> Use `command ls` on Fedora (ls is aliased to eza).

## Quiz result
Solid: `/etc`, `/var/log`, `/opt`, `/tmp`, `remove` vs `purge`, vim save/quit, soft link idea.
Needs work: `apt update` vs `upgrade`, `/proc` and `/sys`, `find` syntax, hard links and inodes.

## Confusions and corrections

### apt update vs apt upgrade
- I thought: update updates the whole system.
- Correct: `apt update` only refreshes the package list (installs nothing). `apt upgrade` installs the newer versions.

### remove vs purge
- `remove` deletes the package but keeps its **config files** (not logs). `purge` deletes the config files too.

### /proc and /sys
- I thought: kernel and system files, "everything is a file".
- Correct: virtual filesystems that live in memory, not on disk. `/proc` = processes + kernel info (`/proc/cpuinfo`, `/proc/<pid>/`). `/sys` = devices, drivers, kernel settings.

### /var/lib
- Persistent app state (databases, Docker images and volumes), not just Docker.

### find
- I wrote: `find foo.conf`. That treats `foo.conf` as the start directory.
- Correct: `find / -name foo.conf 2>/dev/null`
  - `find /` start at root
  - `-name foo.conf` match this name
  - `2>/dev/null` throw away stderr (hides the "Permission denied" noise from dirs a normal user can't read)
  - or `sudo find / -name foo.conf`

### Hard link vs soft link (biggest confusion)
- I thought: a hard link is a copy, and a deleted original breaks the link. I had them backwards at one point.
- An **inode** is the filesystem's record for a file: data location, size, owner, permissions, timestamps. It does **not** store the filename.
- A filename is just a directory entry pointing to an inode number.
- **Hard link** = a second name for the **same inode**. Not a copy, no extra space. Edit through either name and both show it.
- `rm a` removes only the name `a` and drops the **link count** by 1. The data is freed only when the count hits 0 (and no process has it open).
- **Soft link** (`ln -s`) = its own tiny file holding a **path as text**. Delete the target and it breaks.

```
a ──┐
    ├──> inode 1234 (count 2) ──> data
b ──┘
rm a  →  b ──> inode 1234 (count 1) ──> data still there
```

- Check with `ls -li` (same inode number for hard links).
- Still to answer: why can't a hard link cross filesystems?

## Done when
I can explain inodes and link counts without notes and write the `find` command from memory.
