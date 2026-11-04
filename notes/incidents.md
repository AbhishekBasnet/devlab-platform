# Incidents


### 2026-11-04 — Password SSH still enabled after editing sshd_config
- **Symptom:** Set `PasswordAuthentication no` in `/etc/ssh/sshd_config`, but `sshd -T` still showed `passwordauthentication yes`.
- **What I checked:** `sudo sshd -T | grep -iE 'passwordauth|permitroot'`, then `ls /etc/ssh/sshd_config.d/`.
- **Root cause:** `/etc/ssh/sshd_config.d/50-cloud-init.conf` sets `PasswordAuthentication yes` and is included first; sshd uses the first value it reads.
- **Fix:** Changed it to `no` in the drop-in file as well; confirmed with `sshd -T`.
- **Prevention:** Always verify the effective config with `sshd -T`, not just the file I edited. Test with a new session before closing the old one.
