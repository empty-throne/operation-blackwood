# DFIR Case File — CASE-BW-001
## Active Directory Domain Compromise via Password Spray & Pass-the-Hash

---

```
Classification  : CONFIDENTIAL (Lab Environment)
Case Number     : CASE-BW-001
Date Opened     : June 7, 2026
Analyst         : Zackery
Environment     : BLACKWOOD.local (Isolated VirtualBox Home Lab)
Severity        : CRITICAL — Full Domain Compromise
Status          : CLOSED — Root Cause Identified
```

---

## 1. Executive Summary

On June 7, 2026, anomalous authentication activity was detected against Domain Controller `DC01.BLACKWOOD.local` (192.168.10.10). Investigation confirmed a multi-stage intrusion originating from host `192.168.10.99` (Kali Linux attacker VM). The threat actor performed credential-based attacks including password spraying and credential dumping, ultimately achieving Domain Admin-level remote code execution via Pass-the-Hash using a compromised privileged account (`aturner`).

**Total time from first attack event to full domain compromise: approximately 22 minutes.**

No zero-day exploits or advanced techniques were used. The entire attack chain exploited misconfigured policies and weak credentials that are common in real enterprise environments.

---

## 2. Incident Timeline

```
[T+00:00]  192.168.10.99  →  Nmap SYN scan initiated against 192.168.10.0/24
[T+02:14]  192.168.10.99  →  SMB enumeration — BLACKWOOD.local domain confirmed
[T+04:31]  192.168.10.99  →  Password spray begins — 41 x Event ID 4625 in 90 seconds
[T+04:33]  192.168.10.99  →  jsmith:Password123! authenticated — Event ID 4624 (Logon Type 3)
[T+06:10]  192.168.10.99  →  impacket-secretsdump executed as jsmith
[T+06:12]  192.168.10.99  →  aturner NTLM hash extracted — Event ID 4776
[T+14:22]  192.168.10.99  →  Pass-the-Hash with aturner hash — Event ID 4776 (0x0 success)
[T+14:23]  192.168.10.99  →  crackmapexec confirms Pwn3d! on DC01
[T+22:01]  192.168.10.99  →  Remote command execution — blackwood\aturner on DC01
[T+22:01]  192.168.10.99  →  Full domain compromise confirmed
```

---

## 3. Affected Assets

| Asset | Role | Impact |
|-------|------|--------|
| DC01.BLACKWOOD.local (192.168.10.10) | Domain Controller | COMPROMISED — remote code execution |
| jsmith@BLACKWOOD.local | HR User | Credentials stolen via password spray |
| aturner@BLACKWOOD.local | Domain Admin | NTLM hash extracted — used for PTH |
| svc-backup@BLACKWOOD.local | Service Account | SPN registered — Kerberoast target (attack attempted, tooling compatibility issue with Server 2025) |

---

## 4. Attack Chain Analysis

### 4.1 Reconnaissance (T1046, T1135)

**Tools:** nmap, crackmapexec  
**Evidence:** Network logs showing SYN scan pattern from 192.168.10.99

**Nmap findings:**
```
PORT     STATE  SERVICE
88/tcp   open   kerberos-sec
135/tcp  open   msrpc
139/tcp  open   netbios-ssn
389/tcp  open   ldap
445/tcp  open   microsoft-ds
5985/tcp open   wsman
```

**SMB enumeration result:**
```
SMB  192.168.10.10  445  DC01  Windows Server 2025 - BLACKWOOD.local (signing:True)
```

Notable: SMB signing enabled but not required — potential relay attack vector.

---

### 4.2 Password Spraying (T1110.003)

**Tool:** crackmapexec  
**Evidence:** Event ID 4625 — Account Failed to Log On

```
Event ID      : 4625
Timeframe     : June 7, 2026 — 41 failures in 90 seconds
Source IP     : 192.168.10.99
Logon Type    : 3 (Network)
Failure Code  : 0xC000006A (Wrong password)
Accounts hit  : administrator, jsmith, aturner, bcarter, svc-backup
```

**Detection signature triggered:**
> 41 Event ID 4625 failures from 192.168.10.99 within 90 seconds → CRITICAL ALERT

