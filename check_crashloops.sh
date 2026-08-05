#!/bin/bash

check_crashloops() {
      ns="$1"
      count=0
      echo "Checking namespace: $ns"
      while read -r line; do
          echo "  ⚠️  ALERT: CrashLoopBackOff in pod: $line"
          count=$((count + 1))
      done < <(kubectl get pods -n $ns -o json | jq -r '.items[] | select(.status.containerStatuses[]?.state.waiting.reason == "CrashLoopBackOff" or .status.containerStatuses[]?.restartCount > 100) | .metadata.name')
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
