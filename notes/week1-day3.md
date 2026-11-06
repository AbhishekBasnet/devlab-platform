# Week 1, Day 3: Processes, signals, top/htop, tmux, background jobs

> Memorize everything below, then requiz. Each topic has: what it is, why it matters, where it's used.
> Commands in `code` are the ones to know by heart. Items under "Look up" are optional.

---

## 1. Process basics: PID, PPID, PID 1

**What**

- A process is a running instance of a program.
- **PID** = the process's unique number. **PPID** = the PID of its parent (the process that started it).
- **PID 1 = systemd** on this server. Every process descends from it.
- Your shell is a process, and every command you type is a child of the shell.
- `echo $$` = my shell's PID. `echo $PPID` = my shell's parent.
- Everything about a process lives in `/proc/<pid>/` (virtual files: cmdline, status, fd/).

**Need to know commands**

| Command | Does |
|---|---|
| `echo $$` | PID of my current shell |
| `echo $PPID` | PID of my shell's parent |
| `ps -p PID -o pid,ppid,cmd` | show one process and its parent |
| `ls /proc/PID/` | see a process's virtual files (look inside only when debugging) |

**Flags and symbols explained**

- `$$` = special shell variable holding the PID of the current shell. `$PPID` = its parent's PID.
- `-p PID` = **p**id: select the process with this PID.
- `-o pid,ppid,cmd` = **o**utput: choose which columns to print (here PID, parent PID, command).

**Why**: to find, inspect, stop or trace a process you need its PID, and the parent chain tells you who started it.

**Where used**: killing a stuck app, finding which service owns a process, debugging zombies and orphans.

---

## 2. `ps`: snapshot of processes

**Need to know commands**

| Command | Does |
|---|---|
| `ps aux` | all processes, all users (`a` all users, `u` user-format columns, `x` include no-terminal processes) |
| `ps -ef` | same list in another format, **shows PPID** |
| `ps aux \| grep nginx` | find a process by name (the grep itself shows up too) |
| `pgrep -a nginx` | find by name: prints PID and full command, no grep noise (can be long) |
| `pgrep -l nginx` | find by name: prints only PID and process name (short) |
| `ps -p PID -o pid,ppid,stat,cmd` | details of one PID |
| `ps -eo pid,user,%cpu,%mem,comm --sort=-%mem \| head` | **top memory users, clean** (one short line each) |
| `ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu \| head` | **top CPU users, clean** |
| `ps -eo pid,ppid,stat,comm \| awk '$3 ~ /Z/'` | list zombies, clean (STAT column starts with Z) |
| `ps aux --sort=-%mem \| cut -c1-120 \| head` | the `aux` version, each line cut to 120 characters so it doesn't wrap |
| `ps aux \| less -S` | scroll long lines sideways instead of wrapping (`q` quits) |

**Why the clean versions?** In `ps aux` the COMMAND column is the full command line with all arguments (Firefox has hundreds of characters), so lines wrap and the list looks unsorted and unreadable. It is sorted, it just wraps. With `-eo ... comm` you choose the columns and get only the program name.

**Flags and symbols explained**

- `aux` (no dash, old BSD style) = three letters together:
  - `a` = processes of **a**ll users
  - `u` = **u**ser-oriented format (adds USER, %CPU, %MEM columns)
  - `x` = also processes with no terminal (daemons and services)
- `-e` = **e**very process. `-f` = **f**ull format (adds PPID). So `ps -ef` = every process, full format.
- `-p PID` = select by **p**id. `-o cols` = **o**utput columns. `-eo` = `-e` and `-o` together.
- `--sort=-%mem` = sort by memory. The **`-` means descending** (biggest first). Without it, smallest first. `%cpu` sorts by CPU.
- `| head` = pipe (`|`) sends the output to `head`, which prints only the **first 10 lines**. In a table cell it's written `\|`, but in the real command it is just `|`.
- `| grep nginx` = keep only lines containing "nginx".
- `pgrep -a` = **a**ll: show the full command line, not just the PID. `pgrep -l` = **l**ist the process name with the PID.
- `-eo pid,user,%cpu,%mem,comm` = every process, with exactly these columns: PID, owner, CPU %, memory %, and `comm` = **command name only** (no arguments, cut at 15 characters). Use `args` instead of `comm` if you want the full command line.
- `cut -c1-120` = keep only characters 1 to 120 of each line (`-c` = **c**haracters).
- `less -S` = `-S` **S**hows long lines chopped instead of wrapped. Arrow keys scroll sideways.
- `awk '$3 ~ /Z/'` = print lines where column 3 (STAT in the `-eo pid,ppid,stat,comm` layout) matches (`~`) the pattern `/Z/` (contains Z). With plain `ps aux` the STAT column is column 8, so it would be `$8`.
- `--forest` = draw the parent/child tree.

