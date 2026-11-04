# Day 1: New server setup (SSH hardening + firewall)

> **Use this as a checklist every time a fresh server is installed.**
> Golden rule: **never close your working session until you've proven a *new* one works.**

- **Server:** `devlab` (Ubuntu Server), `joshua@192.168.2.158`
- **Client:** Fedora PC

---

## 1. Key-based login (before touching anything else)

A key pair has two halves:

| Half | Lives on | Secret? |
|---|---|---|
| **Private key** `~/.ssh/id_ed25519` | The PC that connects (Fedora) | Yes, never share |
| **Public key** `~/.ssh/id_ed25519.pub` | The server, in `~/.ssh/authorized_keys` | No |

```bash
# On the PC (only if no key exists yet)
ssh-keygen -t ed25519

# On the PC: install the public key on the server
ssh-copy-id joshua@192.168.2.158
```

Shortcut in `~/.ssh/config` on the PC (`chmod 600` the file):

```
Host devlab
    HostName 192.168.2.158
    User joshua
    IdentityFile ~/.ssh/id_ed25519
```

**Test in a NEW terminal:** `ssh devlab` must log in **without a password**.
If it asks for one, stop. Do not continue.

> Every PC that needs access gets its **own** key pair; add each one's public key to the server.

---

## 2. Disable password + root login (without locking yourself out)

Only after step 1 is proven. Keep the original session open the whole time.

1. Edit `/etc/ssh/sshd_config`:
   ```
   PasswordAuthentication no
   PermitRootLogin no
   ```
   (Lines start with `#` by default. Uncomment them.)
2. **Check for overrides** (the trap):
   ```bash
   sudo grep -ri passwordauth /etc/ssh/sshd_config.d/
   ```
   On Ubuntu cloud images, `50-cloud-init.conf` sets `PasswordAuthentication yes` and is read **first**, so it wins. Fix it there too.
3. Validate syntax (prints nothing = OK):
   ```bash
   sudo sshd -t
   ```
4. Confirm the **effective** config, not just what you wrote:
   ```bash
   sudo sshd -T | grep -iE 'passwordauth|permitroot'
   ```
   Must show `passwordauthentication no` and `permitrootlogin no`.
5. Restart with the old session still open:
   ```bash
   sudo systemctl restart ssh
   ```
6. From a new terminal on the PC:
   ```bash
   ssh devlab                                              # must work
   ssh -o PubkeyAuthentication=no joshua@192.168.2.158     # must be refused
   ```

**Why:** bots constantly guess passwords on open SSH ports. Keys can't be guessed, and no root login removes the most targeted account.

---

## 3. Firewall (`ufw`): order matters

```bash
sudo ufw allow OpenSSH     # 1. allow SSH FIRST
sudo ufw enable            # 2. then turn it on
sudo ufw status verbose    # 3. verify
```

Expected: `Status: active`, `Default: deny (incoming), allow (outgoing)`, `22/tcp (OpenSSH) ALLOW IN`.

- **Incoming:** denied except what's explicitly allowed.
- **Outgoing:** still allowed (`apt`, `docker pull`, `git` keep working).
- Enabling before allowing SSH would cut off your own session.
- Each new service needs its own rule (e.g. `sudo ufw allow 32400/tcp` for Plex).
- ⚠️ Docker edits `iptables` directly and can bypass `ufw`. Revisit in Week 4.

---

## 4. Extras

```bash
sudo apt update && sudo apt install -y fail2ban unattended-upgrades tmux
sudo systemctl enable --now fail2ban       # start now AND at every boot
sudo dpkg-reconfigure -plow unattended-upgrades   # choose "Yes" to enable
```

Verify (never assume):

```bash
sudo systemctl status fail2ban             # active (running)
sudo fail2ban-client status sshd           # SSH jail is watching
systemctl status unattended-upgrades       # active
cat /etc/apt/apt.conf.d/20auto-upgrades    # both lines should be "1"
```

> Typo trap: `sudo apt install ...`, not `sudo install ...` (`install` is a different program that copies files).

- `fail2ban`: bans IPs with repeated failed logins. **Why:** stops brute-force bots from hammering SSH (defense in depth, even with passwords off).
- `unattended-upgrades`: installs security patches automatically. **Why:** unpatched software is a top way servers get compromised, and this means I can't forget.
- `tmux`: long tasks survive a dropped SSH connection.
- Reserve the server's IP in the router (static lease) so `ssh devlab` never breaks.

---

## Lockout-prevention rules (summary)

1. Prove key login works in a **new** terminal **before** disabling passwords.
2. Check `sshd_config.d/*.conf` overrides.
3. `sshd -t` before every restart.
4. Keep the old session open until the new one is verified.
5. `ufw allow OpenSSH` **before** `ufw enable`.

## Done when

- [x] Key login works via `ssh devlab`
- [x] Password + root SSH login verified off
- [x] `ufw` active with only SSH allowed
- [ ] `fail2ban`, `unattended-upgrades`, `tmux` installed
- [ ] Static DHCP lease set, IP survives a reboot
