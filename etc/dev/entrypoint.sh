#!/bin/bash

set -e

composer --version
php -v

(
  flock -w 30 200 || exit 0
  if [ ! -d "vendor" ]; then
      composer install
  fi
) 200>/var/lock/vendor.lock

(
  flock -w 30 201 || exit 0
  if [ ! -d "node_modules" ]; then
      pnpm install
  fi
) 201>/var/lock/node.lock

exec "$@"
