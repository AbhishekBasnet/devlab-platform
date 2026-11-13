# Webhooks

A webhook is an HTTP POST sent to a URL when something happens: "when X happens, call this URL". The receiver does not poll.

## git push example
`git push` does not send any message. It uploads commits. After GitHub receives them, GitHub itself sends a POST if a webhook is configured (repo Settings -> Webhooks).

```
you: git push --> GitHub --(event: "push")--> POST https://your-url/hook --> your server / CI / Discord
```

## Two directions

| | Who sends | Who has the URL | Example |
|---|---|---|---|
| GitHub -> your server | GitHub, on events | **Your** server exposes a URL | push triggers a deploy |
| Your script -> Discord | **Your script** | **Discord** gives you the URL | snapshot report |

For Discord: channel settings -> Integrations -> Webhooks -> copy the URL. Anyone who POSTs JSON to it makes a message appear in that channel. There is no login: **the URL is the credential**. Keep it out of git and scripts (a `chmod 600` file, or an `EnvironmentFile=` in systemd).

## The request
```bash
curl -H 'Content-Type: application/json' \
     -d '{"content":"hello from my script"}' \
     "https://discord.com/api/webhooks/ID/TOKEN"
```
`curl --fail` makes curl exit non-zero on an HTTP error, so `set -e` notices a failed send.

## Webhook vs polling

| | Webhook (push) | Polling (pull) |
|---|---|---|
| Who starts it | the sender, the moment something happens | you, on a timer ("anything new?") |
| Cost | instant, cheap | wasteful, delayed by the interval |

## Receiving webhooks (when you are the server)
- Needs a **public HTTPS endpoint**, because GitHub must reach it. A homelab needs a reverse proxy or tunnel.
- Verify the **signature**: GitHub signs each payload with a shared secret (HMAC, `X-Hub-Signature-256` header). Without checking it, anyone could trigger your deploy.
- Reply `200` quickly and do heavy work afterwards, otherwise the sender times out and retries.

## Check questions (unanswered)
1. Why is a Discord webhook URL as sensitive as a password?
2. For "deploy when I push to GitHub", who sends the POST and who needs a public URL?
