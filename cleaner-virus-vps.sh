#!/bin/bash

# Pterodactyl VPS Malware Eradication Script
# WARNING: Backup data penting sebelum menjalankan script ini!

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${RED}"
echo "=========================================="
echo "  PTERODACTYL VPS MALWARE KILLER"
echo "=========================================="
echo -e "${NC}"

# Check root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}[!] Harus dijalankan sebagai root!${NC}"
    exit 1
fi

# Backup penting
echo -e "${YELLOW}[*] Creating backup of important configs...${NC}"
mkdir -p /root/malware-cleanup-backup-$(date +%Y%m%d)
cp -r /etc/pterodactyl /root/malware-cleanup-backup-$(date +%Y%m%d)/ 2>/dev/null
cp -r /var/www/pterodactyl /root/malware-cleanup-backup-$(date +%Y%m%d)/ 2>/dev/null
mysqldump -u root pterodactyl > /root/malware-cleanup-backup-$(date +%Y%m%d)/pterodactyl-db.sql 2>/dev/null

echo -e "${GREEN}[✓] Backup selesai di /root/malware-cleanup-backup-$(date +%Y%m%d)/${NC}"

# Update dan install tools
echo -e "${YELLOW}[*] Installing security tools...${NC}"
apt-get update -qq
apt-get install -y clamav clamav-daemon rkhunter chkrootkit maldet aide iptables-persistent fail2ban -qq

# Stop services sementara
echo -e "${YELLOW}[*] Stopping services temporarily...${NC}"
systemctl stop wings 2>/dev/null
systemctl stop pteroq 2>/dev/null
systemctl stop nginx 2>/dev/null
systemctl stop apache2 2>/dev/null

# Update virus definitions
echo -e "${YELLOW}[*] Updating virus definitions...${NC}"
systemctl stop clamav-freshclam 2>/dev/null
freshclam
maldet --update 2>/dev/null

# KILL SUSPICIOUS PROCESSES
echo -e "${RED}[!] Killing suspicious processes...${NC}"
pkill -9 -f "xmrig|minerd|cpuminer|/tmp/|/dev/shm/"
pkill -9 -f "nc -l|ncat|cryptonight"

# SCAN & REMOVE WEBSHELLS
echo -e "${YELLOW}[*] Scanning for webshells in Pterodactyl directories...${NC}"
WEBSHELL_PATTERNS="eval|base64_decode|gzinflate|str_rot13|assert|system|exec|shell_exec|passthru|popen|proc_open|pcntl_exec"

find /var/www/pterodactyl -type f \( -name "*.php" -o -name "*.suspected" \) -exec grep -l -E "$WEBSHELL_PATTERNS" {} \; > /root/suspected-webshells.txt 2>/dev/null

if [ -s /root/suspected-webshells.txt ]; then
    echo -e "${RED}[!] Potential webshells found:${NC}"
    cat /root/suspected-webshells.txt
    
    read -p "Delete suspected files? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        while read file; do
            echo -e "${RED}[!] Deleting: $file${NC}"
            rm -f "$file"
        done < /root/suspected-webshells.txt
    fi
fi

