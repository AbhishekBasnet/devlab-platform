# Week 1, Day 5: disks, mounts, `fstab`, LVM, swap

> Memorize the concepts, look up long flags with `--help` / `man`. Commands in `code` are the ones to know.
> Weak spots from the quiz are listed at the bottom.

---

## 1. Block device, partition, filesystem

**What**: three layers stacked on top of each other.

| Layer | What it is | Example |
|---|---|---|
| **Block device** | The raw disk (HDD, SSD, USB). The kernel exposes it as a file in `/dev`. | `/dev/sda`, `/dev/sdb`, `/dev/nvme0n1` |
| **Partition** | A numbered slice of the disk. | `/dev/sdb1` |
| **Filesystem** | The structure written into a partition that stores names, files, permissions and inodes. | `ext4`, `xfs` |

**Steps to use a new disk**: partition (optional) -> `mkfs` (write a filesystem) -> `mount` (attach it to a directory). Without all three, `cp` to it won't work.

- `mkfs` **erases** whatever was on the device. Double-check the device name first.
- A raw disk can also go straight to LVM (topic 6) instead of getting a filesystem directly.
- `sdb` is the whole block device. `sdb1` is a partition on it.

| Filesystem | Grow | Shrink |
|---|---|---|
| `ext4` (Ubuntu default) | yes, online | yes, offline only |
| `xfs` | yes | **no** |

**On `devlab`**: the 119G SSD holds the OS (LVM). The 465G HDD is empty, with no partition or filesystem.

---

## 2. Seeing disks

| Command | Shows | Key detail |
|---|---|---|
| `lsblk` | Tree of disks, partitions, LVM volumes and mount points | `lsblk -f` adds filesystem type and UUID. An empty FSTYPE column means no filesystem. |
| `blkid` | UUID and filesystem type of each device | Needs `sudo`. These UUIDs are what `fstab` uses. |
| `df -h` | **Used and free space** per mounted filesystem | `-h` = human-readable sizes. Only shows *mounted* filesystems. |
| `df -i` | **Inode** usage per filesystem | Inodes full = can't create files, even with free space |
| `du -sh dir` | Total size of one directory | `-s` = summary only, `-h` = human-readable |
| `du -xh / 2>/dev/null \| sort -rh \| head` | The biggest directories | See flags below |

**Flags in the last command**

| Part | Meaning |
|---|---|
| `-x` | stay on one filesystem (skips `/proc`, other mounts, network shares) |
| `2>/dev/null` | hide "permission denied" errors (use `sudo` to see everything) |
| `sort -rh` | sort by human-readable size, biggest first |
| `head` | first 10 lines |

**Key idea**: `df` asks the *filesystem* how full it is. `du` adds up the *files it can see*. They can disagree (deleted-but-open files, see topic 5).

**Quick picks**

| Question | Command |
|---|---|
| Which disks exist and what is on them? | `lsblk -f` |
| What is the UUID of a device? | `sudo blkid` |
| How full is each mount? | `df -h` |
| Can't create files but space is free? | `df -i` |
| What is eating the space? | `sudo du -xh / 2>/dev/null \| sort -rh \| head` |

---

## 3. Mounting

**What**

- A filesystem isn't reachable until you **mount** it on a directory. That directory is the **mount point**.
- Linux has one tree starting at `/`. Every disk is attached somewhere in it. There are no drive letters.
- Whatever was in the mount-point directory is **hidden** while something is mounted there.

| Command | Does |
|---|---|
| `sudo mount /dev/sdb1 /mnt/data` | mount the partition on `/mnt/data` (the directory must exist first) |
| `findmnt` (or `mount`) | list what's mounted and where. `findmnt` is the readable one. |
| `sudo umount /mnt/data` | unmount (the command is `umount`, no "n") |
| `sudo mount -a` | mount everything listed in `/etc/fstab`. Use it to **test `fstab` edits** without rebooting. |

**Things to know**

- A manual `mount` is **lost on reboot**. Making it permanent is what `/etc/fstab` is for (topic 4).
- `umount` fails with "target is busy" if a process is using the mount, even a shell that has `cd`'d into it. Find who with `fuser -vm /mnt/data` or `lsof +f -- /mnt/data`, then leave the directory or stop the process.
- Network shares (NFS, CIFS like the NAS volumes on the Fedora PC) mount the same way. Only the source differs.

---

## 4. `/etc/fstab`

**What**: the file systemd reads at boot to decide what to mount and where. It makes mounts permanent.

One line, six columns:

```
UUID=1a2b-3c4d  /mnt/data  ext4  defaults  0  2
```

