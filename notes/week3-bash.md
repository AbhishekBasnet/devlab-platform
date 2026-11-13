# Week 3: Bash notes

D1 (variables, quoting, loops, functions) is skipped for now: the user works in zsh and gets scripts written by AI. The rule instead is **read and review every script before running it**. Scripts that run unattended (cron, systemd timers) often run as root and delete things, so a bug here is expensive.

## Bash gotchas for reviewing scripts

### 1. Quoting
```bash
file="my backup.tar.gz"
rm $file      # bash splits this into two args: "my" and "backup.tar.gz"
rm "$file"    # one argument, correct
```
- Unquoted variables get split on spaces, and `*` inside them gets expanded.
- **Rule: every `$var` is in double quotes.** A bare `$var` is a red flag.
- `"$@"` keeps each argument separate. `$*` glues them together.

### 2. The empty variable
```bash
rm -rf "$BACKUP_DIR/"*    # if BACKUP_DIR is empty, this becomes: rm -rf /*
```
Two defences:
- `set -u` fails the script on an unset variable.
- `"${BACKUP_DIR:?not set}"` aborts with a message if the variable is empty or unset.

### 3. `set -euo pipefail` (second line of every script)

| Flag | Effect |
|---|---|
| `-e` | exit on the first command that fails |
| `-u` | error on an unset variable |
| `-o pipefail` | a pipeline fails if **any** part fails, not just the last |

Without `pipefail`, `mysqldump db | gzip > backup.gz` reports success even if `mysqldump` failed, so you get an empty backup that looks fine.

### 4. Exit codes
- `0` is success. Anything else is failure.
- `$?` holds the last command's exit code.
- `exit 1` makes the script report failure. Cron and systemd use this to know a job broke.
- `grep` returns 1 when it finds **no match**. Under `set -e` that can kill the script, so `grep ... || true` is the usual fix.

### 5. `[[ ]]` vs `[ ]`
Use `[[ ]]` in bash. It is safer with empty variables and spaces, and it supports `&&`, `||` and pattern matching. `[ ]` is the old POSIX form and breaks more easily.
```bash
if [[ -f "$file" ]]; then ...   # -f file exists, -d directory, -z string empty
```

### 6. `cd` can fail silently
```bash
cd /backups && rm -f *.old    # safe: rm runs only if cd succeeded
cd /backups; rm -f *.old      # if cd fails, rm runs in the current directory
```

### 7. Review habits for destructive commands
- `rm`, `mv` and `find ... -delete` should use absolute paths and quoted variables.
- Run the `find ... -delete` selector with `-print` first.
- Test with `echo rm ...` before the real run.
- Use `trap 'cleanup' EXIT` for temp files and lock cleanup.

### 8. Zsh vs bash

| | bash | zsh |
|---|---|---|
| unquoted `$var` with spaces | splits into words | does **not** split |
| array first index | `${arr[0]}` | `${arr[1]}` |

- Scripts start with `#!/usr/bin/env bash`, so they run in bash whatever the terminal is.
- Test with `bash script.sh`, not by pasting into the zsh prompt. Otherwise a bug can hide locally and show up on the server.

## Check questions (unanswered)
1. Why is `rm -rf $DIR/*` more dangerous than `rm -rf "$DIR"/*`, and what does `set -u` add on top?
2. A backup script runs `tar czf out.tgz /data | tee log.txt` without `pipefail`. If `tar` fails, what does the script report?