# CLEAN /tmp dan /dev/shm
echo -e "${YELLOW}[*] Cleaning /tmp and /dev/shm...${NC}"
find /tmp -type f -executable -delete 2>/dev/null
find /dev/shm -type f -delete 2>/dev/null
rm -rf /tmp/.* 2>/dev/null
rm -rf /tmp/* 2>/dev/null

# SCAN MALICIOUS CRON JOBS
echo -e "${YELLOW}[*] Checking cron jobs...${NC}"
echo "=== SYSTEM CRONTAB ===" > /root/cron-audit.log
cat /etc/crontab >> /root/cron-audit.log

for user in $(cut -f1 -d: /etc/passwd); do
    echo "=== $user crontab ===" >> /root/cron-audit.log
    crontab -u $user -l 2>/dev/null >> /root/cron-audit.log
done

grep -E "curl|wget|/tmp/|/dev/shm|base64|python -c|perl -e" /root/cron-audit.log > /root/suspicious-crons.txt

if [ -s /root/suspicious-crons.txt ]; then
    echo -e "${RED}[!] Suspicious cron jobs found! Check /root/suspicious-crons.txt${NC}"
fi

# SCAN BACKDOOR SSH KEYS
echo -e "${YELLOW}[*] Checking SSH authorized_keys...${NC}"
find / -name "authorized_keys" 2>/dev/null > /root/ssh-keys-locations.txt
echo -e "${YELLOW}[*] SSH key locations saved to /root/ssh-keys-locations.txt${NC}"

# CHECK PTERODACTYL FILES INTEGRITY
echo -e "${YELLOW}[*] Checking Pterodactyl file integrity...${NC}"
cd /var/www/pterodactyl
if [ -f "composer.json" ]; then
    # Check for modified core files
    find /var/www/pterodactyl/app -type f -name "*.php" -mtime -7 > /root/recently-modified-pterodactyl.txt
    
    if [ -s /root/recently-modified-pterodactyl.txt ]; then
        echo -e "${YELLOW}[*] Recently modified Pterodactyl files (last 7 days):${NC}"
        cat /root/recently-modified-pterodactyl.txt
    fi
fi

# DEEP SCAN WITH CLAMAV
echo -e "${YELLOW}[*] Running deep ClamAV scan (this will take time)...${NC}"
clamscan -r -i --remove=yes \
    --exclude-dir="^/sys" \
    --exclude-dir="^/proc" \
    --exclude-dir="^/dev" \
    /var/www/ \
    /home/ \
    /root/ \
    /tmp/ \
    /etc/ > /root/clamav-full-scan.log 2>&1 &

CLAM_PID=$!

# MALDET SCAN
echo -e "${YELLOW}[*] Running Linux Malware Detect scan...${NC}"
maldet -a /var/www/pterodactyl 2>/dev/null > /root/maldet-scan.log &

# ROOTKIT SCAN
echo -e "${YELLOW}[*] Running rootkit scans...${NC}"
rkhunter --update
rkhunter --propupd
rkhunter --check --skip-keypress --report-warnings-only > /root/rkhunter-scan.log 2>&1
chkrootkit > /root/chkrootkit-scan.log 2>&1

# CHECK NETWORK CONNECTIONS
echo -e "${YELLOW}[*] Checking network connections...${NC}"
netstat -antp | grep ESTABLISHED > /root/network-connections.log
ss -tunlp > /root/listening-ports.log

# SUSPICIOUS PROCESSES
echo -e "${YELLOW}[*] Checking suspicious processes...${NC}"
ps aux | grep -E "nc -l|ncat|/tmp/|/dev/shm/|xmrig|miner" | grep -v grep > /root/suspicious-processes.log

# CHECK LD_PRELOAD HIJACKING
echo -e "${YELLOW}[*] Checking LD_PRELOAD...${NC}"
if [ -f "/etc/ld.so.preload" ]; then
    echo -e "${RED}[!] WARNING: /etc/ld.so.preload exists!${NC}"
    cat /etc/ld.so.preload > /root/ld-preload-backup.txt
    echo -e "${YELLOW}[*] Backed up to /root/ld-preload-backup.txt${NC}"
fi

# HARDEN SYSTEM
echo -e "${YELLOW}[*] Applying security hardening...${NC}"

# Disable unnecessary services
systemctl disable telnet 2>/dev/null
systemctl stop telnet 2>/dev/null

# Secure SSH
if [ -f "/etc/ssh/sshd_config" ]; then
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    echo -e "${GREEN}[✓] SSH hardened (root login disabled, key-only auth)${NC}"
fi

# Configure fail2ban
if [ -f "/etc/fail2ban/jail.local" ]; then
    systemctl enable fail2ban
    systemctl restart fail2ban
    echo -e "${GREEN}[✓] Fail2ban configured${NC}"
fi

# Set proper permissions for Pterodactyl
echo -e "${YELLOW}[*] Setting proper Pterodactyl permissions...${NC}"
chown -R www-data:www-data /var/www/pterodactyl
chmod -R 755 /var/www/pterodactyl
chmod -R 755 /var/www/pterodactyl/storage
chmod -R 755 /var/www/pterodactyl/bootstrap/cache

# Wait for ClamAV to finish
echo -e "${YELLOW}[*] Waiting for ClamAV scan to complete...${NC}"
wait $CLAM_PID

# Restart services
echo -e "${YELLOW}[*] Restarting services...${NC}"
systemctl start nginx 2>/dev/null || systemctl start apache2 2>/dev/null
systemctl start pteroq 2>/dev/null
systemctl start wings 2>/dev/null
systemctl restart sshd

# SUMMARY REPORT
echo ""
echo -e "${GREEN}=========================================="
echo "  SCAN COMPLETE!"
echo "==========================================${NC}"
echo ""
echo -e "${YELLOW}Check these log files:${NC}"
echo "- /root/clamav-full-scan.log (ClamAV results)"
echo "- /root/maldet-scan.log (Maldet results)"
echo "- /root/rkhunter-scan.log (Rootkit scan)"
echo "- /root/chkrootkit-scan.log (Chkrootkit scan)"
echo "- /root/suspicious-crons.txt (Suspicious cron jobs)"
echo "- /root/suspicious-processes.log (Suspicious processes)"
echo "- /root/network-connections.log (Active connections)"
echo "- /root/suspected-webshells.txt (Potential webshells)"
echo ""
echo -e "${RED}CRITICAL - MANUAL CHECKS REQUIRED:${NC}"
echo "1. Review /root/ssh-keys-locations.txt - Check for unauthorized SSH keys"
echo "2. Review /root/cron-audit.log - Look for malicious cron jobs"
echo "3. Check database: mysql -u root pterodactyl"
echo "4. Review user accounts: cat /etc/passwd"
echo "5. Check Wings nodes for infected game servers"
echo ""
echo -e "${YELLOW}NEXT STEPS:${NC}"
echo "1. Review all log files above"
echo "2. If malware found, consider fresh reinstall"
echo "3. Change all passwords (root, database, Pterodactyl admin)"
echo "4. Regenerate SSH keys"
echo "5. Enable 2FA on Pterodactyl admin panel"
echo "6. Monitor logs: tail -f /var/log/auth.log"
echo ""
echo -e "${GREEN}Backup saved to: /root/malware-cleanup-backup-$(date +%Y%m%d)/${NC}"
echo "=========================================="
