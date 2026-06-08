#!/bin/bash
# 01-recon.sh
# Network discovery
sudo nmap -sn 192.168.10.0/24

# Full port scan on DC01
sudo nmap -sV -sC -p- 192.168.10.10 -oN scans/dc01-fullscan.txt

# SMB enumeration
crackmapexec smb 192.168.10.0/24
