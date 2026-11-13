# Week 5 Day 1: Nginx on the host

Staging box: Debian 13 LXC `stg-web-01` (Proxmox), Nginx 1.26.3. Debian and Ubuntu share the same layout.

## Concepts in short
- Nginx = web server (serves files) + **reverse proxy** (forwards to apps). One front door on 80/443, apps stay hidden.
- **Event-driven**: a few workers handle thousands of connections. Master (root, reads config, binds ports) + workers (`www-data`, handle requests). `worker_processes auto;` = one worker per core.
- Block hierarchy: `main` > `events` | `http` > `server` > `location`. `events` is beside `http`, not inside it.
- **Directive** = one setting ending in `;`. **Block** = group in `{ }`.
- Inner blocks inherit from outer and can override. Exception: `proxy_set_header` and `add_header` do **not** merge (one in the inner block drops all outer ones).
- **`location` is a URL rule, not where files live.** Its action is either serve files (`root`) or pass to an app (`proxy_pass`).
- Server choice: match `listen` (port) first, then `server_name` against the Host header, else `default_server`. `server_name _;` is the catch-all placeholder.

## Layout
| Path | What |
|---|---|
| `/etc/nginx/nginx.conf` | Main config, includes the folders below |
| `/etc/nginx/sites-available/` | Site files. Does **nothing** by itself |
| `/etc/nginx/sites-enabled/` | **Symlinks** to `sites-available`. Only these are loaded |
| `/etc/nginx/conf.d/*.conf` | Loaded directly (Fedora uses only this) |
| `/var/www/html` | Default web root |
| `/var/log/nginx/access.log` / `error.log` | One line per request / problems and why |

Enable a site: `sudo ln -s /etc/nginx/sites-available/app.conf /etc/nginx/sites-enabled/`. Disable: remove the **link**.

## `location` matching order
| Syntax | Meaning |
|---|---|
| `= /path` | exact, wins at once |
| `/path` | prefix, **longest** wins |
| `^~ /path` | prefix that stops the search (no regex check) |
| `~` / `~*` | regex (case-sensitive / insensitive), **first in file** wins |

Order: exact, then longest prefix (remembered; stop if `^~`), then regexes in file order, then the remembered prefix.

## Daily commands
| Command | What / why |
|---|---|
| `sudo apt install nginx` | install; the package starts and enables it |
| `systemctl status nginx --no-pager` | running? master + worker PIDs |
| `curl -I http://localhost` | headers only, expect `200 OK` |
| `nginx -v` | version |
| `nginx -t` | **test** config, changes nothing |
| `nginx -T` | test + dump the full loaded config (includes expanded) |
| `sudo nginx -t && sudo systemctl reload nginx` | the safe workflow: reload only if the test passed |
| `systemctl reload nginx` | graceful, keeps connections |
| `systemctl restart nginx` | drops connections; with a broken config Nginx will not come back |
| `ps -eo pid,user,comm \| grep nginx` | master = root, workers = www-data |
| `ls -l /etc/nginx/sites-enabled/` | see the symlinks |

## Reading the config
| Command | What / why |
|---|---|
| `grep -nE 'worker_processes\|include\|listen\|root\|server_name' /etc/nginx/nginx.conf /etc/nginx/sites-enabled/default` | several keywords in one go; `-n` line numbers, `-E` allows `\|` as "or" |
| `grep -vE '^\s*(#\|$)' FILE` | hide comments and blank lines |
| `grep -n -A3 'server {' FILE` | 3 lines after each match (`-B` before) |
| `sed -n '1,20p' FILE` | print a line range |
| `nginx -T \| grep server_name` | what Nginx **actually** loaded |

## Logs
| Command | What / why |
|---|---|
| `tail -f /var/log/nginx/access.log` | watch requests live |
| `tail -n 20 /var/log/nginx/error.log` | last errors |
| `grep ' 404 ' /var/log/nginx/access.log` | all not-found requests |
| `journalctl -u nginx --since "10 min ago"` | start/stop and failed-start messages |

Access line: `IP - - [time] "METHOD /path HTTP/1.1" STATUS BYTES "referrer" "user agent"`.
Status: `502` upstream down/refused, `503` overloaded (also rate limit default), `504` upstream too slow, `499` client gave up.

## Typical errors
- `unknown directive` / `unexpected "}"`: typo or missing `;`.
- `bind() ... (98: Address already in use)`: something else owns the port.
- `open() ... (13: Permission denied)`: `www-data` cannot read the file or folder.

## Weak spots to requiz
All 15 checks are unanswered. Likely trouble: `location` matching order (`^~`, longest prefix vs first regex), `location` is a rule not a file store, why `sites-available` alone does nothing, `reload` vs `restart` with a broken config, `proxy_set_header`/`add_header` inheritance.
