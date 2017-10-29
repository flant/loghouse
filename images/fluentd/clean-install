#!/bin/sh

set -o errexit

if [ $# = 0 ]; then
  echo >&2 "No packages specified"
  exit 1
fi

apt-get update
apt-get install -y --no-install-recommends $@
clean-apt
