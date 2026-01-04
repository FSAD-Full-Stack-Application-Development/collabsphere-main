#!/bin/bash
set -e

# Remove stale server PID
rm -f /app/tmp/pids/server.pid

echo "Preparing database..."
./bin/rails db:prepare

# Execute CMD
exec "$@"