**Successful authentication:**
```
Event ID      : 4624
Time          : June 7, 2026 T+04:33
Account       : BLACKWOOD\jsmith
Logon Type    : 3 (Network)
Source IP     : 192.168.10.99
```

**Root cause:** jsmith account password `Password123!` met complexity requirements but was trivially guessable and present in common wordlists. No account lockout policy was enforced.

---

### 4.3 Kerberoasting Attempt (T1558.003)

**Tool:** Impacket GetUserSPNs.py  
**Result:** ATTEMPTED — unsuccessful due to tooling compatibility

**Details:**
```
Target Account  : svc-backup
SPN             : HTTP/backup.BLACKWOOD.local (confirmed via setspn -L)
Error           : KRB_AP_ERR_SKEW — persistent clock skew errors
Root Cause      : Known Impacket compatibility issue with Windows Server 2025
                  Kerberos implementation changes
Impact          : Hash not extracted via this method
```

**Detection note:** Even though the attack tool failed, Event ID 4769 would still fire on any successful ticket request. The RC4 encryption type (0x17) in 4769 remains a reliable Kerberoasting detection signature regardless of whether the attacker successfully cracks the hash.

**Alternative tooling note:** Rubeus would succeed in a real engagement. The vulnerability exists — only the specific tool version had compatibility issues.

---

### 4.4 Credential Dumping (T1003.006)

**Tool:** impacket-secretsdump  
**Evidence:** Event ID 4776 — NTLM Authentication

```
Command   : impacket-secretsdump jsmith:'Password123!'@192.168.10.10 -just-dc-user aturner
Result    : BLACKWOOD.local\aturner:1103:aad3b435b51404eeaad3b435b51404ee:72f0eefcc213ea8f350773b831cf2c9c:::
```

**NTLM hash extracted:**
```
Username  : aturner
RID       : 1103
LM Hash   : aad3b435b51404eeaad3b435b51404ee (empty)
NTLM Hash : 72f0eefcc213ea8f350773b831cf2c9c
```

**Root cause:** jsmith had sufficient permissions to trigger DRSUAPI replication against the DC, exposing aturner's credential material without knowing aturner's plaintext password.

---

### 4.5 Pass-the-Hash & Remote Execution (T1550.002, T1021.002)

**Tool:** crackmapexec  
**Evidence:** Event ID 4776 — multiple 0x0 success codes for aturner

```
Event ID    : 4776
Account     : aturner
Error Code  : 0x0 (Success — repeated)
Source      : 192.168.10.99
```

**Execution confirmation:**
```
crackmapexec smb 192.168.10.10 -u aturner -H 72f0eefcc213ea8f350773b831cf2c9c -x "whoami"

SMB  192.168.10.10  445  DC01  [+] BLACKWOOD.local\aturner (Pwn3d!)
SMB  192.168.10.10  445  DC01  [+] Executed command
SMB  192.168.10.10  445  DC01  blackwood\aturner
```

**Full domain compromise confirmed.** Remote code execution achieved on DC01 as Domain Admin without ever knowing aturner's plaintext password.

---

## 5. Root Cause Analysis

Five compounding misconfigurations enabled this attack chain from initial access to full domain compromise:

| # | Misconfiguration | Exploited By | Fix |
|---|-----------------|-------------|-----|
| 1 | Weak password — `Password123!` on jsmith | Password Spray | Enforce 15+ char minimum, ban common passwords |
| 2 | No account lockout policy | Password Spray | Lockout after 5 failures, 30-min window |
| 3 | RC4 Kerberos encryption enabled | Kerberoasting | Enforce AES only via GPO |
| 4 | No MFA on privileged accounts | Pass-the-Hash | Enforce MFA for all Domain Admins |
| 5 | NTLM not restricted | Pass-the-Hash | Restrict NTLM via GPO |

**Most critical finding:** The entire attack required no exploitation of software vulnerabilities. Every stage abused legitimate Windows authentication mechanisms. This is the real threat landscape — misconfiguration and weak credentials are more dangerous than unpatched CVEs in most enterprise environments.

---

## 6. Indicators of Compromise (IOCs)

