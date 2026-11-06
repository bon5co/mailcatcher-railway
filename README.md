# mailcatcher-railway

[MailCatcher NG](https://github.com/spaquet/mailcatcher) for Railway, as a container image.

- MailCatcher NG 1.7.0 (the Docker Hub image `stpaquet/alpinemailcatcher` is still on 1.6.8).
- A Caddy front adds HTTP basic auth, because MailCatcher has no login of its own. The inbox is
  never served without it; only `/healthz` is open.
- SMTP listens on 1025 for the private network. Keep it off the public internet.
- Caught mail is stored in SQLite under `$DATA_DIR/.mailcatcher` (default `/data`; mount a volume there).
- One patch: MailCatcher NG 1.7.0's `process_unknown` override takes two arguments but
  EventMachine calls it with none, so any unrecognised SMTP command (a port scan, a client probing
  `VRFY`) raises `ArgumentError` and kills the whole process. The Dockerfile rewrites the signature.

Environment: `MAILCATCHER_UI_PASSWORD` (required, the basic-auth secret), `MAILCATCHER_UI_USER`
(default `admin`), `MAILCATCHER_MESSAGES_LIMIT` (default 5000), `PORT` (default 8080).

Image: `ghcr.io/bon5co/mailcatcher`. This wrapper and MailCatcher NG are both MIT licensed.
