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

MQTT_HOST="localhost"
MQTT_TOPIC1="/radio/stream/title"
#MQTT_TOPIC2="/radio/stream/qr"

if [ ! -d "/mnt/mp3" ]
then
  mosquitto_pub -h $MQTT_HOST -q 0 -t $MQTT_TOPIC1 -m "music repository not available - exit" -i "identity" -u "user" -P "password"
  exit 100
else
  parec -r -d alsa_output.platform-bcm2835_audio.stereo-fallback.monitor --format=s16le --rate=44100 --volume=64880 --raw \
  | sox -t raw -r 44100 -e s -b 16 -c 2 -V1 - -r 44100 -t mp3 -C -2.2 - \
  | cvlc - --sout '#duplicate{dst=standard{access=http,mux=mp3,dst=hostname.speedport.ip:8080/audio.mp3},dst=standard{access=http,mux=mp3,dst=[::]:8082/audio.mp3}}' :ttl=12 :sout-keep \
  &

  while true
  do
    #mosquitto_pub -h localhost -q 0 -t $MQTT_TOPIC2 -m "$(qrencode -l L -v 1 -m 1 -t UTF8 'http://[fdac::ba01:dcee:eab6:37ba]:8082/audio.mp3')" -i "identity" -u "user" -P "password"
    title=$(find /mnt/mp3/ -type f \( -iname \*.mp3 -o -iname \*.ogg -o -iname \*.wav -o -iname \*.flac \) \
    | shuf  --random-source=/dev/urandom -n 1)
    echo "$(date --iso-8601=seconds) $title" >> /tmp/playlist-$(date +%F).log
    mosquitto_pub -h $MQTT_HOST -q 0 -t $MQTT_TOPIC1 -m "$(date --iso-8601=seconds) $title" -i "identity" -u "user" -P "password"
    play -q "$title" \
    vol 0.77 \
    highpass 29 \
    lowpass 19000 \
    equalizer 100 30h +0.27 \
    equalizer 275 25h +0.8 \
    equalizer 3k 28h -0.8 \
    equalizer 5k 28h +0.27 \
    equalizer 8k 28h +0.28 \
    equalizer 15k 28h +0.09 \
    compand 0.3,1 -93,-93,-73,-73,-63,-23,0,0 -13 0 0.2 \
    reverb 7 0.1 9 0.5 0.5 \
    contrast 4 \
    loudness -2 \
    gain -l 0.6
  done &
fi
