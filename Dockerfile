# Builder
FROM alpine AS builder

WORKDIR /app

# Download latest release source code
RUN apk add --no-cache curl jq && \
    curl -sSL "$(curl -sSL 'https://api.github.com/repos/GVCoder09/NoDPI/releases/latest' | jq -r '.tarball_url')" -o /tmp/nodpi.tar && \
    tar --strip-components=1 -xf /tmp/nodpi.tar 

# Preparing run script
RUN cat << 'EOF' > ./nodpi
#!/bin/sh

# Get the absolute path of the script
script_path="$(cd "$(dirname "$0")" && pwd)"

# Default blacklists file
blacklist_file="$script_path/blacklist.txt"

# Optional directory containing additional blacklists
blacklists_dir="/blacklists"

# Temporary file for the combined blacklist
tmp_file="/tmp/blacklist.txt"

# Check if the directory with blacklists exists
if [ -d "$blacklists_dir" ]; then
   # Concatenate all blacklist files from the directory into the temporary file
   cat "$blacklists_dir"/* > "$tmp_file" 2>/dev/null

   # If the temporary file exists and is not empty, use it as the blacklist
   if [ -f "$tmp_file" ] && [ -s "$tmp_file" ]; then
       blacklist_file="$tmp_file"
   fi
fi

# Run the main Python script with the specified blacklist file and pass all arguments
python3 "$script_path/src/main.py" --host 0.0.0.0 --blacklist "$blacklist_file" "$@"

EOF

RUN chmod +x ./nodpi

# App runner
FROM python:alpine AS app

COPY --from=builder /app /app

RUN adduser -u 1000 -D -h /app -s /sbin/nologin nodpi

USER nodpi

EXPOSE 8881

ENTRYPOINT ["/app/nodpi"]

