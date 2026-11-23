#!/bin/bash
LOG="logs/surveillance.log"

arret() {
  echo "arrêt propre" >> "$LOG"
  exit 0
}
trap arret TERM

mkdir -p logs
while true; do
  echo "$(date '+%F %T') $(wc -l < logs/access.log) lignes" >> "$LOG"
  sleep 5 &
  wait $!
done
