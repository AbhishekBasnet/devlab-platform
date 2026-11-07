# Week 2 Day 2: DNS

## Topics
1. What DNS is (stub resolver, recursive resolver, authoritative server)
2. Record types
3. TTL and caching
4. The resolution chain
5. `dig` and `resolvectl`
6. Final scenario quiz (only Q2, Q3, Q8 answered)

## Essentials
- **Roles:** stub (`127.0.0.53`) asks, recursive (`1.1.1.1`) walks the chain and caches, authoritative gives the real answer.
- **Records:** A (name to IPv4), AAAA (IPv6), CNAME (name to another name), MX (mail, lower number first), TXT (verification, SPF, Let's Encrypt), NS (zone's nameservers), PTR (reverse).
- **A vs CNAME:** A for an IP you control, CNAME for a provider's name (CDN, load balancer, SaaS) whose IPs change. A CNAME can't sit at the root (NS/SOA/MX must live there); use A or ALIAS/ANAME.
- **TTL:** how long caches keep an answer. Lower it before a migration, change the IP, raise it again. "Propagation" is just caches expiring.
- **Chain:** browser cache, `/etc/hosts`, stub, recursive, root (referral to TLD), TLD (referral to NS), authoritative (answer).
- **Commands:** `dig +short name`, `dig name MX`, `dig @1.1.1.1 name`, `dig +trace name`, `dig -x ip`, `resolvectl status`, `resolvectl flush-caches`.
- **Debug:** `dig +short name` fails but `dig +short @1.1.1.1 name` works = the configured resolver is broken. `dig` right but browser wrong = local cache or `/etc/hosts`.
- **Status:** NXDOMAIN = name doesn't exist, SERVFAIL = resolver couldn't get an answer.

## Weak spots
- The DNS fix for "ping IP works, name fails" (the commands above).
- Open checks and quiz questions still unanswered: Check 1 to 5, quiz Q1, Q4, Q5, Q6, Q7.

## Commands

| Command | Flag / part | Meaning | Why you use it |
|---|---|---|---|
| `dig example.com` | | Full answer (question, answer, authority, server, query time) | See `status`, TTL and which server answered |
| `dig +short example.com` | `+short` | Answer only | Step 1 of the ladder: does the name resolve? |
| `dig example.com MX` | record type (`A`, `AAAA`, `CNAME`, `MX`, `TXT`, `NS`) | Ask for one record type | Check mail, verification TXT, nameservers |
| `dig @1.1.1.1 example.com` | `@server` | Ask a specific resolver, skipping your default | Compare with the default: differs = your resolver or cache is the problem |
| `dig +trace example.com` | `+trace` | Walk root, TLD, authoritative | Find which server holds a stale or wrong record |
| `dig +noall +answer example.com` | `+noall +answer` | Hide everything except the answer section (keeps TTL) | Clean output with the TTL counting down |
| `dig -x 203.0.113.10` | `-x` = reverse | PTR lookup, IP to name | Reverse DNS, mail server checks |
| `resolvectl status` | | DNS servers per interface (systemd-resolved) | See which resolver the machine really uses |
| `resolvectl query example.com` | | Resolve the way apps do, via the local stub | Compare with `dig`: differs = local config |
| `resolvectl flush-caches` | | Clear the local DNS cache | After a DNS change that "hasn't arrived" |
| `getent hosts example.com` | | Resolve like apps do (`/etc/hosts` first, then DNS) | Shows what an app sees; `dig` ignores `/etc/hosts` |
| `cat /etc/resolv.conf` | | Resolver config (`127.0.0.53` = systemd-resolved stub) | See where lookups go |

`dig` status values: `NOERROR` worked, `NXDOMAIN` name doesn't exist, `SERVFAIL` resolver couldn't get an answer.
