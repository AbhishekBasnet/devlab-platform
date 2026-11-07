# Week 2 Day 3: TCP, ports and network tools

Skimmed from a description only (the user covered TCP/UDP in their degree). Not quizzed yet.

## Topics
1. TCP vs UDP
2. Handshake and teardown
3. Ports
4. `ss`
5. `nc` and `curl -v`
6. `ping`, `traceroute`, `mtr`
7. `tcpdump`

## Essentials
- **TCP:** connection, reliable, ordered (HTTP/S, SSH, databases). **UDP:** no connection, fast, no guarantees (DNS, video, games, DHCP). Both L4, ports on top of IP.
- **Handshake:** SYN, SYN-ACK, ACK. Close: FIN. RST = abrupt reset.
- **Closed port** = instant "connection refused" (RST). **Filtered/firewalled** = timeout (no answer).
- **States:** `LISTEN`, `ESTAB`, `TIME-WAIT` (normal), `SYN-SENT` (no answer yet), `CLOSE-WAIT` (the app didn't close, often a bug).
- **Ports:** 22 SSH, 25 SMTP, 53 DNS, 80 HTTP, 443 HTTPS, 3000 Grafana, 3306 MySQL, 5432 Postgres, 6379 Redis, 9090 Prometheus, 27017 MongoDB. Ephemeral client ports about 32768 to 60999.
- **Bind address:** `127.0.0.1:PORT` = local only; `0.0.0.0:PORT` = all interfaces. "Works locally, not from another machine" = check this first.
- Ping is ICMP (L3), no ports, and may be blocked, so a failed ping doesn't prove the host is down.
- `mtr` loss on a middle hop that doesn't continue to later hops = router rate-limiting ICMP. Loss that continues to the end = real.

## Commands

### `ss` (sockets; replaces `netstat`)

| Command | Flag | Meaning | Why |
|---|---|---|---|
| `ss -tulpn` | `-t` TCP, `-u` UDP, `-l` listening, `-p` process (needs `sudo` for others), `-n` numeric ports and IPs | What is listening, on which address, by which process | Ladder step 3; spot `127.0.0.1` vs `0.0.0.0` |
| `ss -tn` | `-n` numeric | Established TCP connections | See who is connected |
| `ss -tn state established` | `state X` | Filter by state | Count or inspect live connections |
| `ss -tn dst 1.2.3.4` | `dst` | Connections to one address | Check a specific peer |
| `ss -s` | `-s` summary | Socket counts per state | Spot a pile of `CLOSE-WAIT` or `TIME-WAIT` |

### `nc` (netcat)

| Command | Flag | Meaning | Why |
|---|---|---|---|
| `nc -zv host 443` | `-z` scan only, send no data; `-v` verbose | Is the port open? | Ladder step 2; faster than curl |
| `nc -zv host 20-25` | range | Scan several ports | Quick scan |
| `nc -l 9000` | `-l` listen | Open a test server on a port | Test firewall or tunnel paths |
| `nc -zvu host 53` | `-u` UDP | Test a UDP port (unreliable result) | UDP gives no handshake, so "open" is a guess |
| `nc -w 3 -zv host 22` | `-w 3` timeout in seconds | Don't hang on filtered ports | Fail fast |

### `curl`

| Command | Flag | Meaning | Why |
|---|---|---|---|
| `curl -v URL` | `-v` verbose | Shows DNS, connect, TLS and headers | Shows which stage fails |
| `curl -I URL` | `-I` HEAD request | Headers and status only | Quick health check |
| `curl -L URL` | `-L` follow redirects | Follow 301/302 | See the final page |
| `curl -s -o /dev/null -w "%{http_code}\n" URL` | `-s` silent, `-o` output file, `-w` write-out format | Print only the status code | Scripts and health checks |
| `curl --resolve host:443:IP URL` | `--resolve` | Force a name to an IP, bypassing DNS | Test a new server before changing DNS |
| `curl -k URL` | `-k` insecure | Skip certificate checks | Testing only, never production |
| `curl --connect-timeout 5 URL` | | Give up on connect after 5 s | Avoid hangs |

### `ping`, `traceroute`, `mtr`

| Command | Flag | Meaning | Why |
|---|---|---|---|
| `ping -c 4 host` | `-c` count | 4 packets, then stop | Reachability and latency |
| `traceroute -n host` | `-n` no name lookup | Each router hop (increasing TTL) | See the path; where it stops |
| `mtr -rwn host` | `-r` report mode, `-w` wide, `-n` numeric; `-c 50` for 50 cycles | Hop-by-hop loss and latency | Best tool for slow or flaky connections |

### `tcpdump`

| Command | Flag | Meaning | Why |
|---|---|---|---|
| `sudo tcpdump -i any port 80` | `-i any` all interfaces; `port` filter | Watch HTTP traffic | See the handshake from a `curl http://...` |
| `sudo tcpdump -i any -nn host 1.2.3.4` | `-nn` no name or port resolution | Traffic to or from one host | Faster, clearer output |
| `sudo tcpdump -i any -nn port 53` | | DNS queries | Debug DNS live |
| `sudo tcpdump -i any -c 20 ...` | `-c 20` stop after 20 packets | Limit the capture | Avoid flooding the terminal |
| `sudo tcpdump -i any -w out.pcap` | `-w` write file (`-r` to read) | Save for Wireshark | Analyze later |

Flags in the output: `[S]` SYN, `[S.]` SYN-ACK, `[.]` ACK, `[P.]` data, `[F.]` FIN, `[R]` RST. HTTPS bodies are encrypted; you see the handshake and sizes only.

## Weak spots
Not quizzed yet.