Look up: `ps -eo pid,ppid,stat,cmd --forest` (tree view).

**Process states (STAT column)**

| State | Meaning |
|---|---|
| `R` | Running (or ready to run) |
| `S` | Sleeping, waiting for an event (the normal state) |
| `D` | Uninterruptible sleep, usually stuck on disk/network I/O. **Can't be killed**, even with `kill -9`, until the I/O returns |
| `T` | Stopped (paused, e.g. `Ctrl+Z`) |
| `Z` | Zombie (dead, not yet reaped by its parent) |

**Why**: `ps` is the first step in any "what is running / what is stuck" problem.

**Where used**: checking if a service is running, finding a runaway process, spotting `D` (I/O problem) and `Z` (buggy parent).

---

## 3. `top` and `htop`: live view

### Reading the `top` screen (example from my Fedora machine)

```
top - 13:03:59 up 3:15, 1 user, load average: 0.87, 0.91, 0.84
Tasks: 381 total, 1 running, 379 sleep, 0 d-sleep, 0 stopped, 1 zombie
%Cpu(s): 3.0 us, 2.6 sy, 0.0 ni, 93.7 id, 0.0 wa, 0.4 hi, 0.4 si, 0.0 st
MiB Mem : 15671.0 total, 2854.1 free, 5275.9 used, 8743.8 buff/cache
MiB Swap: 8192.0 total, 8192.0 free, 0.0 used. 10395.1 avail Mem
```

**Line 1: uptime and load average**

- `up 3:15` = time since boot. `1 user` = logged-in users.
- `load average: 0.87, 0.91, 0.84` = the 1, 5 and 15 minute averages (see section 10).

**Line 2: Tasks** (counts by state)

- total, running, sleeping, **d-sleep** (uninterruptible, I/O stuck), stopped, **zombie**.
- Here: 1 zombie exists. Harmless in small numbers, but it means some parent isn't reaping a child.

**Line 3: %Cpu(s)** (where CPU time is going; all add up to 100%)

| Field | Meaning | A high value means |
|---|---|---|
| `us` | **user**: normal programs | apps are busy (find which in the list) |
| `sy` | **system**: the kernel | lots of syscalls, I/O, networking |
| `ni` | **nice**: user processes with changed nice value | low-priority batch work is running |
| `id` | **idle** | healthy (the machine has spare capacity) |
| `wa` | **I/O wait**: CPU idle but waiting for disk/network | a **disk (or network storage) problem** |
| `hi` | **hardware interrupts** | busy devices (NIC, disk) |
| `si` | **software interrupts** | heavy network packet handling |
| `st` | **steal**: time the hypervisor took from this VM | an overloaded VM host (only matters on VMs) |

**Lines 4-5: Memory and Swap**

- `total`, `free`, `used`, `buff/cache`, and `avail Mem`.
- **Look at `avail Mem`, not `free`.** Linux uses spare RAM as cache and gives it back when apps need it. Low `free` is normal.
- Swap used heavily = the machine is short of RAM.

**Process table columns**

| Column | Meaning |
|---|---|
| `PID` / `USER` | process ID / owner |
| `PR` | kernel priority (`PR = 20 + NI` for normal processes) |
| `NI` | nice value (-20 to +19) |
| `VIRT` | virtual memory the process has mapped (often huge, not real use) |
| `RES` | **real RAM** in use |
| `SHR` | shared memory (shared libraries) |
| `S` | state (R, S, D, T, Z) |
| `%CPU` / `%MEM` | CPU and RAM share |
| `TIME+` | total CPU time used |
| `COMMAND` | the program |

**Need to know commands**

| Command | Does |
|---|---|
| `top` | live view |
| `htop` | nicer live view (`sudo apt install htop`) |
| `top -bn1 \| head -15` | **one-time snapshot** of `top`: header plus the busiest processes, easy to read, copy or save to a file |
| `top` then `M` | sort by memory |
| `top` then `P` | sort by CPU |
| `top` then `1` | per-core CPU |
| `top` then `k` | kill a PID |
| `q` | quit `top` |
| `free -h` | memory summary. Read the **available** column |
| `uptime` | load average only |

**Flags and keys explained**

