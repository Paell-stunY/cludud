#!/bin/bash

# ============================================
# WEBSITE MANAGER - ALL IN ONE SCRIPT
# Author: Auto Web Manager
# Version: 2.0
# ============================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
BASE_DIR="/var/www"
NGINX_AVAILABLE="/etc/nginx/sites-available"
NGINX_ENABLED="/etc/nginx/sites-enabled"
APACHE_AVAILABLE="/etc/apache2/sites-available"
APACHE_ENABLED="/etc/apache2/sites-enabled"

# Function to print header
print_header() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           🚀 WEBSITE MANAGER - ALL IN ONE               ║${NC}"
    echo -e "${BLUE}║                 Version 2.0 - $(date +%Y)                     ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Function to print status messages
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# Function to detect web server
detect_webserver() {
    if systemctl is-active --quiet nginx; then
        echo "nginx"
    elif systemctl is-active --quiet apache2; then
        echo "apache"
    else
        echo "none"
    fi
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Script harus dijalankan sebagai root/sudo"
        exit 1
    fi
}

# Function to check dependencies
check_dependencies() {
    local missing=()
    
    # Check for required commands
    for cmd in curl wget grep sed awk; do
        if ! command -v $cmd &> /dev/null; then
            missing+=($cmd)
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        print_warning "Menginstall dependencies yang hilang..."
        apt update
        apt install -y ${missing[@]}
    fi
}

