#!/bin/bash

check_crashloops() {
      ns="$1"
      count=0
      echo "Checking namespace: $ns"
      while read -r line; do
        if echo "$line" | grep -q "CrashLoopBackOff"; then
          echo "  ⚠️  ALERT: $line"
          count=$((count + 1))
        fi
      done < <(kubectl get pods -n "$ns" --no-headers)
      echo "Alerts in $ns: $count"
    }


if [ $# -eq 0 ]; then
  names=$(kubectl get ns --no-headers | awk '{ print $1 }')
  for ns in $names; do
      check_crashloops "$ns"
    done
else
  for ns in $@; do
      check_crashloops "$ns"
    done
fi
