#!/bin/sh

# Abort on any error (including if wait-for-it fails).
set -e

# Wait for the backend to be up, if we know where it is.
if [ -n "mongodb" ]; then
  /usr/src/app/wait-for-it.sh "mongodb:27017"
fi

# Run the main container command.
exec "$@"