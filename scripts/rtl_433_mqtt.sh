#!/bin/sh

LANG=POSIX

# Script handling:
# ---------------
# Protect script (errexit -e, nounset -u, noglob -f)
# The exceptions are:
#
# If bash is used, try to be posix-compatible and set other methods.
if [ "$(ps -p $$ -o comm=)" = "bash" ]; then
  set -euf -o posix -o pipefail
else
  set -euf
fi

rtl_433 -d RTL002 \
-p 72 \
-g 40.2 \
-G 4 \
-C si \
-R -129 \
-C si \
-M level \
-M time:iso:tz \
-F "mqtt://127.0.0.1:1883,user="user",pass="password",retain=0,events=/radio/rtl_433[/id]" &

