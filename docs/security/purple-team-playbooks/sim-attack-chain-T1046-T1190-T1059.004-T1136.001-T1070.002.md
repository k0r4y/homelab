# Purple Team Simulation: Attack Chain — Forgotten Service
## T1046 → T1190 → T1059.004 → T1136.001 → T1070.002

## Overview

| Field | Value |
|---|---|
| Scenario Name | Forgotten Service |
| MITRE Tactics | Discovery, Initial Access, Execution, Persistence, Defense Evasion |
| Attacker | kali01 — 10.10.10.20 |
| Target | target01 — 10.10.10.30 (DVWA, Apache, vsftpd) |
| Gateway | fw01 — 10.10.10.1 |
| SIEM | Wazuh on node03 — 192.168.178.28 |
| Date | 2026-06-23 |
| Result | Partial — reverse shell achieved, privilege escalation blocked |

---

## Scenario Description

A web application (DVWA) is running on an internal server in an isolated network zone. The application was deployed for testing and never hardened — default credentials were never changed, the security level was left at `impossible` in the PHP session default, and no firewall rules restrict web access from within the attack zone.

An attacker who has gained a foothold in the attack zone discovers the service via network scanning, logs in with default credentials, and exploits a command injection vulnerability to establish a reverse shell. However, privilege escalation fails — no credential reuse is possible and no misconfigured sudo rules exist — blocking the persistence and defense evasion stages.

This scenario demonstrates both a successful initial access and execution chain, and the value of hardened user permissions as a defensive control.

---

## Attack Chain Overview

    T1046     Network scan — discover target01 and open services      <- Executed
         |
         v
    T1190     Exploit DVWA with default credentials (admin/password)  <- Executed
         |
         v
    T1059.004 Python reverse shell via command injection              <- Executed / Partial Detection
         |
         v
    T1136.001 Create backdoor local account                          <- BLOCKED (no privesc path)
         |
         v
    T1070.002 Clear logs to cover tracks                             <- NOT ATTEMPTED

---

## Prerequisites

- kali01 running on the attack zone (10.10.10.20)
- target01 running with DVWA installed and Apache running (10.10.10.30)
- DVWA security level set to low via Apache environment variable
- Wazuh agent active on target01
- auditd running on target01

---

## Stage 1 — T1046: Network Scan

### What This Technique Is

Network scanning is how an attacker maps the environment after gaining initial access to a network segment. By sending probes to a range of IP addresses and ports, the attacker discovers which hosts are alive and what services they expose.

### Attack

    sudo nmap -sV -sC 10.10.10.0/24

### Findings

Three hosts discovered:

| Host | Ports | Services |
|---|---|---|
| 10.10.10.1 (fw01) | 22 | OpenSSH 9.6p1 |
| 10.10.10.20 (kali01) | 22 | OpenSSH 10.3p1 |
| 10.10.10.30 (target01) | 21, 22, 80 | vsftpd 3.0.5, OpenSSH 9.6p1, Apache 2.4.58 |

Notable observation: fw01 and target01 share identical SSH host keys — both built from the same golden image. This is an anomaly that would stand out to an analyst reviewing SSH fingerprints.

Followed up with HTTP enumeration:

    sudo nmap -sV -p 80 --script http-enum 10.10.10.30

Apache default page confirmed. DVWA discovered by manual browsing to /dvwa/.

### Detection

Not detected. Wazuh is host-based and cannot see network traffic. No network sensor is deployed on fw01. This is a documented detection gap — Suricata deployment on fw01 is planned for Phase 7.

---

## Stage 2 — T1190: Exploit Public-Facing Application

### What This Technique Is

DVWA ships with default credentials (admin / password) that are publicly documented. An attacker discovering a DVWA login page will always try these before anything else. The application was deployed for testing and the credentials were never changed.

### Attack

    http://10.10.10.30/dvwa/login.php
    Username: admin
    Password: password

Login successful — redirected to index.php.

Security level confirmed as low (set via Apache environment variable DEFAULT_SECURITY_LEVEL=low).

### Detection

Not detected. Apache access logs record the HTTP POST to /dvwa/login.php but Wazuh is not configured to ingest Apache logs on target01. This is a documented detection gap — adding Apache log monitoring to the Wazuh agent configuration would detect this.

---

## Stage 3 — T1059.004: Python Reverse Shell via Command Injection

### What This Technique Is

DVWA's Command Execution module passes user input directly to a system shell without sanitisation. At security level low there is no filtering. Appending a shell command after ; causes it to execute on the server as www-data.

A standard bash reverse shell (bash -i >& /dev/tcp/...) failed — PHP's process execution context prevented the shell from staying open. A Python reverse shell using socket redirection was used instead, which is more reliable from a web execution context.

### How the Injection Works

The DVWA ping command executes:

    ping -c 4 [USER_INPUT]

Injecting ;python3 -c '...' after a valid IP causes the server to run both the ping and the Python reverse shell.

### Attack