# Function 1: CREATE WEBSITE
create_website() {
    print_header
    echo -e "${CYAN}📝 CREATE NEW WEBSITE${NC}"
    echo -e "${BLUE}══════════════════════════════════════════${NC}"
    
    # Get site name
    echo -n "Masukkan nama website (contoh: tokosaya): "
    read SITE_NAME
    
    if [ -z "$SITE_NAME" ]; then
        print_error "Nama website tidak boleh kosong!"
        sleep 2
        return
    fi
    
    # Get domain
    echo -n "Masukkan domain (contoh: tokosaya.com): "
    read DOMAIN
    
    if [ -z "$DOMAIN" ]; then
        print_error "Domain tidak boleh kosong!"
        sleep 2
        return
    fi
    
    WWW_DOMAIN="www.$DOMAIN"
    SITE_PATH="$BASE_DIR/$SITE_NAME"
    HTML_PATH="$SITE_PATH/public_html"
    LOG_PATH="$SITE_PATH/logs"
    
    # Check if site already exists
    if [ -d "$SITE_PATH" ]; then
        print_warning "Website '$SITE_NAME' sudah ada!"
        read -p "Timpa? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Proses dibatalkan"
            sleep 2
            return
        fi
        rm -rf "$SITE_PATH"
    fi
    
    # Detect web server
    WEBSERVER=$(detect_webserver)
    
    if [ "$WEBSERVER" = "none" ]; then
        print_warning "Web server tidak terdeteksi!"
        echo -e "${YELLOW}Pilih web server:${NC}"
        echo "1) Nginx (Direkomendasikan)"
        echo "2) Apache"
        echo "3) Keluar"
        
        read -p "Pilihan [1-3]: " choice
        
        case $choice in
            1)
                apt update
                apt install -y nginx
                WEBSERVER="nginx"
                systemctl enable nginx
                systemctl start nginx
                print_status "Nginx berhasil diinstall!"
                ;;
            2)
                apt update
                apt install -y apache2
                WEBSERVER="apache"
                systemctl enable apache2
                systemctl start apache2
                print_status "Apache berhasil diinstall!"
                ;;
            *)
                print_error "Installasi dibatalkan"
                sleep 2
                return
                ;;
        esac
    fi
    
    # Create directory structure
    print_status "Membuat struktur direktori..."
    mkdir -p "$HTML_PATH"
    mkdir -p "$LOG_PATH"
    mkdir -p "$SITE_PATH/backups"
    mkdir -p "$SITE_PATH/certs"
    
    # Create sample index.html
    cat > "$HTML_PATH/index.html" << EOF
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$DOMAIN - Website Baru</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            text-align: center;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            padding: 3rem;
            border-radius: 15px;
            backdrop-filter: blur(10px);
            max-width: 600px;
        }
        h1 {
            color: #00ff88;
            margin-bottom: 1rem;
        }
        .info {
            background: rgba(0, 0, 0, 0.2);
            padding: 1rem;
            border-radius: 8px;
            margin: 1rem 0;
            text-align: left;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 Website Berhasil Dibuat!</h1>
        <p><strong>$DOMAIN</strong> siap digunakan!</p>
        
        <div class="info">
            <p><strong>📁 Upload file ke:</strong><br>
            <code>$HTML_PATH</code></p>
            
            <p><strong>🌐 Domain:</strong><br>
            $DOMAIN</p>
            
            <p><strong>🛠️ Web Server:</strong><br>
            $WEBSERVER</p>
        </div>
        
        <p>Ganti file ini dengan kode website Anda!</p>
    </div>
</body>
</html>
EOF
    
    # Create web server configuration
    if [ "$WEBSERVER" = "nginx" ]; then
        # Nginx config
        cat > "$NGINX_AVAILABLE/$SITE_NAME" << EOF
server {
    listen 80;
    server_name $DOMAIN $WWW_DOMAIN;
    
    root $HTML_PATH;
    index index.html index.htm index.php;
    
    access_log $LOG_PATH/access.log;
    error_log $LOG_PATH/error.log;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    location ~ /\. {
        deny all;
    }
}
EOF
        ln -sf "$NGINX_AVAILABLE/$SITE_NAME" "$NGINX_ENABLED/"
        nginx -t && systemctl reload nginx
        
    elif [ "$WEBSERVER" = "apache" ]; then
        # Apache config
        cat > "$APACHE_AVAILABLE/$SITE_NAME.conf" << EOF
<VirtualHost *:80>
    ServerAdmin webmaster@$DOMAIN
    ServerName $DOMAIN
    ServerAlias $WWW_DOMAIN
    DocumentRoot $HTML_PATH
    
    <Directory $HTML_PATH>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog $LOG_PATH/error.log
    CustomLog $LOG_PATH/access.log combined
</VirtualHost>
EOF
        a2ensite "$SITE_NAME.conf"
        apache2ctl configtest && systemctl reload apache2
    fi
    
    # Set permissions
    chown -R www-data:www-data "$SITE_PATH"
    chmod -R 755 "$HTML_PATH"
    
    # Create info file
    cat > "$SITE_PATH/site-info.txt" << EOF
Website: $SITE_NAME
Domain: $DOMAIN
WWW Domain: $WWW_DOMAIN
Created: $(date)
Path: $HTML_PATH
Web Server: $WEBSERVER

UPLOAD FILES:
- Upload HTML/CSS/JS ke: $HTML_PATH
- Ganti index.html dengan website Anda

MANAGEMENT:
- Edit config: /etc/$WEBSERVER/sites-available/$SITE_NAME
- View logs: $LOG_PATH/
- Backup: tar -czf backup.tar.gz $HTML_PATH
EOF
    
    # Create management script for this site
    cat > "$SITE_PATH/manage.sh" << EOF
#!/bin/bash
echo "Website: $SITE_NAME"
echo "Domain: $DOMAIN"
echo "Path: $HTML_PATH"
echo ""
echo "Commands:"
echo "  tail -f $LOG_PATH/error.log    # View error log"
echo "  tail -f $LOG_PATH/access.log   # View access log"
echo "  nano $HTML_PATH/index.html     # Edit index file"
EOF
    chmod +x "$SITE_PATH/manage.sh"
    
    # Display summary
    echo ""
    echo -e "${GREEN}══════════════════════════════════════════${NC}"
    echo -e "${GREEN}          WEBSITE BERHASIL DIBUAT!        ${NC}"
    echo -e "${GREEN}══════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}📋 DETAIL WEBSITE:${NC}"
    echo -e "  Nama     : ${YELLOW}$SITE_NAME${NC}"
    echo -e "  Domain   : ${YELLOW}$DOMAIN${NC}"
    echo -e "  WWW      : ${YELLOW}$WWW_DOMAIN${NC}"
    echo -e "  Path     : ${YELLOW}$HTML_PATH${NC}"
    echo -e "  Server   : ${YELLOW}$WEBSERVER${NC}"
    echo ""
    echo -e "${CYAN}🚀 NEXT STEPS:${NC}"
    echo "  1. Upload file ke: $HTML_PATH"
    echo "  2. Akses website: http://$DOMAIN"
    echo "  3. Untuk SSL: certbot --$WEBSERVER -d $DOMAIN"
    echo ""
    
    # Update local hosts for testing
    if [[ ! "$DOMAIN" =~ (localhost|test) ]]; then
        echo -e "${YELLOW}💡 TIP:${NC} Untuk testing lokal, tambahkan di /etc/hosts:"
        echo -e "     $(hostname -I | awk '{print $1}')   $DOMAIN $WWW_DOMAIN"
    fi
    
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Function 2: LIST WEBSITES
list_websites() {
    print_header
    echo -e "${CYAN}📋 LIST ALL WEBSITES${NC}"
    echo -e "${BLUE}══════════════════════════════════════════${NC}"
    
    # Check if base directory exists
    if [ ! -d "$BASE_DIR" ]; then
        print_error "Direktori $BASE_DIR tidak ditemukan!"
        read -p "Tekan Enter untuk kembali..."
        return
    fi
    
    # Count total websites
    TOTAL_SITES=$(ls -d $BASE_DIR/*/ 2>/dev/null | wc -l)
    
    if [ $TOTAL_SITES -eq 0 ]; then
        echo -e "${YELLOW}Belum ada website yang dibuat.${NC}"
    else
        echo -e "${GREEN}Ditemukan $TOTAL_SITES website:${NC}"
        echo ""
        
        # List all websites
        for site_dir in $BASE_DIR/*/; do
            if [ -d "$site_dir" ]; then
                SITE_NAME=$(basename "$site_dir")
                SIZE=$(du -sh "$site_dir" 2>/dev/null | cut -f1)
                
                # Try to get domain from config files
                DOMAIN=""
                CONFIG_TYPE=""
                
                # Check Nginx config
                if [ -f "$NGINX_AVAILABLE/$SITE_NAME" ]; then
                    DOMAIN=$(grep "server_name" "$NGINX_AVAILABLE/$SITE_NAME" 2>/dev/null | head -1 | sed 's/.*server_name //;s/;//' | xargs)
                    CONFIG_TYPE="nginx"
                # Check Apache config
                elif [ -f "$APACHE_AVAILABLE/$SITE_NAME.conf" ]; then
                    DOMAIN=$(grep "ServerName" "$APACHE_AVAILABLE/$SITE_NAME.conf" 2>/dev/null | head -1 | sed 's/.*ServerName //' | xargs)
                    CONFIG_TYPE="apache"
                fi
                
                # Display site info
                echo -e "${YELLOW}► $SITE_NAME${NC}"
                if [ -n "$DOMAIN" ]; then
                    echo -e "   Domain: ${GREEN}$DOMAIN${NC}"
                fi
                echo -e "   Size: ${BLUE}$SIZE${NC}"
                echo -e "   Path: ${CYAN}$site_dir${NC}"
                if [ -n "$CONFIG_TYPE" ]; then
                    echo -e "   Config: ${PURPLE}$CONFIG_TYPE${NC}"
                fi
                
                # Check if website is accessible
                if [ -n "$DOMAIN" ] && [[ ! "$DOMAIN" =~ (localhost|test) ]]; then
                    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$DOMAIN" 2>/dev/null || echo "000")
                    if [[ $HTTP_CODE =~ ^(200|301|302)$ ]]; then
                        echo -e "   Status: ${GREEN}Online ✓${NC}"
                    else
                        echo -e "   Status: ${RED}Offline ✗${NC}"
                    fi
                fi
                echo ""
            fi
        done
    fi
    
    echo -e "${BLUE}══════════════════════════════════════════${NC}"
    
    # Show system info
    echo ""
    echo -e "${CYAN}📊 SYSTEM INFO:${NC}"
    echo -e "  Disk Usage: $(df -h /var/www | tail -1 | awk '{print $5}')"
    echo -e "  Web Server: $(detect_webserver)"
    echo -e "  IP Address: $(hostname -I | cut -d' ' -f1)"
    
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Function 3: DELETE WEBSITE
delete_website() {
    print_header
    echo -e "${CYAN}🗑️  DELETE WEBSITE${NC}"
    echo -e "${BLUE}══════════════════════════════════════════${NC}"
    
    # List available websites
    echo -e "${YELLOW}Website yang tersedia:${NC}"
    echo ""
    
    COUNT=0
    declare -a SITES_ARRAY
    
    for site_dir in $BASE_DIR/*/; do
        if [ -d "$site_dir" ]; then
            COUNT=$((COUNT + 1))
            SITE_NAME=$(basename "$site_dir")
            SITES_ARRAY[$COUNT]=$SITE_NAME
            
            # Get domain if exists
            DOMAIN=""
            if [ -f "$NGINX_AVAILABLE/$SITE_NAME" ]; then
                DOMAIN=$(grep "server_name" "$NGINX_AVAILABLE/$SITE_NAME" 2>/dev/null | head -1 | sed 's/.*server_name //;s/;//' | xargs)
            elif [ -f "$APACHE_AVAILABLE/$SITE_NAME.conf" ]; then
                DOMAIN=$(grep "ServerName" "$APACHE_AVAILABLE/$SITE_NAME.conf" 2>/dev/null | head -1 | sed 's/.*ServerName //' | xargs)
            fi
            
            echo -e "  ${COUNT}) ${YELLOW}$SITE_NAME${NC}"
            if [ -n "$DOMAIN" ]; then
                echo -e "     Domain: $DOMAIN"
            fi
            echo -e "     Path: $site_dir"
            echo ""
        fi
    done
    
    if [ $COUNT -eq 0 ]; then
        print_error "Tidak ada website yang ditemukan!"
        read -p "Tekan Enter untuk kembali..."
        return
    fi
    
    echo -e "${BLUE}══════════════════════════════════════════${NC}"
    echo -n "Pilih nomor website yang akan dihapus (1-$COUNT): "
    read CHOICE
    
    # Validate choice
    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt $COUNT ]; then
        print_error "Pilihan tidak valid!"
        sleep 2
        return
    fi
    
    SITE_NAME=${SITES_ARRAY[$CHOICE]}
    SITE_PATH="$BASE_DIR/$SITE_NAME"
    
    # Get domain for confirmation
    DOMAIN=""
    if [ -f "$NGINX_AVAILABLE/$SITE_NAME" ]; then
        DOMAIN=$(grep "server_name" "$NGINX_AVAILABLE/$SITE_NAME" 2>/dev/null | head -1 | sed 's/.*server_name //;s/;//' | xargs)
    elif [ -f "$APACHE_AVAILABLE/$SITE_NAME.conf" ]; then
        DOMAIN=$(grep "ServerName" "$APACHE_AVAILABLE/$SITE_NAME.conf" 2>/dev/null | head -1 | sed 's/.*ServerName //' | xargs)
    fi
    
    # Confirmation
    echo ""
    echo -e "${RED}⚠️  PERINGATAN: Anda akan menghapus website berikut:${NC}"
    echo -e "   Nama: ${YELLOW}$SITE_NAME${NC}"
    if [ -n "$DOMAIN" ]; then
        echo -e "   Domain: ${YELLOW}$DOMAIN${NC}"
    fi
    echo -e "   Path: ${YELLOW}$SITE_PATH${NC}"
    echo ""
    
    read -p "Apakah Anda yakin? (ketik 'ya' untuk konfirmasi): " CONFIRM
    
    if [ "$CONFIRM" != "ya" ]; then
        print_error "Penghapusan dibatalkan!"
        sleep 2
        return
    fi
    
    # Backup before deletion
    BACKUP_DIR="/tmp/website-backups"
    mkdir -p "$BACKUP_DIR"
    BACKUP_FILE="$BACKUP_DIR/$SITE_NAME-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    print_status "Membuat backup ke: $BACKUP_FILE"
    tar -czf "$BACKUP_FILE" -C "$BASE_DIR" "$SITE_NAME" 2>/dev/null
    
    # Remove from web server configs
    print_status "Menghapus konfigurasi web server..."
    
    # Nginx
    if [ -f "$NGINX_ENABLED/$SITE_NAME" ]; then
        rm "$NGINX_ENABLED/$SITE_NAME"
    fi
    if [ -f "$NGINX_AVAILABLE/$SITE_NAME" ]; then
        rm "$NGINX_AVAILABLE/$SITE_NAME"
    fi
    
    # Apache
    if [ -f "$APACHE_ENABLED/$SITE_NAME.conf" ]; then
        a2dissite "$SITE_NAME.conf" >/dev/null 2>&1
    fi
    if [ -f "$APACHE_AVAILABLE/$SITE_NAME.conf" ]; then
        rm "$APACHE_AVAILABLE/$SITE_NAME.conf"
    fi
    
    # Remove directory
    print_status "Menghapus direktori..."
    rm -rf "$SITE_PATH"
    
    # Reload web servers
    systemctl reload nginx 2>/dev/null
    systemctl reload apache2 2>/dev/null
    
    echo ""
    print_status "Website '$SITE_NAME' berhasil dihapus!"
    print_info "Backup disimpan di: $BACKUP_FILE"
    
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Function 4: QUICK BACKUP
quick_backup() {
    print_header
    echo -e "${CYAN}💾 QUICK BACKUP WEBSITE${NC}"
    echo -e "${BLUE}══════════════════════════════════════════${NC}"
    
    # List websites
    COUNT=0
    declare -a SITES_ARRAY
    
    for site_dir in $BASE_DIR/*/; do
        if [ -d "$site_dir" ]; then
            COUNT=$((COUNT + 1))
            SITE_NAME=$(basename "$site_dir")
            SITES_ARRAY[$COUNT]=$SITE_NAME
            
            SIZE=$(du -sh "$site_dir" 2>/dev/null | cut -f1)
            echo -e "  ${COUNT}) ${YELLOW}$SITE_NAME${NC} - ${BLUE}$SIZE${NC}"
        fi
    done
    
    if [ $COUNT -eq 0 ]; then
        print_error "Tidak ada website yang ditemukan!"
        read -p "Tekan Enter untuk kembali..."
        return
    fi
    
    echo ""
    echo -e "0) Backup SEMUA website"
    echo -e "${BLUE}══════════════════════════════════════════${NC}"
    echo -n "Pilih nomor website (0-$COUNT): "
    read CHOICE
    
    BACKUP_DIR="/var/www/backups"
    mkdir -p "$BACKUP_DIR"
    
    if [ "$CHOICE" = "0" ]; then
        # Backup all
        BACKUP_FILE="$BACKUP_DIR/all-websites-$(date +%Y%m%d-%H%M%S).tar.gz"
        print_status "Membackup semua website..."
        tar -czf "$BACKUP_FILE" -C "$BASE_DIR" $(ls "$BASE_DIR") 2>/dev/null
        print_status "Backup selesai: $BACKUP_FILE"
        echo -e "${GREEN}Size: $(du -h "$BACKUP_FILE" | cut -f1)${NC}"
        
    elif [[ "$CHOICE" =~ ^[0-9]+$ ]] && [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le $COUNT ]; then
        # Backup single website
        SITE_NAME=${SITES_ARRAY[$CHOICE]}
        BACKUP_FILE="$BACKUP_DIR/$SITE_NAME-$(date +%Y%m%d-%H%M%S).tar.gz"
        
        print_status "Membackup website: $SITE_NAME..."
        tar -czf "$BACKUP_FILE" -C "$BASE_DIR" "$SITE_NAME" 2>/dev/null
        
        if [ -f "$BACKUP_FILE" ]; then
            print_status "Backup selesai: $BACKUP_FILE"
            echo -e "${GREEN}Size: $(du -h "$BACKUP_FILE" | cut -f1)${NC}"
        else
            print_error "Gagal membuat backup!"
        fi
    else
        print_error "Pilihan tidak valid!"
    fi
    
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Function 5: SYSTEM STATUS
system_status() {
    print_header
    echo -e "${CYAN}📊 SYSTEM STATUS${NC}"
    echo -e "${BLUE}══════════════════════════════════════════${NC}"
    
    # Web Server Status
    WEBSERVER=$(detect_webserver)
    echo -e "${YELLOW}🌐 WEB SERVER:${NC}"
    if [ "$WEBSERVER" = "nginx" ]; then
        systemctl status nginx --no-pager | head -10
    elif [ "$WEBSERVER" = "apache" ]; then
        systemctl status apache2 --no-pager | head -10
    else
        echo -e "${RED}Tidak ada web server yang berjalan${NC}"
    fi
    
    # Disk Usage
    echo ""
    echo -e "${YELLOW}💾 DISK USAGE:${NC}"
    df -h /var/www
    
    # Memory Usage
    echo ""
    echo -e "${YELLOW}🧠 MEMORY USAGE:${NC}"
    free -h
    
    # Website Count
    echo ""
    echo -e "${YELLOW}📁 WEBSITE COUNT:${NC}"
    WEBSITE_COUNT=$(ls -d $BASE_DIR/*/ 2>/dev/null | wc -l)
    echo -e "  Total Website: ${GREEN}$WEBSITE_COUNT${NC}"
    
    # Recent Logs
    echo ""
    echo -e "${YELLOW}📝 RECENT ERRORS:${NC}"
    if [ "$WEBSERVER" = "nginx" ]; then
        tail -5 /var/log/nginx/error.log 2>/dev/null || echo "No error logs found"
    elif [ "$WEBSERVER" = "apache" ]; then
        tail -5 /var/log/apache2/error.log 2>/dev/null || echo "No error logs found"
    fi
    
    # Network Info
    echo ""
    echo -e "${YELLOW}🌍 NETWORK INFO:${NC}"
    echo -e "  IP Address: $(hostname -I | cut -d' ' -f1)"
    echo -e "  Hostname: $(hostname)"
    
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Function 6: INSTALL SSL
install_ssl() {
    print_header
    echo -e "${CYAN}🔒 INSTALL SSL CERTIFICATE${NC}"
    echo -e "${BLUE}══════════════════════════════════════════${NC}"
    
    # Check if certbot is installed
    if ! command -v certbot &> /dev/null; then
        print_warning "Certbot tidak ditemukan!"
        read -p "Install Certbot? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            apt update
            apt install -y certbot python3-certbot-nginx python3-certbot-apache
            print_status "Certbot berhasil diinstall!"
        else
            print_error "Certbot diperlukan untuk SSL!"
            sleep 2
            return
        fi
    fi
    
    # List websites with domains
    echo -e "${YELLOW}Website dengan domain:${NC}"
    echo ""
    
    COUNT=0
    declare -a SSL_SITES
    declare -a SSL_DOMAINS
    
    for site_dir in $BASE_DIR/*/; do
        if [ -d "$site_dir" ]; then
            SITE_NAME=$(basename "$site_dir")
            DOMAIN=""
            
            # Get domain from config
            if [ -f "$NGINX_AVAILABLE/$SITE_NAME" ]; then
                DOMAIN=$(grep "server_name" "$NGINX_AVAILABLE/$SITE_NAME" 2>/dev/null | head -1 | sed 's/.*server_name //;s/;//' | xargs | awk '{print $1}')
            elif [ -f "$APACHE_AVAILABLE/$SITE_NAME.conf" ]; then
                DOMAIN=$(grep "ServerName" "$APACHE_AVAILABLE/$SITE_NAME.conf" 2>/dev/null | head -1 | sed 's/.*ServerName //' | xargs)
            fi
            
            if [ -n "$DOMAIN" ] && [[ ! "$DOMAIN" =~ (localhost|test) ]]; then
                COUNT=$((COUNT + 1))
                SSL_SITES[$COUNT]=$SITE_NAME
                SSL_DOMAINS[$COUNT]=$DOMAIN
                
                # Check if SSL already installed
                if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
                    SSL_STATUS="${GREEN}(SSL Installed)${NC}"
                else
                    SSL_STATUS="${RED}(No SSL)${NC}"
                fi
                
                echo -e "  ${COUNT}) ${YELLOW}$SITE_NAME${NC}"
                echo -e "     Domain: $DOMAIN $SSL_STATUS"
                echo ""
            fi
        fi
    done
    
    if [ $COUNT -eq 0 ]; then
        print_error "Tidak ada website dengan domain publik!"
        echo "SSL hanya untuk domain publik (bukan localhost/test)"
        read -p "Tekan Enter untuk kembali..."
        return
    fi
    
    echo -e "${BLUE}══════════════════════════════════════════${NC}"
    echo -n "Pilih nomor website untuk install SSL (1-$COUNT): "
    read SSL_CHOICE
    
    if ! [[ "$SSL_CHOICE" =~ ^[0-9]+$ ]] || [ "$SSL_CHOICE" -lt 1 ] || [ "$SSL_CHOICE" -gt $COUNT ]; then
        print_error "Pilihan tidak valid!"
        sleep 2
        return
    fi
    
    SITE_NAME=${SSL_SITES[$SSL_CHOICE]}
    DOMAIN=${SSL_DOMAINS[$SSL_CHOICE]}
    WWW_DOMAIN="www.$DOMAIN"
    
    echo ""
    echo -e "${CYAN}Installing SSL untuk:${NC}"
    echo -e "  Website: ${YELLOW}$SITE_NAME${NC}"
    echo -e "  Domain: ${YELLOW}$DOMAIN${NC}"
    echo -e "  WWW: ${YELLOW}$WWW_DOMAIN${NC}"
    echo ""
    
    # Detect web server for certbot
    WEBSERVER=$(detect_webserver)
    
    if [ "$WEBSERVER" = "nginx" ]; then
        certbot --nginx -d "$DOMAIN" -d "$WWW_DOMAIN" --non-interactive --agree-tos --email admin@$DOMAIN
    elif [ "$WEBSERVER" = "apache" ]; then
        certbot --apache -d "$DOMAIN" -d "$WWW_DOMAIN" --non-interactive --agree-tos --email admin@$DOMAIN
    else
        certbot certonly --standalone -d "$DOMAIN" -d "$WWW_DOMAIN" --non-interactive --agree-tos --email admin@$DOMAIN
    fi
    
    if [ $? -eq 0 ]; then
        print_status "SSL berhasil diinstall untuk $DOMAIN!"
        print_info "Renew otomatis: certbot renew --dry-run"
    else
        print_error "Gagal install SSL!"
    fi
    
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Function 7: SHOW MAIN MENU
show_menu() {
    print_header
    
    # Show system overview
    WEBSERVER=$(detect_webserver)
    WEBSITE_COUNT=$(ls -d $BASE_DIR/*/ 2>/dev/null | wc -l)
    
    echo -e "${CYAN}📊 SYSTEM OVERVIEW:${NC}"
    echo -e "  Web Server  : ${YELLOW}$WEBSERVER${NC}"
    echo -e "  Total Website: ${GREEN}$WEBSITE_COUNT${NC}"
    echo -e "  IP Address  : ${BLUE}$(hostname -I | cut -d' ' -f1)${NC}"
    echo ""
    
    echo -e "${PURPLE}📋 MAIN MENU:${NC}"
    echo -e "${BLUE}══════════════════════════════════════════${NC}"
    echo -e "  ${GREEN}1)${NC} 📝 Buat Website Baru"
    echo -e "  ${GREEN}2)${NC} 📋 List Semua Website"
    echo -e "  ${GREEN}3)${NC} 🗑️  Hapus Website"
    echo -e "  ${GREEN}4)${NC} 💾 Backup Website"
    echo -e "  ${GREEN}5)${NC} 🔒 Install SSL Certificate"
    echo -e "  ${GREEN}6)${NC} 📊 System Status"
    echo -e "  ${GREEN}7)${NC} ⚙️  Settings"
    echo -e "  ${GREEN}0)${NC} ❌ Keluar"
    echo -e "${BLUE}══════════════════════════════════════════${NC}"
    echo ""
    
    # Show last 3 created websites
    if [ $WEBSITE_COUNT -gt 0 ]; then
        echo -e "${CYAN}📁 WEBSITE TERBARU:${NC}"
        ls -dt $BASE_DIR/*/ | head -3 | while read dir; do
            name=$(basename "$dir")
            size=$(du -sh "$dir" 2>/dev/null | cut -f1)
            echo -e "  ${YELLOW}•${NC} $name (${BLUE}$size${NC})"
        done
        echo ""
    fi
    
    echo -n "Pilih menu [0-7]: "
}

# Function 8: SETTINGS MENU
settings_menu() {
    print_header
    echo -e "${CYAN}⚙️  SETTINGS${NC}"
    echo -e "${BLUE}══════════════════════════════════════════${NC}"
    
    echo -e "  ${GREEN}1)${NC} Install Web Server (Nginx/Apache)"
    echo -e "  ${GREEN}2)${NC} Install PHP"
    echo -e "  ${GREEN}3)${NC} Install MySQL"
    echo -e "  ${GREEN}4)${NC} Install Node.js"
    echo -e "  ${GREEN}5)${NC} Install Certbot (SSL)"
    echo -e "  ${GREEN}6)${NC} Update Script"
    echo -e "  ${GREEN}7)${NC} Kembali ke Menu Utama"
    echo -e "${BLUE}══════════════════════════════════════════${NC}"
    echo -n "Pilih [1-7]: "
    
    read SETTING_CHOICE
    
    case $SETTING_CHOICE in
        1)
            echo ""
            echo -e "${YELLOW}Pilih Web Server:${NC}"
            echo "1) Nginx"
            echo "2) Apache"
            echo "3) Kembali"
            
            read -p "Pilihan: " WS_CHOICE
            
            case $WS_CHOICE in
                1)
                    apt update
                    apt install -y nginx
                    systemctl enable nginx
                    systemctl start nginx
                    print_status "Nginx berhasil diinstall!"
                    ;;
                2)
                    apt update
                    apt install -y apache2
                    systemctl enable apache2
                    systemctl start apache2
                    print_status "Apache berhasil diinstall!"
                    ;;
            esac
            ;;
        2)
            print_status "Menginstall PHP dan extensions..."
            apt update
            apt install -y php-fpm php-mysql php-curl php-gd php-mbstring php-xml php-zip
            print_status "PHP berhasil diinstall!"
            ;;
        3)
            print_status "Menginstall MySQL..."
            apt update
            apt install -y mysql-server
            print_status "MySQL berhasil diinstall!"
            print_info "Jalankan: sudo mysql_secure_installation"
            ;;
        4)
            print_status "Menginstall Node.js..."
            curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
            apt install -y nodejs
            print_status "Node.js berhasil diinstall!"
            ;;
        5)
            print_status "Menginstall Certbot..."
            apt update
            apt install -y certbot python3-certbot-nginx python3-certbot-apache
            print_status "Certbot berhasil diinstall!"
            ;;
        6)
            print_status "Memperbarui script..."
            # This would download latest version from repo
            echo "Fitur update akan datang..."
            ;;
    esac
    
    if [ "$SETTING_CHOICE" -ne 7 ]; then
        read -p "Tekan Enter untuk melanjutkan..."
    fi
}

# Main loop
main() {
    check_root
    check_dependencies
    
    while true; do
        show_menu
        read MENU_CHOICE
        
        case $MENU_CHOICE in
            1) create_website ;;
            2) list_websites ;;
            3) delete_website ;;
            4) quick_backup ;;
            5) install_ssl ;;
            6) system_status ;;
            7) settings_menu ;;
            0)
                print_header
                echo -e "${GREEN}Terima kasih telah menggunakan Website Manager!${NC}"
                echo ""
                exit 0
                ;;
            *)
                print_error "Pilihan tidak valid!"
                sleep 2
                ;;
        esac
    done
}

# Run main function
main