| # | Column | Meaning |
|---|---|---|
| 1 | device | what to mount. **Use `UUID=...`**, not `/dev/sdb1` |
| 2 | mount point | the directory to mount it on (must exist) |
| 3 | type | `ext4`, `xfs`, `cifs`, `swap`... |
| 4 | options | `defaults`, plus extras like `nofail` or `noatime` |
| 5 | dump | old backup flag. Almost always `0` |
| 6 | fsck order | `1` for `/`, `2` for other disks, `0` to skip the check |

**Why UUID, not `/dev/sdb1`**

- Names like `/dev/sdb` depend on detection order. Plug in another disk and `sdb` can become `sdc`, so the wrong disk gets mounted.
- A UUID belongs to the filesystem and never changes. Get it with `sudo blkid` or `lsblk -f`.

**Useful options**

| Option | Does |
|---|---|
| `defaults` | the normal set (`rw`, `suid`, `exec`, `auto`, `async`...) |
| `nofail` | don't block boot if the device is missing. Use it for secondary disks (HDD, USB). |
| `noatime` | don't update the access time on every read (less disk writing) |
| `ro` | mount read-only |

**Why a typo is dangerous**

- A bad line (wrong UUID, bad option, missing disk) can drop boot into **emergency mode**. This is the `rescue`/`emergency` target from Day 4.
- Without `nofail`, one missing disk can stop the whole boot.

**`nofail` in detail**

- By default a mount in `fstab` is **required**. If it fails, systemd treats it as a failed dependency of `local-fs.target` and drops to emergency mode.
- `nofail` makes it optional: boot continues, the mount just doesn't happen, and the failure shows up in `journalctl -b`.
- Use it for anything the system doesn't need to boot: the HDD on `devlab`, USB drives, NAS/CIFS/NFS shares.
- Never use it on `/` or on a mount the OS can't run without (like a separate `/var`).
- Related: `x-systemd.device-timeout=5s` shortens the wait for a missing device (the default wait is about 90 seconds). Example: `defaults,nofail,x-systemd.device-timeout=5s`.
- `nofail` hides the problem rather than fixing it. If an app writes to the mount point while the disk is missing, the data lands on the **root disk** underneath. Check that the mount is really there (`findmnt /mnt/data`).

**Safe workflow**

| Step | Command |
|---|---|
| 1. Back up | `sudo cp /etc/fstab /etc/fstab.bak` |
| 2. Edit | `sudo nano /etc/fstab` |
| 3. Test | `sudo mount -a` (an error here means fix it **before** rebooting) |
| 4. Reboot | only when `mount -a` is silent |

**Recovery if boot breaks**

1. Get to the emergency shell (enter the root password, or edit the GRUB line if root is locked).
2. `mount -o remount,rw /` (root is read-only in emergency mode).
3. Fix `/etc/fstab` (or restore `fstab.bak`).
4. `mount -a` to check, then `reboot`.

---

## 5. Full-disk troubleshooting

**What**: "the disk is full" has three different causes, each with its own command.

| Symptom | Cause | Command |
|---|---|---|
| `df -h` shows 100% | Real files fill the space | `sudo du -xh / 2>/dev/null \| sort -rh \| head` |
| `df -h` shows 100%, but `du` finds far less | A **deleted file is still held open** by a process | `sudo lsof +L1` |
| Can't create files, `df -h` shows free space | **Inodes** are exhausted | `df -i`, then find the directory with millions of files |

**1. Real files**

- Usual suspects: `/var/log`, Docker (`/var/lib/docker`: images, container logs), old backups, `/tmp`.
- Fix: delete or rotate the files. Prevent a repeat with log rotation, Docker `max-size`, backup retention and a disk alert at about 85%.

**2. Deleted but open (the classic trap)**

- When you `rm` a file that a process still has open, the name disappears but the **space is not freed** until the process closes it.
- `du` can't see it (no name), but `df` still counts it. That is why they disagree.
- `lsof +L1` lists open files with **link count below 1**, which means deleted.

| Fix | Command |
|---|---|
| Restart the process holding it | `sudo systemctl restart svc` |
| Truncate through `/proc` without a restart | `: > /proc/<PID>/fd/<N>` |
| Prevention: empty a log, don't delete it | `truncate -s 0 file.log` |

**3. Inode exhaustion**

- Every file uses one inode. The number is fixed when the filesystem is made.
- Millions of tiny files (cache, sessions, mail queue) can use them all up while `df -h` looks fine.
- `df -i` shows `IUse%` at 100%. Fix: delete the many small files.
- Find the culprit directory: `sudo find / -xdev -type f | cut -d/ -f1-3 | sort | uniq -c | sort -rn | head`.

