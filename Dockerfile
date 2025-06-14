# Builder
FROM alpine AS builder

WORKDIR /app

# Download latest release source code
RUN apk add --no-cache curl jq && \
    curl -sSL "$(curl -sSL 'https://api.github.com/repos/GVCoder09/NoDPI/releases/latest' | jq -r '.tarball_url')" -o /tmp/nodpi.tar && \
    tar --strip-components=1 -xf /tmp/nodpi.tar 

# Preparing run script
RUN echo '#!/bin/sh' > ./nodpi && \
    echo 'script_path="$(cd "$(dirname "$0")" && pwd)"' >> ./nodpi && \
    echo 'blacklist_file="$script_path/blacklist.txt"' >> ./nodpi && \
    echo 'blacklists_dir="/blacklists"' >> ./nodpi && \
    echo 'tmp_file="/tmp/blacklist.txt"' >> ./nodpi && \
    echo 'if [ -d "$blacklists_dir" ]; then' >> ./nodpi && \
    echo '  cat "$blacklists_dir"/* > "$tmp_file" 2>/dev/null' >> ./nodpi && \
    echo '  if [ -f "$tmp_file" ] && [ -s "$tmp_file" ]; then' >> ./nodpi && \
    echo '    blacklist_file="$tmp_file"' >> ./nodpi && \
    echo '  fi' >> ./nodpi && \
    echo 'fi' >> ./nodpi && \
    echo 'python3 "$script_path/src/main.py" --host 0.0.0.0 --blacklist "$blacklist_file" "$@"' >> ./nodpi
RUN chmod +x ./nodpi

# App runner
FROM python:alpine AS app

COPY --from=builder /app /app

RUN adduser -u 1000 -D -h /app -s /sbin/nologin nodpi

USER nodpi

EXPOSE 8881

ENTRYPOINT ["/app/nodpi"]

