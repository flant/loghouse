#!/bin/sh

# For systems without journald
mkdir -p /var/log/journal

/usr/local/bin/fluentd $@
