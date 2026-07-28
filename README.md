# k8s-crashloop-checker

A small Bash script that scans Kubernetes namespaces for pods stuck in `CrashLoopBackOff` and reports how many were found per namespace.

Built as a hands-on exercise while learning shell scripting fundamentals — loops, conditionals, functions, exit codes, and script arguments — and turned into a small real-world tool along the way.

## What it does

- Checks one, many, or **all** namespaces in the current `kubectl` context
- Flags any pod whose status line contains `CrashLoopBackOff`
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

## Example output

```
Checking namespace: my-app
Alerts in my-app: 0
Checking namespace: payments-service
  ⚠️  ALERT: payments-worker-6ffb76b6cc-jwjcm   0/1   CrashLoopBackOff   12 (3m ago)   1d
Alerts in payments-service: 1
```

## How it works

- Loops through the target namespace(s) with a `for` loop
- Uses `kubectl get pods -n <namespace> --no-headers` and reads the output line by line with `while read`
- Uses process substitution (`< <(...)`) instead of piping into the `while` loop, to avoid Bash's subshell variable-scoping trap — a pipe would run the loop in a subshell and silently reset the alert counter after each namespace
- Uses `grep -q` to detect `CrashLoopBackOff` in each line without printing anything itself
- Wraps the check in a function (`check_crashloops`) so it can be called once per namespace, whether that's one namespace or all of them
- Reads `$#` (argument count) to decide whether to check every namespace on the cluster or just the ones passed in on the command line

## Notes

This intentionally checks for one specific failure signature (`CrashLoopBackOff`) rather than trying to be a general-purpose cluster health tool. A natural next step would be extending it to catch other failure states (`ImagePullBackOff`, `Pending`, missing resource limits, etc.) or rewriting it in Python/Go with structured (JSON) output.
