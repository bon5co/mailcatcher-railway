# MailCatcher NG for Railway: the current gem (the Docker Hub image is stuck on 1.6.8) behind a
# Caddy basic-auth front, because MailCatcher has no login of its own and a public inbox would
# hand every caught message to anyone with the URL. SMTP stays on the private network.
FROM ruby:3.4-slim@sha256:3e76621a6e7771cacf9fff99c0399baae41fc56fe58547bc846ff72c6a27c527 AS build
ARG MAILCATCHER_VERSION=1.7.0
RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential libsqlite3-dev libssl-dev pkg-config \
 && rm -rf /var/lib/apt/lists/* \
 && gem install --no-document mailcatcher-ng -v ${MAILCATCHER_VERSION} \
 && SMTP_RB="$(gem contents mailcatcher-ng -v ${MAILCATCHER_VERSION} | grep lib/mail_catcher/smtp.rb)" \
 && sed -i 's/def process_unknown(command, data)/def process_unknown(*)/; s/"#{command} #{data}".strip/"[unrecognised command]"/' "$SMTP_RB" \
 && grep -q "def process_unknown(\*)" "$SMTP_RB"

FROM ruby:3.4-slim@sha256:3e76621a6e7771cacf9fff99c0399baae41fc56fe58547bc846ff72c6a27c527
LABEL org.opencontainers.image.source="https://github.com/bon5co/mailcatcher-railway"
LABEL org.opencontainers.image.description="MailCatcher NG with a Caddy basic-auth front and Railway defaults"
RUN apt-get update \
 && apt-get install -y --no-install-recommends libsqlite3-0 libssl3 ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=caddy:2.10-alpine@sha256:4c6e91c6ed0e2fa03efd5b44747b625fec79bc9cd06ac5235a779726618e530d /usr/bin/caddy /usr/local/bin/caddy
COPY entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod +x /usr/local/bin/railway-entrypoint.sh
EXPOSE 8080 1025
ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
