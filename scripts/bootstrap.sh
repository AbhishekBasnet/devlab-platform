#!/usr/bin/env bash
# bootstrap.sh: first-boot setup for a fresh Ubuntu Server (devlab)
#
# Phase 1 (no lockout risk):   sudo bash bootstrap.sh
#   packages, ufw (SSH only), fail2ban, unattended-upgrades, lid switch ignored
#
# Phase 2 (after proving key login from your PC in a NEW terminal):
#                              sudo bash bootstrap.sh harden
#   disables SSH password login and root login (safely, with checks)
#
# Idempotent: safe to run more than once.

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo:  sudo bash $0 [harden]" >&2
  exit 1
fi

TARGET_USER="${SUDO_USER:-$(logname 2>/dev/null || echo root)}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
SSHD_DROPIN="/etc/ssh/sshd_config.d/00-hardening.conf"

say() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok()  { printf '\033[1;32m  ok:\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m  ERROR:\033[0m %s\n' "$*" >&2; exit 1; }

phase1() {
  say "1/5 Installing packages (fail2ban, unattended-upgrades, tmux)"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y fail2ban unattended-upgrades tmux ufw
  ok "packages installed"

  say "2/5 Firewall: allow SSH FIRST, then enable"
  ufw allow OpenSSH            # must come before enable, or you cut your own session
  ufw --force enable
  ufw status verbose

  say "3/5 fail2ban: enable and start (now + at boot)"
  systemctl enable --now fail2ban
  ok "fail2ban $(systemctl is-active fail2ban)"

  say "4/5 Automatic security updates"
  cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
  systemctl enable --now unattended-upgrades
  ok "unattended-upgrades $(systemctl is-active unattended-upgrades)"

  say "5/5 Laptop: do not suspend when the lid is closed"
  mkdir -p /etc/systemd/logind.conf.d
  cat > /etc/systemd/logind.conf.d/lid.conf <<'EOF'
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
EOF
  systemctl kill -s HUP systemd-logind   # reload config, does not end sessions
  ok "lid switch ignored"

  say "Phase 1 done"
  cat <<EOF

NEXT (from your PC, in a NEW terminal):
  ssh-keygen -R <server-ip>          # clear the old host key (reinstall = new host key)
  ssh $TARGET_USER@<server-ip>       # must log in WITHOUT a password

Only when that works, run on the server:
  sudo bash $0 harden
EOF
}

harden() {
  say "SSH hardening for user '$TARGET_USER'"

  local ak="$TARGET_HOME/.ssh/authorized_keys"
  [[ -s "$ak" ]] || die "$ak is missing or empty. Install your public key first (ssh-copy-id). NOT disabling passwords."
  ok "found $(grep -c '^ssh-\|^ecdsa-\|^sk-' "$ak" || true) key(s) in $ak"

  echo
  echo "Keys allowed to log in:"
  ssh-keygen -lf "$ak" || true
  echo
  read -r -p "Did you log in from your PC with the KEY (no password) in a NEW terminal? Type 'yes': " ans </dev/tty
  [[ "$ans" == "yes" ]] || die "Aborted. Prove key login first, then re-run."

  # 00- sorts before 50-cloud-init.conf. sshd uses the FIRST value it reads, so this wins.
  cat > "$SSHD_DROPIN" <<'EOF'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
EOF

  if ! sshd -t; then
    rm -f "$SSHD_DROPIN"
    die "sshd -t failed, removed $SSHD_DROPIN. Nothing changed."
  fi

  local eff
  eff="$(sshd -T | grep -iE '^(passwordauthentication|permitrootlogin) ')"
  echo "$eff"
  if grep -qi 'passwordauthentication yes' <<<"$eff" || ! grep -qi 'permitrootlogin no' <<<"$eff"; then
    rm -f "$SSHD_DROPIN"
    die "Effective config is not what we want (another file overrides it?). Reverted. Check: grep -ri passwordauth /etc/ssh/"
  fi
  ok "effective config verified"

  systemctl restart ssh
  ok "ssh restarted. YOUR CURRENT SESSION STAYS OPEN."

  cat <<EOF

NOW test from your PC in a NEW terminal, before closing this one:
  ssh $TARGET_USER@<server-ip>                                        # must work
  ssh -o PubkeyAuthentication=no $TARGET_USER@<server-ip>             # must be refused
If the first one fails, fix it from THIS session: sudo rm $SSHD_DROPIN && sudo systemctl restart ssh
EOF
}

verify() {
  say "Quick verification"
  sshd -T | grep -iE '^(passwordauthentication|permitrootlogin) ' || true
  ufw status | head -5
  echo "fail2ban:            $(systemctl is-active fail2ban)"
  echo "unattended-upgrades: $(systemctl is-active unattended-upgrades)"
  cat /etc/apt/apt.conf.d/20auto-upgrades
  ip -4 -br a
}

case "${1:-}" in
  "")     phase1; verify ;;
  harden) harden; verify ;;
  verify) verify ;;
  *)      echo "usage: sudo bash $0 [harden|verify]"; exit 1 ;;
esac
