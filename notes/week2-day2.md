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
