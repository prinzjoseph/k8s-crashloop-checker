# k8s-crashloop-checker

A small Bash script that scans Kubernetes namespaces for crash-looping pods and reports how many were found per namespace.

Built as a hands-on exercise while learning shell scripting fundamentals — loops, conditionals, functions, exit codes, script arguments, and reading Kubernetes' structured JSON output with `jq` — and turned into a small real-world tool along the way.

## What it does

- Checks one, many, or **all** namespaces in the current `kubectl` context
- Flags a pod as crash-looping if **either**:
  - its container is currently in a `CrashLoopBackOff` waiting state, **or**
  - its restart count is above a threshold (currently 100)
- Prints a per-namespace alert count so you can spot problem namespaces at a glance, without manually scrolling through `kubectl get pods` output

## Usage

Check every namespace in the cluster:
```bash
./check_crashloops.sh
```

Check specific namespaces only:
```bash
./check_crashloops.sh namespace-one namespace-two namespace-three
```

## Requirements

- `bash`
- `kubectl`, configured with a valid context pointing at the cluster you want to check
- `jq`

## Example output

```
Checking namespace: my-app
Alerts in my-app: 0
Checking namespace: payments-service
  ⚠️  ALERT: CrashLoopBackOff in pod: payments-worker-6ffb76b6cc-jwjcm
Alerts in payments-service: 1
```

## How it works

- Loops through the target namespace(s) with a `for` loop
- Uses `kubectl get pods -n <namespace> -o json` to read each pod's structured data instead of parsing the human-formatted table
- Pipes that JSON into `jq`, selecting pods where `status.containerStatuses[].state.waiting.reason == "CrashLoopBackOff"` **or** `restartCount > 100`
- Uses process substitution (`< <(...)`) instead of piping into the `while` loop, to avoid Bash's subshell variable-scoping trap — a pipe would run the loop in a subshell and silently reset the alert counter after each namespace
- Wraps the check in a function (`check_crashloops`) so it can be called once per namespace, whether that's one namespace or all of them
- Reads `$#` (argument count) to decide whether to check every namespace on the cluster or just the ones passed in on the command line

### Why two signals instead of one

`waiting.reason == "CrashLoopBackOff"` is a live snapshot — Kubernetes only reports it while a container is actively in backoff. A crash-looping container cycles between `waiting` and briefly `running` again right after each restart, so a single check can catch a real problem at exactly the wrong instant and report nothing. Restart count doesn't have that blind spot (it only ever goes up), but it also never resets once a real problem is fixed, so relying on it alone flags namespaces long after they've recovered. Combining both gives a more consistent result across repeated runs than either signal alone.

## Notes

This intentionally checks for one failure category (containers stuck restarting) rather than trying to be a general-purpose cluster health tool. The restart-count threshold (100) is currently hardcoded. Natural next steps: make the threshold configurable via a script flag, extend detection to other failure states (`ImagePullBackOff`, `Pending`, missing resource limits, etc.), or rewrite in Python/Go with structured output.