Step 1 — Set up listener on kali01:

    nc -lvnp 4444

Step 2 — Login to DVWA and get CSRF token, then execute Python reverse shell via command injection targeting 10.10.10.20:4444.

Step 3 — Upgrade shell:

    python3 -c 'import pty; pty.spawn("/bin/bash")'

Shell confirmed:

    uid=33(www-data) gid=33(www-data) groups=33(www-data)
    hostname: target01

### Detection — Partial

Rule 100003 (auditd TTY filter) did not fire. This is a confirmed detection gap.

The Python reverse shell uses os.dup2 to redirect file descriptors rather than spawning a new process with a TTY. At the point of the initial execve syscall that auditd captures, no TTY is assigned — the TTY filter condition (audit.tty != (none)) filters it out as if it were a headless process.

Wazuh did detect the sudo attempts made from the shell:

| Timestamp | Rule ID | Level | Description |
|---|---|---|---|
| 12:07:39 | 5405 | 5 | Unauthorized user attempted to use sudo |
| 12:07:31 | 5405 | 5 | Unauthorized user attempted to use sudo |
| 12:01:53 | 533 | 7 | Listened ports status changed (new port opened) |

The port change alert (rule 533) fired when the reverse shell connection was established — this is a useful indirect indicator of compromise.

### Detection Gap — New Sigma Rule

A new Sigma rule T1059.004-python-reverse-shell.yml was written to detect Python processes with socket/subprocess patterns in their arguments, independent of TTY status. This rule targets the EXECVE log entry for the python3 process itself rather than the spawned shell.

---

## Stage 4 — T1136.001: Create Backdoor Account

### Result: BLOCKED

Privilege escalation was exhausted before this stage could be attempted.

### Escalation paths attempted from www-data shell

| Method | Result | Notes |
|---|---|---|
| sudo useradd | Denied | www-data has no sudo rights |
| SUID binaries | No exploitable binaries | Standard Ubuntu set only |
| MySQL root via socket | Access denied | Root only allows local socket auth |
| MySQL FILE privilege | Permission denied | dvwa user has no FILE grant |
| Credential reuse (p@ssw0rd) | Auth failure | DVWA db password not reused on system |
| Cron job write | Permission denied | No writable cron paths |
| /etc/passwd write | Permission denied | Root-owned, world-readable only |

### Why This Is Good News

The privilege escalation failure is a direct result of correct configuration:

- www-data has no sudo rights
- No NOPASSWD entries for web service accounts
- No credential reuse between application and system accounts
- MySQL root protected by socket authentication

In a real engagement this would be documented as a finding that the defensive controls on target01 are effective.

---

## Stage 5 — T1070.002: Clear Logs

### Result: NOT ATTEMPTED

Stage 4 was blocked. Log clearing was not attempted as there was nothing meaningful to cover — the attacker did not achieve elevated access and the primary evidence (Wazuh alerts already forwarded to node03) cannot be cleared from the target anyway.

---

## Detection Summary

| Stage | Technique | Result | Wazuh Rule | Notes |
|---|---|---|---|---|
| 1 — Network scan | T1046 | Not detected | None | No network sensor on fw01 |
| 2 — Default credentials | T1190 | Not detected | None | Apache logs not in Wazuh |
| 3 — Reverse shell | T1059.004 | Partial | 533, 5405 | Rule 100003 bypassed by Python shell |
| 4 — Backdoor account | T1136.001 | Blocked | N/A | No privilege escalation path |
| 5 — Log clearing | T1070.002 | Not attempted | N/A | Blocked by stage 4 |

---

## Detection Gaps and Recommendations

### Gap 1 — Network scanning not detected (T1046)
Deploy Suricata on fw01 in IDS mode on eth1. Planned for Phase 7.

### Gap 2 — Web application login not detected (T1190)
Configure Wazuh agent on target01 to ingest Apache access logs. A custom rule matching POST to /dvwa/login.php with a 302 response would detect successful logins.

### Gap 3 — Python reverse shell bypasses TTY detection (T1059.004)
Rule 100003 relies on audit.tty != (none). Python reverse shells using os.dup2 bypass this because no TTY is assigned at execve time. New Sigma rule T1059.004-python-reverse-shell.yml added to detections/sigma/ to address this.

---

## Defensive Controls Validated

| Control | Status | Effect |
|---|---|---|
| www-data has no sudo rights | Confirmed effective | Blocked T1136.001 |
| No credential reuse | Confirmed effective | Blocked privilege escalation |
| MySQL socket auth for root | Confirmed effective | Blocked MySQL-based privesc |
| Wazuh real-time log forwarding | Confirmed effective | Log clearing would not erase evidence |

---

## Sigma Rules

| File | Technique | Status |
|---|---|---|
| detections/sigma/T1059.004-reverse-shell.yml | Interactive shell via auditd TTY | Existing |
| detections/sigma/T1059.004-python-reverse-shell.yml | Python reverse shell via socket | New — added as result of this exercise |