```
TYPE              VALUE                               CONTEXT
────────────────  ──────────────────────────────────  ──────────────────────────────
IP Address        192.168.10.99                       Attacker — Kali Linux
Account           jsmith@BLACKWOOD.local              Sprayed — initial access vector
Account           aturner@BLACKWOOD.local             NTLM hash — PTH domain compromise
NTLM Hash         72f0eefcc213ea8f350773b831cf2c9c   aturner — used in Pass-the-Hash
Event IDs         4625 x41, 4776 (0x0), 4624         Core detection artifact cluster
Source IP         192.168.10.99                       Present in 4625, 4624, 4776
```

---

## 7. Detection Opportunities

Every stage of this attack had a detection opportunity. A properly tuned SIEM would have alerted within 90 seconds of the spray beginning.

| Stage | Event ID | Detection Rule | Priority |
|-------|----------|---------------|----------|
| Password Spray | 4625 | >10 failures from single IP in 5 min | CRITICAL |
| Initial Access | 4624 | Logon Type 3 from new external IP | HIGH |
| Credential Dump | 4776 | NTLM auth from non-standard source | HIGH |
| Pass-the-Hash | 4776 | 0x0 success + no prior 4624 from same IP | CRITICAL |
| Kerberoasting | 4769 | EncryptionType = 0x17 (RC4) | HIGH |
| Lateral Movement | 4648 | Explicit credential logon to DC | CRITICAL |

---

## 8. Remediation Recommendations

### Immediate (Critical)
- [ ] Reset all compromised account passwords (jsmith, aturner, svc-backup)
- [ ] Force re-issue of all Kerberos tickets (`klist purge` on all systems)
- [ ] Block 192.168.10.99 at network boundary
- [ ] Rotate krbtgt account password twice (Golden Ticket invalidation)
- [ ] Audit all Domain Admin group members

### Short-Term (High)
- [ ] Enforce minimum 15-character passwords with complexity
- [ ] Set account lockout — 5 failures, 30-minute observation window
- [ ] Disable RC4 encryption — enforce AES only for Kerberos
- [ ] Enable Protected Users security group for all admin accounts
- [ ] Deploy LAPS on all workstations
- [ ] Restrict NTLM via GPO: `Network Security: Restrict NTLM`

### Long-Term (Strategic)
- [ ] Deploy Microsoft Defender for Identity (MDI)
- [ ] Implement Privileged Access Workstations (PAWs)
- [ ] Adopt Tiered AD Administration model (Tier 0/1/2)
- [ ] Enable Credential Guard on Windows endpoints
- [ ] Run quarterly password audits — DSInternals `Test-PasswordQuality`
- [ ] Establish SIEM alerting on all Event IDs listed in Section 7

---

## 9. Lessons Learned

**For defenders:** The entire attack chain took 22 minutes and required no advanced techniques. Detection opportunities existed at every single stage. The failure was not in the tools — it was in the absence of monitoring and policy enforcement. A single SIEM rule on Event ID 4625 threshold would have triggered an alert within 90 seconds of the attack beginning.

**For practitioners:** Real-world attackers don't need sophistication when misconfiguration does the work. Password spraying, credential dumping, and Pass-the-Hash are not exotic techniques — they are the baseline. Defenders who don't understand how these attacks work at the log level cannot write effective detection rules.

**On the Kerberoasting compatibility issue:** Documenting failed attack attempts is as valuable as documenting successful ones. Real penetration test reports include failed techniques, compatibility issues, and alternative tooling recommendations. The vulnerability existed — the specific tool version had a limitation. In a real engagement, Rubeus would have succeeded.

---

## 10. Analyst Notes

This case file was produced as part of the **Operation Blackwood** Active Directory home lab project. The environment was fully isolated within a VirtualBox internal network on personal hardware. All attack techniques were self-directed against systems I own and operate for educational purposes.

This investigation demonstrates the following DFIR competencies:
- Evidence preservation and structured documentation
- Windows Security Event Log analysis
- Attack chain reconstruction from log artifacts
- IOC identification and documentation
- Actionable remediation aligned to security best practices

---

*CASE-BW-001 | Status: CLOSED | Analyst: Zackery | June 7, 2026 | BLACKWOOD.local Lab*