**Reserved blocks (extra)**: `ext4` reserves about 5% of space for root, so a disk can look full to normal users while root can still write.

**Order to check**: `df -h` -> `df -i` -> `du` for big directories -> `lsof +L1` if `df` and `du` disagree.

---

## 6. LVM

**What**

- LVM adds a flexible layer between physical disks and filesystems. You can grow volumes later without repartitioning.
- Three layers, built bottom-up:

| Layer | Full name | What it is | Create |
|---|---|---|---|
| **PV** | Physical Volume | a disk or partition prepared for LVM | `pvcreate /dev/sdb` |
| **VG** | Volume Group | a pool made from one or more PVs | `vgcreate vg0 /dev/sdb` |
| **LV** | Logical Volume | a slice of the pool. This is what you put a filesystem on. | `lvcreate -L 10G -n data vg0` |

- The LV path is `/dev/vg0/data` (also `/dev/mapper/vg0-data`).
- After that it is normal: `mkfs.ext4 /dev/vg0/data`, `mount`, `fstab`.

**Look at it**

| Command | Shows |
|---|---|
| `pvs` / `vgs` / `lvs` | short summary of each layer. `vgs` shows **free space in the pool** (`VFree`). |
| `pvdisplay` / `vgdisplay` / `lvdisplay` | detailed versions |
| `lsblk` | the whole tree, including LVs |

**Growing a volume (the main reason to use LVM)**

| Step | Command |
|---|---|
| 1. Check the pool has free space | `vgs` (look at `VFree`) |
| 2. If not, add a disk to the pool | `pvcreate /dev/sdc` then `vgextend vg0 /dev/sdc` |
| 3. Grow the LV **and** its filesystem | `lvextend -r -L +5G /dev/vg0/data` |

**Flags**

| Flag | Meaning |
|---|---|
| `-r` | also resize the filesystem. Without it the LV is bigger but `df` shows no change. |
| `-L +5G` | add 5G |
| `-L 20G` | set the size to exactly 20G |
| `-l +100%FREE` | use all free space in the VG |

**If you forgot `-r`**: grow the filesystem afterwards. `ext4`: `resize2fs /dev/vg0/data`. `xfs`: `xfs_growfs /mount/point`.

**Grow and shrink**

| Filesystem | Grow | Shrink |
|---|---|---|
| `ext4` | online (mounted) | offline only, and risky |
| `xfs` | online | **not possible** |

**Order matters**: when growing, the LV first, then the filesystem. When shrinking (ext4 only), the filesystem first, then the LV. Shrinking in the wrong order destroys data.

**On `devlab`**: the root volume is 58G on the 119G SSD and the rest of the volume group is free. `sudo lvextend -r -L +10G /dev/<vg>/<root-lv>` would grow `/` live with no reboot. This has not been run, it only shows what it would look like.

---

## 7. Swap and memory

**`swappiness`**

- A kernel setting from 0 to 100 for how eagerly it moves memory to swap. The default is 60.
- Lower = prefers keeping things in RAM. Higher = swaps sooner.
- Servers often set it low (about 10) so RAM is used first.

| Command | Does |
|---|---|
| `cat /proc/sys/vm/swappiness` | show the current value |
| `sudo sysctl vm.swappiness=10` | change it now (lost on reboot) |
| `vm.swappiness=10` in `/etc/sysctl.d/99-swap.conf` | make it permanent |

**The OOM killer: did it kill my service?**

- If RAM and swap are both exhausted, the kernel's **OOM (out of memory) killer** picks a process and kills it with SIGKILL, usually the one using the most memory.
- SIGKILL can't be caught, so the service gets no chance to log anything. That is why it "just disappears" with no error in its own logs.

| Command | Does |
|---|---|
| `sudo dmesg \| grep -i -E "oom\|killed process"` | search the kernel log for OOM kills |
| `journalctl -k \| grep -i oom` | same, through the journal (`-k` = kernel messages) |
| `journalctl -u svc` | the service's own log. It will usually just stop with no error. |
| `systemctl status svc` | may show `Result: oom-kill` or `signal=KILL` |

- The kernel line looks like `Out of memory: Killed process 1234 (name)`.
- Fix the cause, not the symptom: a memory leak, too little RAM, or no memory limit on a container.
- Related signs: `available` near zero in `free -h`, heavy swap use.

---

## Weak spots from the quiz

- Mounting is the third step, after partition and `mkfs`.
- `sdb` is a block device, not necessarily an HDD.
- "Can't create files but `df -h` shows free space" = inodes. Run `df -i`.
- `du -x` means stay on one filesystem (skips `/proc`, other disks, NAS mounts). Biggest-first comes from `sort -rh | head`, not from `-x`.
