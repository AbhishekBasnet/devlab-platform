# Week 2 Day 1: Networking basics

## Topics
1. OSI and TCP/IP models
2. IP addresses, private ranges
3. CIDR and subnetting
4. NAT
5. DHCP (DORA)
6. ARP

## Essentials
- **OSI:** L2 = MAC/switch, L3 = IP/router/ping (ICMP, no ports), L4 = TCP/UDP/ports, L7 = HTTP/DNS/SSH. TCP/IP has 4 layers: Link, Internet, Transport, Application.
- **Hops:** the MAC changes at every hop, the IP stays the same end to end.
- **Private ranges:** `10/8`, `172.16/12` (172.16 to 172.31 only), `192.168/16`. `169.254.x.x` = DHCP failed (link-local fallback). `127/8` = loopback.
- **CIDR:** usable hosts = 2^(32 - prefix) - 2. Block size = 256 - mask octet. Same subnet = talk directly, different subnet = via the gateway.
- **NAT:** the router rewrites the source to its public IP. Unsolicited inbound has no table entry and is dropped. Port forwarding adds a permanent rule.
- **DHCP:** Discover, Offer, Request, Acknowledge. Discover and Request are broadcasts. Servers need a static lease (devlab has one).
- **ARP:** IP to MAC on the local subnet only. For an off-subnet target, ARP for the gateway's MAC. `ip neigh` shows the table.

## Weak spots
- Ping is L3, no ports.
- Host bits (32 - prefix) vs number of hosts (2^bits - 2).
- `169.254.x.x` means DHCP failed, not that it worked.
- Duplicate IPs are possible (static IP inside the DHCP pool, two DHCP servers, cloned VMs). Symptom: intermittent failures.
- Off-subnet ARP goes to the gateway, not to DNS or the target.
- `ifconfig.me` shows the same IP on two machines because they share one router, not because of DNS.

## Not answered
OSI layer list, DORA order, subnet splitting (skipped: already known from the networks class).

## Commands

| Command | Flag / part | Meaning | Why you use it |
|---|---|---|---|
| `ip a` | `a` = `addr` | Show interfaces and their IPs | See your private IP, mask and whether DHCP gave one (`169.254.x.x` = DHCP failed) |
| `ip -br a` | `-br` = brief | One line per interface | Quick overview |
| `ip r` | `r` = `route` | Routing table; `default via X` is the gateway | Find the gateway; check which route a destination uses |
| `ip route get 1.1.1.1` | | Which route/gateway a packet to that IP would take | Confirms "same subnet or via gateway" |
| `ip neigh` | | ARP table (IP, MAC, state) | See who your machine has talked to; spot a changing MAC (duplicate IP) |
| `ip -br link` | `link` = L2 | Interfaces with MAC addresses | Find your own MAC |
| `curl ifconfig.me` | | Your public IP as the internet sees it | Compare with `ip a`: different = behind NAT |
| `ping -c 4 host` | `-c 4` = send 4 packets then stop | Reachability and round-trip time (ICMP, L3) | Test the gateway, then `8.8.8.8`, then a name, to find the failing layer |
| `sudo tcpdump -i any arp` | `-i any` = all interfaces | Watch ARP requests and replies live | See ARP happen |

Ping order for "no internet": gateway, then `8.8.8.8`, then a name. If the IP works and the name fails, it's DNS (Day 2).
