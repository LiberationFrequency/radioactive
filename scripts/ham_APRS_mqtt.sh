#!/bin/sh
# sends all the pager messages to a mosquitto (MQTT) broker.

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

MQTT_HOST="localhost"
MQTT_TOPIC1="/radio/ham/aprs/raw"
###MQTT_TOPIC2="/radio/ham/aprs/json"
PAGER_FREQ="144.8M"

rtl_fm -d RTL006 -p 27 -g 7.1 -f "$PAGER_FREQ" -M nfm -s 22050 - \
| multimon-ng -t raw -c -a AFSK1200 --timestamp /dev/stdin \
| while read LINE
do
  # Log the raw data to file, so we can debug them if needed
  #echo $LINE >> ~/rtl_433log/ham_POCSAG_mqtt-$(date "+%F").log

  mosquitto_pub -h $MQTT_HOST -q 0 -t $MQTT_TOPIC1 -m "$LINE" -i "identity" -u "user" -P "password"

  #json=$(echo $LINE | jq -c -R 'split(" ") | {date:.[0], time:.[1], demod:.[2], address:.[4], function:.[6], mode:.[7], message:.['8:']}')
  #echo $json >> ~/rtl_433log/ham_POCSAG_mqtt-$(date "+%F").json
  #mosquitto_pub -h $MQTT_HOST -q 0 -t $MQTT_TOPIC2 -m "$json" -i "identity" -u "user" -P "password"
done &