- `top -bn1` = `-b` **b**atch mode (plain text, not the interactive screen), `-n1` run **n**=1 time then exit. `| head -15` keeps the first 15 lines.
- `free -h` = `-h` is **h**uman-readable (MiB/GiB instead of raw KiB). `free -m` would force MiB.
- Inside `top`, `M` = sort by **M**emory, `P` = sort by CPU (**P**ercent), `1` = toggle per-core CPU lines, `k` = **k**ill (asks for a PID, then the signal), `q` = **q**uit.
- `sudo apt install htop` = run as root (`sudo`), use the package manager (`apt`), `install` the package `htop`.

`htop` extras (look up): `F5` tree, `F3` search, `F9` kill, `F7`/`F8` nice.

**Why**: to see in real time what is eating CPU or RAM, and whether the problem is CPU, memory, or I/O.

**Where used**: "the server is slow" is always the first command. Read the header first to decide whether it's CPU (`us`/`sy`), I/O (`wa`), memory (`avail`, swap), or a VM issue (`st`).

---

## 4. Signals

A signal is a message sent to a process by the kernel or another process. The process can handle it, ignore it, or be killed by it.

| Signal | # | Meaning | Can be caught? |
|---|---|---|---|
| SIGHUP | 1 | Terminal hung up. Many daemons reload config on it | yes |
| SIGINT | 2 | `Ctrl+C`, interrupt | yes |
| SIGKILL | 9 | Kill immediately | **no** |
| SIGTERM | 15 | Polite "please stop" (**default for `kill`**) | yes |
| SIGCONT | 18 | Resume a stopped process | yes |
| SIGSTOP | 19 | Pause | **no** |
| SIGTSTP | 20 | `Ctrl+Z`, pause from terminal | yes |

Know cold: **1, 9, 15**. Look up the rest.

**SIGTERM vs SIGKILL**

- **SIGTERM (15)**: the process catches it, flushes buffers, closes files, removes lock/temp files, then exits. Clean shutdown.
- **SIGKILL (9)**: the kernel kills it directly. No cleanup, so it can leave stale locks, temp files or half-written data.
- **Rule**: `kill PID` (15) first, wait, and `kill -9 PID` only if it won't die.
- A process in `D` state ignores even `-9` until its I/O returns.

**Need to know commands**

| Command | Does |
|---|---|
| `kill PID` | send 15 (TERM), the polite stop. **Try this first** |
| `kill -9 PID` | send 9 (KILL), last resort |
| `kill -HUP PID` | send 1, many daemons reload config on it |
| `kill -l` | list all signals |
| `pgrep -l name` | **check what matches before** a name-kill |
| `pkill name` | send TERM to **every** process matching the name |
| `sudo kill PID` | needed for other users' processes |

