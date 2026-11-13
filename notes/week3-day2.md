# Week 3 Day 2: Text tools

Taught in order, with a check after each topic. Topics so far: 1 `grep` and pipes, 2 `cut`/`sort`/`uniq`/`wc`, 3 `awk`, 4 `sed`, 5 `find`, 6 `xargs`. All six taught; the check questions below are still unanswered.

## Essentials
- A pipe (`|`) sends one command's output into the next command's input. Every tool here is a small filter chained this way.
- `uniq` only collapses **adjacent** duplicates, so run `sort` before it: `sort | uniq -c`.
- `sort -n` is numeric. Without it `10` sorts before `9`.
- The ranking pattern: `cut/awk` (pick a column) -> `sort` -> `uniq -c` -> `sort -rn` -> `head`.

## What the names stand for

| Command | Stands for |
|---|---|
| `grep` | **g**lobal / **r**egular **e**xpression / **p**rint, from the old `ed` editor command `g/re/p` |
| `awk` | **A**ho, **W**einberger, **K**ernighan, the surnames of its three creators (1977) |
| `sed` | **s**tream **ed**itor |
| `find` | just "find" (finds files) |
| `xargs` | e**x**tended **args** (builds **arg**ument lists from input) |
| `cut` | just "cut" (cuts columns out of lines) |
| `sort` | just "sort" |
| `uniq` | **uniq**ue (shows unique lines) |
| `wc` | **w**ord **c**ount (`-l` counts lines, `-w` words, `-c` bytes) |
| `head` / `tail` | the head (start) and tail (end) of a file |

## 1. `grep` and pipes

| Command | Meaning |
|---|---|
| `grep "text" file` | print lines containing `text` |
| `grep -i` | ignore case |
| `grep -v` | invert: lines that do **not** match |
| `grep -r "text" dir/` | search every file under a directory |
| `grep -n` | show line numbers |
| `grep -c` | count matching lines |
| `grep -E "a\|b"` | extended regex (`\|` means "or") |

Example: `journalctl -u ssh | grep -i "failed"` shows only the failed-login lines.

## 2. `cut`, `sort`, `uniq`, `wc`

| Command | Flag | Meaning |
|---|---|---|
| `cut -d' ' -f1` | `-d` delimiter, `-f` field number | take the first space-separated column |
| `cut -d: -f1,3` | `-f1,3` | take fields 1 and 3 (`/etc/passwd` usernames and UIDs) |
| `sort` | | sort lines alphabetically |
| `sort -n` | | sort numerically |
| `sort -r` | | reverse order |
| `sort -u` | | sort and drop duplicates |
| `uniq` | | collapse **adjacent** duplicate lines |
| `uniq -c` | | prefix each line with its count |
| `wc -l` | | count lines (`-w` words, `-c` bytes) |
| `head -n 10` / `tail -n 10` | | first or last 10 lines |

The ranking pattern, step by step:
```bash
cut -d' ' -f1 access.log | sort | uniq -c | sort -rn | head
```
1. `cut` pulls out the first column (the IP address).
2. `sort` puts identical IPs next to each other.
3. `uniq -c` counts each group.
4. `sort -rn` ranks the counts, highest first.
5. `head` keeps the top 10.

## 3. `awk`

`awk` reads input line by line, splits each line into fields on whitespace, and runs a small program on it. Use it when `cut` is not enough (several spaces between columns, conditions, sums).

| Item | Meaning |
|---|---|
| `awk '{print $1}'` | print the first field of every line |
| `$0` | the whole line |
| `$1`, `$2`, ... | field 1, field 2, ... |
| `$NF` | the last field |
| `NF` | number of fields in the line |
| `NR` | current line number |
| `-F:` | set the field separator (here `:`), like `cut -d` |
| `awk '$9 == 404'` | print lines where field 9 equals 404 (condition before the braces) |
| `awk '$3 > 100 {print $1}'` | print field 1 only for lines where field 3 is above 100 |
| `awk '{s+=$1} END {print s}'` | sum the first column; `END` runs once after the last line |
| `BEGIN {...}` | runs once before the first line |

Roadmap one-liners:
```bash
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head      # top 10 IPs
awk '{print $9}' access.log | sort | uniq -c | sort -rn             # count HTTP status codes
```
Why `cut` fails where `awk` works: `cut -d' '` treats every single space as a separator, so a column padded with several spaces gives empty fields. `awk` treats any run of whitespace as one separator.

## 4. `sed`

`sed` (**s**tream **ed**itor) edits text as it flows through. It reads input line by line, applies an edit, and prints the result. Without `-i` the file is never changed, only the output.

| Command | Meaning |
|---|---|
| `sed 's/old/new/' file` | replace the **first** `old` on each line |
| `sed 's/old/new/g' file` | `g` = replace **every** `old` on each line |
| `sed -i 's/old/new/g' file` | `-i` = edit the file **in place** (no undo) |
| `sed -i.bak 's/old/new/g' file` | in place, but keep the original as `file.bak` |
| `sed -n '5,10p' file` | `-n` = print only what is asked: lines 5 to 10 |
| `sed '5d' file` | delete line 5 from the output |
| `sed '/DEBUG/d' file` | delete every line matching `DEBUG` |
| `sed -E 's/[0-9]+/N/g'` | `-E` = extended regex |
| `sed 's\|/usr/bin\|/bin\|' file` | any character can be the delimiter, handy for paths |

