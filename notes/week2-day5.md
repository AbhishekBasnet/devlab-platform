# Week 2 Day 5: SSH in depth and firewalls

Described but not taught step by step, and not quizzed yet. The user already did SSH hardening and `ufw` in Week 0.

## Topics
1. SSH keys
2. `~/.ssh/config`
3. `ssh-agent`
4. Tunnels
5. `scp` vs `rsync`
6. SSH hardening
7. Firewalls

## Essentials
- **Keys:** private key stays on your machine (`~/.ssh/id_ed25519`), public key goes in the server's `~/.ssh/authorized_keys`. Permissions: `~/.ssh` 700, private key 600, `authorized_keys` 600; too open and SSH refuses them.
- **`known_hosts`** stores the server fingerprint. "HOST IDENTIFICATION HAS CHANGED" = a reinstall or a possible man-in-the-middle.
- **Agent:** holds the decrypted key so you type the passphrase once. Agent forwarding (`-A`) lets a middle host use your agent while you're connected, so prefer `ProxyJump`.
- **Tunnels:** `-L` brings a remote service to your local port (Grafana in your Fedora browser); `-R` exposes your local port on the remote; `-D` is a SOCKS proxy; `-J` goes through a jump host.
- **`rsync` vs `scp`:** `rsync` copies only changes, keeps permissions, resumes. Trailing slash: `dir/` copies the contents, `dir` copies the folder.
- **Hardening:** `PasswordAuthentication no`, `PermitRootLogin no`. Check the effective value with `sshd -T`, because `sshd_config.d/` overrides can win (the Week 0 incident). Keep a second session open while testing.
- **Firewalls:** all sit on netfilter. `iptables` is the old tool, `nftables` the modern one, `ufw` (Ubuntu) and `firewalld` (Fedora) are frontends. Model: default deny incoming, allow outgoing, open only what's needed. Stateful: replies to outgoing connections are allowed back in.
- **`ufw`:** allow SSH before `enable`, otherwise you lock yourself out.
- **`firewalld`:** `--permanent` changes the saved config only, so `--reload` applies it.
- **"Permission denied (publickey)" causes:** key not installed, wrong permissions, wrong user, a `sshd_config` override.

## Commands

### SSH

| Command | Flag | Meaning | Why |
|---|---|---|---|
| `ssh-keygen -t ed25519 -C "comment"` | `-t` key type, `-C` comment | Make a key pair | Modern default key |
| `ssh-copy-id devlab` | | Append your public key to the server's `authorized_keys` | Set up key login |
| `ssh -i ~/.ssh/key user@host` | `-i` identity file | Use a specific key | Multiple keys |
| `ssh -v user@host` | `-v` (up to `-vvv`) | Show which keys are tried and where auth fails | Debug "Permission denied" |
| `ssh -p 2222 user@host` | `-p` port | Non-default port | Custom SSH port |
| `ssh -L 3000:localhost:3000 devlab` | `-L local:target:port` | Local port forward | Reach Grafana without exposing it |
| `ssh -N -f -L ...` | `-N` no shell, `-f` background | Tunnel only | Long-running tunnels |
| `ssh -R 8080:localhost:3000 server` | `-R` | Remote port forward | Expose a local app on the server |
| `ssh -D 1080 server` | `-D` | SOCKS proxy | Browse through the server |
| `ssh -J bastion target` | `-J` jump host | Go through a bastion | Private hosts (or `ProxyJump` in config) |
| `ssh-keygen -R host` | `-R` remove | Delete a host from `known_hosts` | After a legitimate reinstall |
| `sudo sshd -T \| grep -i passwordauth` | `-T` test and print effective config | See the real value | Catches override files |
| `sudo systemctl reload ssh` | | Reload config without dropping sessions | Apply `sshd_config` changes |

### Agent and copying

| Command | Flag | Meaning | Why |
|---|---|---|---|
| `eval "$(ssh-agent -s)"` | | Start the agent | Passphrase once |
| `ssh-add ~/.ssh/id_ed25519` | | Load a key | |
| `ssh-add -l` | `-l` list | Show loaded keys | Confirm the agent has your key |
| `scp -r dir devlab:/tmp/` | `-r` recursive; `-P` port (capital) | Simple copy over SSH | One-off copies |
| `rsync -avz dir/ devlab:/tmp/dir/` | `-a` archive (recursive, keeps permissions and times), `-v` verbose, `-z` compress | Copy only changes | Repeated or large copies |
| `rsync -avzn ...` | `-n` dry run | Show what would change | Check before a real run |
| `rsync -avz --delete src/ dest/` | `--delete` | Remove files missing from the source | Mirror (careful) |
| `rsync -avz --progress ...` | `--progress` | Show per-file progress | Large transfers |

### Firewalls

| Command | Meaning | Why |
|---|---|---|
| `sudo ufw status verbose` | State, default policy, rules | Ladder step 4 |
| `sudo ufw allow 22/tcp` (or `allow OpenSSH`) | Allow SSH | **Before** `ufw enable` |
| `sudo ufw allow from 192.168.2.0/24 to any port 9090` | Allow a port from one subnet only | Limit exposure |
| `sudo ufw deny 3306` | Block a port | |
| `sudo ufw delete allow 80` | Remove a rule | |
| `sudo ufw enable` | Turn it on | After allowing SSH |
| `sudo firewall-cmd --list-all` | Active zone and rules (Fedora) | Ladder step 4 on firewalld |
| `sudo firewall-cmd --add-service=http --permanent` | Allow a service permanently | |
| `sudo firewall-cmd --add-port=3000/tcp --permanent` | Allow a port permanently | |
| `sudo firewall-cmd --reload` | Apply the permanent changes | Needed after `--permanent` |
| `sudo nft list ruleset` | Show the nftables rules | See what ufw/firewalld generated |
| `sudo iptables -L -n -v` | Legacy rules (`-L` list, `-n` numeric, `-v` counters) | Older systems |

## Weak spots
Not quizzed yet.
