# Week 2 Day 4: HTTP, HTTPS and TLS

Skimmed from a description only (the user covered HTTP/TLS in their degree). Not quizzed yet.

## Topics
1. HTTP basics
2. Status codes
3. HTTPS and the TLS handshake
4. Certificates
5. Tools
6. "What happens when you type a URL?"

## Essentials
- **HTTP:** L7, text, request/response, stateless (cookies add state). Methods: GET read, POST create, PUT replace, PATCH partial update, DELETE remove, HEAD headers only. Headers: `Host`, `Content-Type`, `Authorization`, `Cookie`/`Set-Cookie`, `Location` (redirect), `Cache-Control`.
- **Versions:** 1.1 keep-alive, 2 multiplexing over one connection, 3 over QUIC (UDP).
- **Status codes:** 2xx success, 3xx redirect, 4xx client error, 5xx server error.
  - 200 OK, 201 Created, 301 permanent redirect, 302 temporary redirect, 304 use your cache.
  - 400 bad request, **401 not authenticated (who are you?)**, **403 authenticated but not allowed**, 404 not found, 429 rate limited.
  - 500 app error, **502 proxy got a bad answer from the backend**, 503 overloaded or maintenance, **504 proxy waited too long for the backend**.
  - 4xx = look at the request; 5xx = look at the server or backend.
- **TLS 1.3 flow** (after TCP): Client Hello (ciphers, SNI), Server Hello with certificate and key share, client verifies the chain, keys agreed, encrypted data. Asymmetric crypto authenticates and agrees on a key; symmetric crypto encrypts the traffic. SNI lets one IP serve many HTTPS sites.
- **Certificate holds:** domain (CN/SAN), issuer, validity dates, public key, signature. **Chain:** server cert, intermediate CA, trusted root.
- **Let's Encrypt:** free, 90 days, auto-renewed (HTTP challenge on port 80, or DNS challenge with a TXT record).
- **Certificate failures:** expired (renewal failed), name mismatch, untrusted issuer or missing intermediate (self-signed), wrong system clock.
- **Type a URL:** parse and cache, DNS, route via the gateway (ARP, NAT), TCP handshake, TLS handshake, HTTP request, load balancer or proxy to the app (and database), response, browser renders and fetches more resources.

## Commands

| Command | Flag | Meaning | Why |
|---|---|---|---|
| `curl -v https://host` | `-v` verbose | Shows DNS, TCP, TLS (certificate info) and headers | See which stage fails |
| `curl -I https://host` | `-I` HEAD | Status and response headers only | Quick health check |
| `curl -i URL` | `-i` include headers | Headers plus body | See headers with the content |
| `curl -L URL` | `-L` follow redirects | Follow 301/302 | See the final destination |
| `curl -X POST -H "Content-Type: application/json" -d '{"a":1}' URL` | `-X` method, `-H` header, `-d` body | Send a custom request | Test an API |
| `curl -k URL` | `-k` insecure | Skip certificate verification | Testing only |
| `curl -s -o /dev/null -w "%{http_code}\n" URL` | `-s`, `-o`, `-w` | Status code only | Scripts and monitoring |
| `openssl s_client -connect host:443 -servername host` | `-connect host:port`; `-servername` sends SNI | Raw TLS handshake and chain | Debug certificate or chain problems; without `-servername` a shared IP may return the wrong certificate |
| `echo \| openssl s_client -connect host:443 -servername host 2>/dev/null \| openssl x509 -noout -dates -subject -issuer` | `-noout` hide the PEM; `-dates`, `-subject`, `-issuer` | Print validity dates, domain and issuer | Check the expiry date |
| `openssl x509 -in cert.pem -noout -enddate` | `-enddate` | Expiry of a local certificate | Check a file |
| `openssl x509 -in cert.pem -noout -checkend 604800` | `-checkend N` seconds | Exit status 1 if it expires within N seconds (7 days here) | Expiry alerts in scripts |
| `sudo certbot certificates` | | List Let's Encrypt certificates and expiry | See what is installed |
| `sudo certbot renew --dry-run` | `--dry-run` | Test renewal without changing anything | Confirm auto-renewal works |

## Weak spots
Not quizzed yet.