- `kill 1234` only hits that one PID. `pkill`/`killall` hit every match (risk: killing something you didn't mean to).

**Flags explained**

- `-9` = signal **number** 9 (KILL). Same as `-KILL` or `-SIGKILL`.
- `-HUP` = signal **name** HUP (number 1). Same as `-1`.
- `-l` on `kill` = **l**ist all signal names and numbers. `-l` on `pgrep` = **l**ist the process names along with PIDs.
- No flag (`kill PID`) = sends the default, signal 15 (TERM).
- `sudo` = run as root, needed to signal a process owned by someone else.

**Why**: this is how you stop, pause, reload and force-kill processes. It's also how `systemctl stop` works underneath (TERM, then KILL after a timeout).

**Where used**: stopping a hung app, reloading nginx config (`kill -HUP` or `systemctl reload`), docker stop (TERM, then KILL after 10s).

---

## 5. Job control (foreground / background)

**Need to know commands**

| Command | Does |
|---|---|
| `cmd &` | run in the background. The shell prints `[1] 12345` (job number and PID) |
| `Ctrl+Z` | **suspend** the foreground job (SIGTSTP). Paused, not running |
| `bg` | resume the suspended job **in the background** |
| `fg` | bring a job back to the foreground. `fg %2` picks job 2 |
| `jobs` | list this shell's jobs |
| `Ctrl+C` | SIGINT (interrupt, normally ends the program) |

**Symbols explained**

- `&` at the end of a command = run it in the background.
- `%2` = job number 2 of this shell (not a PID). `%%` or `%+` = the current job.
- `Ctrl+Z` = suspend (SIGTSTP, 20). `Ctrl+C` = interrupt (SIGINT, 2).

**Typical flow**: start a long command, `Ctrl+Z`, `bg`, keep working, `fg` later.

**Note**: job numbers (`%1`) belong to one shell. PIDs are system-wide.

**Why**: free up your terminal without opening a second one.

**Where used**: a long copy or build that you forgot to put in the background, starting a quick server while you keep typing.

---

## 6. The SIGHUP problem and surviving logout

**The problem**

- A background job (`&`) is still a **child of the shell**.
- When the shell exits (you log out or **SSH drops**), the shell sends **SIGHUP** to its children, and they die.

**The fixes (need to know commands)**

| Tool | What it does |
|---|---|
| `nohup cmd > out.log 2>&1 &` | Makes the process **ignore SIGHUP** and sends output to `out.log`. Without the redirect, output goes to `nohup.out`. **Not about priority** (that is `nice`) |
| `disown` | Removes the current job from the shell's job list so it won't get a HUP. Use after `Ctrl+Z`, `bg` when you forgot `nohup`. `disown %1` picks job 1 |
| `setsid cmd` | Starts it in a new session, detached from the terminal (look up) |
| `tmux` | A session that lives on the server and survives disconnects (section 7) |
| **systemd service** | The proper way for anything permanent (Day 4) |

**Symbols explained** (for `nohup cmd > out.log 2>&1 &`)

- `>` = redirect **stdout** (normal output) into a file, overwriting it. `>>` would append.
- `out.log` = the file receiving the output.
- `2>` = redirect file descriptor 2, which is **stderr** (error output). Descriptor 1 is stdout, 0 is stdin.
- `2>&1` = send stderr to **the same place stdout is going** (so errors also land in `out.log`). The order matters: put it after `> out.log`.
- `&` at the end = run in the background.
- `disown %1` = `%1` is job number 1.

**Why**: a dropped connection must not kill a job that is halfway done.

**Where used**: long downloads, backups, `apt upgrade` over SSH. For long interactive work use `tmux`, for permanent services use systemd.

---

## 7. `tmux`: persistent terminal sessions

**Concepts**: session, which contains windows (like tabs), which contain panes (splits).

**Need to know commands**

| Command | Does |
|---|---|
| `tmux new -s name` | start a named session |
| `Ctrl+b` then `d` | **detach** (it keeps running) |
| `tmux ls` | list sessions |
| `tmux a -t name` | reattach |
| `tmux kill-session -t name` | end it |
| `exit` (inside tmux) | close the window or session you're in |

**Flags and keys explained**

- `new` = create a **new** session. `-s name` = **s**ession name.
- `a` = **a**ttach (short for `attach`). `-t name` = **t**arget session to attach to or kill.
- `ls` = **l**i**s**t sessions. `kill-session` = end a session.
- `Ctrl+b` is the **prefix key**: press it, release it, then press the next key (`d` = **d**etach).

**Look up**: `Ctrl+b c` new window, `n`/`p` next/prev, `%` vertical split, `"` horizontal split, `[` scroll mode, `,` rename window.

**Why**: the session runs on the server, so your SSH dropping doesn't matter. You reconnect and reattach.

**Where used**: **`apt upgrade` or any long job over SSH**. If apt dies halfway, the recovery is `sudo dpkg --configure -a`, then `sudo apt -f install`.

---

## 8. `nice`: process priority

**What**

- Nice value runs from **-20 (highest priority) to +19 (lowest)**. **Default is 0.**
- A "nice" process lets others go first.
- Only **root** can set negative values (raise priority). Anyone can lower their own.

**Need to know commands**

| Command | Does |
|---|---|
| `nice -n 10 cmd` | start a command at lower priority |
| `renice -n 5 -p PID` | change a running process's niceness |
| `sudo nice -n -5 cmd` | raise priority (negative needs root) |
| `ps -o pid,ni,cmd -p PID` | check a process's nice value (also the `NI` column in `top`) |

**Flags explained**

- `-n 10` = **n**iceness: the value to **add** to the default 0 (so it becomes 10). `-n -5` = subtract 5 (raise priority, root only).
- `renice -n 5 -p PID` = set niceness to 5 for the process with this **p**id.
- `ps -o pid,ni,cmd -p PID` = show PID, **ni**ce value and command for this PID.

**Don't mix up**: `nice` = priority. `nohup` = ignore SIGHUP.

**Why**: heavy jobs shouldn't starve important services of CPU.

**Where used**: backups, compression, big builds on a shared server. (More modern limiting: systemd `CPUWeight=` / cgroups, Day 4 and Docker limits.)

---

## 9. Zombie vs orphan

| | Zombie | Orphan |
|---|---|---|
| State | **Already dead** (`Z`, `<defunct>`) | Still running |
| Problem | Its parent hasn't called `wait()` to read its exit status, so the process-table entry stays | Its parent died |
| Resources | No CPU or RAM, only a PID slot | Normal |
| Fix | **You can't kill it** (it's already dead). Fix or restart the **parent**, or kill the parent so systemd adopts and reaps it | Nothing. **systemd (PID 1) adopts it**. Harmless |