Safe habit: run without `-i` first and read the output, then add `-i` (or `-i.bak`). `sed -i` rewrites the file at once and there is no undo.

Example: `sed -i.bak 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config` (`^` anchors to the start of the line).

## 5. `find`

`find` walks a directory tree and lists files that match your conditions. `grep` searches *inside* files, `find` searches for the *files themselves* (by name, age, size, type, owner). It is the main tool for log cleanup and backup rotation (Day 3 and Day 4 scripts).

Shape: `find WHERE CONDITIONS ACTION`. Conditions are joined with AND by default.

| Item | Meaning |
|---|---|
| `find /var/log -name "*.log"` | match by name (quote the pattern so the shell does not expand it) |
| `-iname` | same as `-name` but ignores case |
| `-type f` / `-type d` | only files / only directories |
| `-mtime +7` | modified **more than** 7 days ago (`-mtime -1` = within the last day) |
| `-mmin -30` | modified within the last 30 minutes |
| `-size +100M` | bigger than 100 MB (`k`, `M`, `G`) |
| `-user name` / `-perm 777` | owned by a user / has exact permissions |
| `-maxdepth 1` | do not go deeper than 1 level (put it before other tests) |
| `! -name "*.gz"` | NOT; `-o` is OR |
| `-print` | print the matches (the default action) |
| `-delete` | delete the matches |
| `-exec cmd {} \;` | run `cmd` once per match, `{}` is the file |
| `-exec cmd {} +` | run `cmd` once with many files (faster) |

Examples:
```bash
find /backups -name "*.tar.gz" -mtime +7                 # preview old backups
find /backups -name "*.tar.gz" -mtime +7 -delete         # delete them
find /var/log -type f -size +100M                        # find big logs
find . -name "*.conf" -exec grep -l "port" {} +          # which .conf files mention "port"
```
Gotchas:
- **Preview before deleting:** run with `-print` (or no action) first, then replace it with `-delete`. `-delete` has no undo, and the order of arguments matters.
- Quote `"*.log"`, otherwise the shell expands it before `find` sees it.
- `-type f` stops `-delete` from matching directories.
- `find` descends into subfolders by default, so use `-maxdepth 1` if you only want one level.

## 6. `xargs`

`xargs` turns lines from a pipe into **arguments** for another command. A pipe sends text to a command's *input* (stdin), but commands like `rm`, `cp` and `mv` read their *arguments*, not stdin. `echo file.txt | rm` does nothing; `echo file.txt | xargs rm` works.

| Item | Meaning |
|---|---|
| `... \| xargs cmd` | run `cmd` with the piped lines as arguments |
| `-n 1` | pass one argument per command run |
| `-I {}` | name a placeholder: `xargs -I {} cp {} /backup/` |
| `-P 4` | run up to 4 commands in parallel |
| `-0` | input is separated by null characters (pair with `find -print0`) |
| `-r` | do not run the command if the input is empty (GNU) |
| `-t` | print each command before running it (good for checking) |

Examples:
```bash
find /tmp -name "*.tmp" -print0 | xargs -0 rm            # delete safely, even with spaces in names
find . -name "*.log" -print0 | xargs -0 grep -l ERROR    # which logs contain ERROR
cat hosts.txt | xargs -I {} ping -c1 {}                  # ping every host in a list
```
Gotchas:
- **Spaces in filenames:** `xargs` splits on whitespace, so `my file.txt` becomes two arguments. Use `find -print0 | xargs -0` to be safe.
- **`xargs` vs `find -exec {} +`:** they do almost the same job. `-exec` is simpler after `find`; `xargs` works after any command (`grep -l`, `cat list.txt`) and can run in parallel with `-P`.
- Preview with `-t` or `echo` before anything destructive: `... | xargs -t echo rm`.

## Check questions (unanswered)
- Topic 1: what does `grep -v "DEBUG" app.log` print? How do you count the lines containing `ERROR`? What does `cat app.log | grep ERROR | wc -l` do, and what is a shorter way?
- Topic 2: why does `sort | uniq -c` need the `sort` first? Why `sort -rn` for a list of counts, and what goes wrong without `-n`? What does `cut -d: -f1 /etc/passwd` print?
- Topic 3: what does `awk '{print $NF}' file` print? How do you print only the lines of `access.log` where field 9 is `500`? What does `awk -F: '{print $1}' /etc/passwd` do, and which `cut` command is the same?
- Topic 4: difference between `sed 's/a/b/'` and `sed 's/a/b/g'`? `sed 's/yes/no/' config.conf` leaves the file unchanged: why, and what would change it? How do you print only line 20?
- Topic 5: difference between `grep` and `find`? What does `find /var/log -type f -mtime +30` list? Why run a `find ... -delete` command without `-delete` first?
- Topic 6: see below.
