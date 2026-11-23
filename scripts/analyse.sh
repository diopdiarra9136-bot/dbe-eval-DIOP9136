#!/bin/bash
set -euo pipefail

TOP=3
FICHIER=""

usage() {
  echo "Usage : bash scripts/analyse.sh <fichier.log> [--top N]" >&2
  exit 1
}

lire_arguments() {
  [ $# -ge 1 ] || usage
  FICHIER="$1"
  shift
  if [ $# -gt 0 ]; then
    if [ $# -ne 2 ] || [ "$1" != "--top" ] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
      usage
    fi
    TOP="$2"
  fi
}

verifier() {
  if [ -z "${MATRICULE:-}" ]; then
    echo "Erreur : la variable MATRICULE n'est pas définie" >&2
    exit 1
  fi
  [ -f "$FICHIER" ] || { echo "Erreur : fichier absent : $FICHIER" >&2; exit 2; }
  [ -s "$FICHIER" ] || { echo "Erreur : fichier vide : $FICHIER" >&2; exit 3; }
}

compter_familles() {
  local c n
  for c in 2 3 4 5; do
    n=$(awk -v c="$c" 'int($9/100)==c {n++} END {print n+0}' "$FICHIER")
    echo "${c}xx : $n"
  done
}

top_endpoints() {
  awk '{sub(/\?.*/, "", $7); print $7}' "$FICHIER" | sort | uniq -c | sort -rn | awk -v n="$TOP" 'NR<=n'
}

ip_suspecte() {
  awk '$9==401 && $7=="/api/auth/login" {c[$1]++} END {for (i in c) if (c[i]>m) {m=c[i]; ip=i} print ip " (" m " échecs)"}' "$FICHIER"
}

temps_moyen() {
  awk '$9==200 {s+=$11+0; n++} END {if (n>0) printf "%.1f ms\n", s/n; else print "n/a"}' "$FICHIER"
}

main() {
  lire_arguments "$@"
  verifier
  mkdir -p rapports
  local sortie="rapports/rapport_${MATRICULE}_$(date +%Y%m%d_%H%M).txt"
  {
    echo "Rapport d'analyse - $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Utilisateur : $(whoami)@$(hostname)"
    echo "Matricule : $MATRICULE"
    echo "SHA256 : $(sha256sum "$FICHIER" | awk '{print $1}')"
    echo "--- Requêtes par famille ---"
    compter_familles
    echo "--- Top $TOP endpoints ---"
    top_endpoints
    echo "--- IP suspecte ---"
    ip_suspecte
    echo "--- Temps moyen (200) ---"
    temps_moyen
  } > "$sortie"
  cat "$sortie"
}

main "$@"