- A few zombies are harmless. Thousands means a buggy parent leaking children.

**Need to know commands**

| Command | Does |
|---|---|
| `ps -eo pid,ppid,stat,comm \| awk '$3 ~ /Z/'` | find zombies, shows PID and **parent PID** in one line |
| `ps -o ppid= -p ZOMBIE_PID` | find the zombie's **parent PID** (that is who to fix) |
| `top` header, `N zombie` | quick count |
| `sudo systemctl restart service` | restart the parent service, which reaps the zombie |

**Flags explained**

- `ps -o ppid= -p PID` = `-o ppid` selects the PPID column, and the **trailing `=` removes the column header**, so only the number prints. `-p PID` selects the process.
- `awk '$3 ~ /Z/'` = see the `ps` section above.
- `systemctl restart service` = stop and start a service again (Day 4).

**Why**: it's a classic interview question, and it tells you who to blame (the parent).

**Where used**: spotting `1 zombie` in the `top` header, `ps aux | grep ' Z '`, debugging apps that spawn children.

---

## 10. Load average

**What**

- The average number of processes that are **running or waiting to run** (on Linux, also those stuck in uninterruptible I/O wait), over **1, 5 and 15 minutes**.
- Shown in `uptime`, `top`, `/proc/loadavg`.
- **Compare to `nproc`** (number of CPU cores).
  - Load below core count = healthy.
  - About equal = fully busy.
  - Well above = queueing.
- **Read the three numbers as a trend.**
  - 1 min > 15 min means load is **rising**.
  - 1 min < 15 min means load is **falling**.
  - Example: `9.5 8.2 4.1` on 4 cores = overloaded (about 2.4x) and getting worse.
- **High load but low CPU use** = processes are stuck on I/O (check `wa` and `d-sleep`).

**Need to know commands**

| Command | Does |
|---|---|
| `uptime` | load average, 1/5/15 min |
| `nproc` | number of CPU cores (compare the load to this) |
| `cat /proc/loadavg` | raw load numbers |
| `top` | header shows load, `wa`, and `d-sleep` |

**Output explained**

- `uptime` prints: current time, how long up, users logged in, then `load average: 1min, 5min, 15min`.
- `cat /proc/loadavg` prints: `1min 5min 15min running/total-processes last-PID-used`.
- `nproc` = **n**umber of **proc**essing units (cores/threads) available.

**Why**: one number that tells you whether the machine is keeping up.

**Where used**: first look when a server is slow, alerting, deciding whether to scale up.

---

## Essential commands: the one-page list for DevOps

```
ps aux | less -S            all processes (scroll sideways, q to quit)
ps -eo pid,user,%cpu,%mem,comm --sort=-%mem | head   top memory users
ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | head   top CPU users
ps -eo pid,ppid,stat,comm | awk '$3 ~ /Z/'           find zombies
pgrep -l name               find by name (short output)
top / htop                  live view (M = memory, P = CPU, q = quit)
free -h                     memory (read "available")
uptime ; nproc              load vs cores

kill PID                    polite stop (15), try first
kill -9 PID                 force kill, last resort
kill -HUP PID               reload config
pgrep -l name ; pkill name  check, then kill by name

cmd &  ;  jobs              background, list jobs
Ctrl+Z ; bg ; fg            suspend, resume in background, bring back
nohup cmd > out.log 2>&1 &  survive SSH drop
disown                      detach a running job from the shell

tmux new -s name            start session
Ctrl+b d                    detach
tmux a -t name              reattach
tmux ls                     list

nice -n 10 cmd              start at low priority
renice -n 5 -p PID          change running process
```

## Look up (not memorized)
`pkill`/`killall` flags, `ps -eo ... --forest`, `top`/`htop` shortcuts beyond M/P/1/k/q, signal numbers beyond 1/9/15, tmux split/window/scroll keys, `setsid`.

## My mistakes from the first quiz (fix these first)

- `nohup` is **not** priority. It ignores SIGHUP. `nice` is priority.
- `wa` is CPU time waiting on I/O, **not** load average.
- `Ctrl+Z` then `bg` then `fg` is the job-control flow.
- A zombie is dead-but-not-reaped, not "hung". Fix the parent.
- States: `S` sleeping, `D` stuck on I/O (unkillable), `Z` zombie.
- `kill PID` sends 15 (TERM), the polite one. Try it before `-9`.
- PID 1 is systemd.
- `pkill`/`killall` kill by **name** (every match), and send TERM, not 9, by default.
- Load trend: compare the 1, 5 and 15 min numbers. Rising if 1 min is the biggest.

## Done when
I can explain every section above without notes and type the "must know" commands from memory.
