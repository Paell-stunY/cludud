#!/bin/bash

# Pterodactyl Auto Installer
# Using official pterodactyl-installer script
# Modified by Rielliona

set -e

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Fungsi untuk print dengan warna
print_success() {
    echo -e "${GREEN}[✓] $1${NC}"
}

print_error() {
    echo -e "${RED}[✗] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

print_info() {
    echo -e "${CYAN}[i] $1${NC}"
}

# Fungsi untuk banner
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "  ██████╗ ██╗███████╗██╗     ██╗     ██╗ ██████╗ ███╗   ██╗ █████╗ "
    echo "  ██╔══██╗██║██╔════╝██║     ██║     ██║██╔═══██╗████╗  ██║██╔══██╗"
    echo "  ██████╔╝██║█████╗  ██║     ██║     ██║██║   ██║██╔██╗ ██║███████║"
    echo "  ██╔══██╗██║██╔══╝  ██║     ██║     ██║██║   ██║██║╚██╗██║██╔══██║"
    echo "  ██║  ██║██║███████╗███████╗███████╗██║╚██████╔╝██║ ╚████║██║  ██║"
    echo "  ╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝"
    echo -e "${NC}"
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC}          ${YELLOW}PTERODACTYL AUTO INSTALLER${NC}                          ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}          ${GREEN}Copyright © Riellionasa${NC}                                 ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Fungsi untuk menu utama
show_menu() {
    show_banner
    echo -e "${CYAN}Pilih opsi instalasi:${NC}"
    echo ""
    echo -e "  ${GREEN}[1]${NC} Install Pterodactyl Panel"
    echo -e "  ${BLUE}[2]${NC} Install Pterodactyl Wings"
    echo -e "  ${YELLOW}[3]${NC} Change Database Host (127.0.0.1 → 0.0.0.0)"
    echo -e "  ${MAGENTA}[4]${NC} Uninstall Panel/Wings"
    echo -e "  ${RED}[5]${NC} Exit"
    echo ""
    echo -n "Masukkan pilihan [1-5]: "
}

# Fungsi install panel
install_panel() {
    show_banner
    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}    PTERODACTYL PANEL INSTALLATION${NC}"
    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    echo ""
    
    # Input konfigurasi dari user
    read -p "Masukkan domain panel (contoh: panel.domain.com): " PANEL_DOMAIN
    read -p "Masukkan email: " PANEL_EMAIL
    read -p "Database name (default: panel): " DB_NAME
    DB_NAME=${DB_NAME:-panel}
    read -p "Database username (default: pterodactyl): " DB_USER
    DB_USER=${DB_USER:-pterodactyl}
    read -sp "Database password (kosongkan untuk random): " DB_PASS
    echo ""
    read -p "Username admin (default: admin): " ADMIN_USER
    ADMIN_USER=${ADMIN_USER:-admin}
    read -sp "Password admin: " ADMIN_PASS
    echo ""
    
    # Validasi input
    if [[ -z "$PANEL_DOMAIN" ]] || [[ -z "$PANEL_EMAIL" ]] || [[ -z "$ADMIN_PASS" ]]; then
        print_error "Domain, email, dan password admin tidak boleh kosong!"
        sleep 2
        install_panel
        return
    fi
    
    print_info "Menjalankan official pterodactyl-installer..."
    echo ""
    
    # Buat file untuk auto-input
    cat > /tmp/panel_input.txt <<EOF
0
$DB_NAME
$DB_USER
$DB_PASS
Asia/Jakarta
$PANEL_EMAIL
$PANEL_EMAIL
$ADMIN_USER
admin
admin
$ADMIN_PASS
$PANEL_DOMAIN
y
y
y
y
no
y
EOF
    
    # Jalankan installer dengan auto-input
    bash <(curl -s https://pterodactyl-installer.se) < /tmp/panel_input.txt
    
    # Hapus file input
    rm -f /tmp/panel_input.txt
    
    # Setelah instalasi selesai
    echo ""
    print_success "Instalasi Panel selesai!"
    print_success "Panel URL: https://$PANEL_DOMAIN"
    print_success "Admin Username: $ADMIN_USER"
    print_success "Admin Email: $PANEL_EMAIL"
    
    # Simpan kredensial
    INFO_FILE="/root/pterodactyl_panel_info.txt"
    cat > $INFO_FILE <<EOF
========================================
PTERODACTYL PANEL - INFORMASI LOGIN
========================================

PANEL URL: https://$PANEL_DOMAIN

ADMIN PANEL:
Username: $ADMIN_USER
Email: $PANEL_EMAIL
Password: $ADMIN_PASS

DATABASE:
Database: $DB_NAME
Username: $DB_USER
Password: $DB_PASS

========================================
Simpan informasi ini dengan aman!
========================================
EOF
    
    print_warning "Kredensial disimpan di: $INFO_FILE"
    
    # Tanya apakah ingin ganti database host
    echo ""
    echo -e "${YELLOW}Apakah ingin mengubah database host dari 127.0.0.1 ke 0.0.0.0? (y/n)${NC}"
    read -r CHANGE_HOST
    
    if [[ "$CHANGE_HOST" =~ [Yy] ]]; then
        change_db_host
    fi
    
    echo ""
    echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
    read
    main_menu
}

# Fungsi install wings
install_wings() {
    show_banner
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}    PTERODACTYL WINGS INSTALLATION${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo ""
    
    # Input konfigurasi dari user
    read -p "Masukkan domain node (contoh: node1.domain.com): " NODE_DOMAIN
    read -p "Masukkan email untuk Let's Encrypt: " NODE_EMAIL
    
    # Validasi input
    if [[ -z "$NODE_DOMAIN" ]] || [[ -z "$NODE_EMAIL" ]]; then
        print_error "Domain dan email tidak boleh kosong!"
        sleep 2
        install_wings
        return
    fi
    
    print_info "Menjalankan official pterodactyl-installer..."
    echo ""
    
    # Buat file untuk auto-input installer wings
    cat > /tmp/wings_input.txt <<EOF
1
y
n
y
$NODE_DOMAIN
y
$NODE_EMAIL
y
EOF
    
    # Jalankan installer dengan auto-input
    bash <(curl -s https://pterodactyl-installer.se) < /tmp/wings_input.txt
    
    # Hapus file input
    rm -f /tmp/wings_input.txt
    
    # Cek apakah direktori pterodactyl sudah dibuat oleh installer
    if [ ! -d "/etc/pterodactyl" ]; then
        print_warning "Direktori /etc/pterodactyl belum ada, membuat..."
        mkdir -p /etc/pterodactyl
    fi
    
    # Setelah instalasi selesai
    clear
    show_banner
    echo ""
    print_success "Instalasi Wings selesai!"
    echo ""
    print_warning "═══════════════════════════════════════════════════════════"
    print_warning "LANGKAH SELANJUTNYA - KONFIGURASI WINGS:"
    print_warning "═══════════════════════════════════════════════════════════"
    echo ""
    echo "1. Login ke Panel Pterodactyl"
    echo "2. Buka menu: Admin → Locations → Buat location baru"
    echo "3. Buka menu: Admin → Nodes → Buat node baru"
    echo "4. Isi informasi node:"
    echo "   - FQDN: $NODE_DOMAIN"
    echo "   - Scheme: HTTPS"
    echo "5. Setelah node dibuat, klik tab 'Configuration'"
    echo "6. Klik tombol 'Generate Token'"
    echo "7. Copy command yang muncul"
    echo ""
    echo -e "${YELLOW}Contoh command:${NC}"
    echo "cd /etc/pterodactyl && sudo wings configure --panel-url https://panel.domain.com --token ptla_xxxxx --node 1"
    echo ""
    print_warning "═══════════════════════════════════════════════════════════"
    echo ""
    echo -e "${YELLOW}Paste command dari panel di bawah ini:${NC}"
    read -r WINGS_COMMAND
    
    # Validasi command
    if [[ -z "$WINGS_COMMAND" ]]; then
        print_error "Command tidak boleh kosong!"
        echo ""
        echo "Jalankan manual dengan command dari panel, lalu:"
        echo "  systemctl start wings"
        echo ""
        echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
        read
        main_menu
        return
    fi
    
    # Jalankan command wings configure
    print_info "Menjalankan wings configure..."
    
    # Extract komponen dari command
    # Command format: cd /etc/pterodactyl && sudo wings configure --panel-url URL --token TOKEN --node ID
    if [[ "$WINGS_COMMAND" =~ --panel-url[[:space:]]+([^[:space:]]+) ]]; then
        PANEL_URL="${BASH_REMATCH[1]}"
    fi
    
    if [[ "$WINGS_COMMAND" =~ --token[[:space:]]+([^[:space:]]+) ]]; then
        TOKEN="${BASH_REMATCH[1]}"
    fi
    
    if [[ "$WINGS_COMMAND" =~ --node[[:space:]]+([^[:space:]]+) ]]; then
        NODE_ID="${BASH_REMATCH[1]}"
    fi
    
    # Validasi parameter
    if [[ -z "$PANEL_URL" ]] || [[ -z "$TOKEN" ]] || [[ -z "$NODE_ID" ]]; then
        print_error "Command tidak valid! Pastikan format benar."
        echo ""
        echo "Format yang benar:"
        echo "cd /etc/pterodactyl && sudo wings configure --panel-url https://panel.com --token ptla_xxx --node 1"
        echo ""
        echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
        read
        main_menu
        return
    fi
    
    # Pindah ke direktori pterodactyl dan jalankan wings configure
    cd /etc/pterodactyl || {
        print_error "Direktori /etc/pterodactyl tidak ada!"
        echo ""
        echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
        read
        main_menu
        return
    }
    
    # Cek apakah wings binary ada
    if [ ! -f "/usr/local/bin/wings" ]; then
        print_error "Wings binary tidak ditemukan di /usr/local/bin/wings"
        print_warning "Installer mungkin gagal. Coba install ulang Wings."
        echo ""
        echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
        read
        main_menu
        return
    fi
    
    # Jalankan wings configure dengan parameter yang di-extract (gunakan full path)
    /usr/local/bin/wings configure --panel-url "$PANEL_URL" --token "$TOKEN" --node "$NODE_ID"
    
    CONFIGURE_STATUS=$?
    
    if [ $CONFIGURE_STATUS -eq 0 ]; then
        print_success "Konfigurasi Wings berhasil!"
        
        # Cek apakah config.yml sudah dibuat
        if [ -f "/etc/pterodactyl/config.yml" ]; then
            print_success "File config.yml berhasil dibuat!"
        else
            print_error "File config.yml tidak ditemukan!"
            echo ""
            echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
            read
            main_menu
            return
        fi
    else
        print_error "Konfigurasi Wings gagal!"
        echo ""
        echo "Coba jalankan manual:"
        echo "  cd /etc/pterodactyl"
        echo "  /usr/local/bin/wings configure --panel-url $PANEL_URL --token $TOKEN --node $NODE_ID"
        echo ""
        echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
        read
        main_menu
        return
    fi
    
    # Start Wings
    print_info "Starting Wings dengan systemctl..."
    systemctl start wings
    
    # Tunggu beberapa detik
    sleep 3
    
    # Enable wings agar auto start saat boot
    systemctl enable wings 2>/dev/null
    
    # Cek status Wings
    if systemctl is-active --quiet wings; then
        print_success "Wings berhasil dijalankan!"
    else
        print_error "Wings gagal dijalankan!"
        print_warning "Cek log dengan: journalctl -u wings -f"
        echo ""
        echo "Atau coba start manual dengan: systemctl start wings"
        echo ""
        echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
        read
        main_menu
        return
    fi
    
    # Tampilkan hasil
    clear
    show_banner
    echo ""
    print_success "═══════════════════════════════════════"
    print_success "   INSTALASI WINGS SELESAI!"
    print_success "═══════════════════════════════════════"
    echo ""
    print_success "Domain Node: $NODE_DOMAIN"
    print_success "Status Wings: $(systemctl is-active wings)"
    echo ""
    print_warning "Perintah berguna:"
    echo "  - Cek status:  systemctl status wings"
    echo "  - Restart:     systemctl restart wings"
    echo "  - Stop:        systemctl stop wings"
    echo "  - Log:         journalctl -u wings -f"
    echo ""
    print_warning "PENTING:"
    echo "  - Port 8080 dan 2022 harus terbuka di firewall"
    echo "  - Domain $NODE_DOMAIN harus mengarah ke IP server ini"
    echo ""
    echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
    read
    main_menu
}

# Fungsi untuk mengganti database host dari 127.0.0.1 ke 0.0.0.0
change_db_host() {
    show_banner
    echo -e "${YELLOW}═══════════════════════════════════════${NC}"
    echo -e "${YELLOW}    CHANGE DATABASE HOST${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════${NC}"
    echo ""
    
    print_warning "Mengubah database host dari 127.0.0.1 ke 0.0.0.0..."
    echo ""
    
    # File .env pterodactyl
    ENV_FILE="/var/www/pterodactyl/.env"
    
    if [ ! -f "$ENV_FILE" ]; then
        print_error "File .env tidak ditemukan!"
        print_error "Pastikan Panel sudah terinstall."
        echo ""
        echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
        read
        return
    fi
    
    # Backup file .env
    print_info "Backup file .env..."
    cp "$ENV_FILE" "${ENV_FILE}.backup.$(date +%Y%m%d%H%M%S)"
    
    # Ganti DB_HOST dari 127.0.0.1 ke 0.0.0.0
    if grep -q "DB_HOST=127.0.0.1" "$ENV_FILE"; then
        sed -i 's/DB_HOST=127.0.0.1/DB_HOST=0.0.0.0/g' "$ENV_FILE"
        print_success "DB_HOST berhasil diubah ke 0.0.0.0"
    else
        print_warning "DB_HOST bukan 127.0.0.1 atau sudah diubah sebelumnya"
    fi
    
    # Konfigurasi MariaDB untuk listen pada 0.0.0.0
    print_info "Konfigurasi MariaDB..."
    
    MARIADB_CONF="/etc/mysql/mariadb.conf.d/50-server.cnf"
    
    if [ -f "$MARIADB_CONF" ]; then
        # Backup config
        cp "$MARIADB_CONF" "${MARIADB_CONF}.backup.$(date +%Y%m%d%H%M%S)"
        
        # Ubah bind-address
        if grep -q "bind-address.*=.*127.0.0.1" "$MARIADB_CONF"; then
            sed -i 's/bind-address.*=.*127.0.0.1/bind-address = 0.0.0.0/g' "$MARIADB_CONF"
            print_success "MariaDB bind-address berhasil diubah ke 0.0.0.0"
        else
            print_warning "bind-address tidak ditemukan atau sudah diubah"
        fi
        
        # Restart MariaDB
        print_info "Restart MariaDB..."
        systemctl restart mariadb
        
        if systemctl is-active --quiet mariadb; then
            print_success "MariaDB berhasil direstart"
        else
            print_error "MariaDB gagal restart!"
        fi
    else
        print_error "File konfigurasi MariaDB tidak ditemukan!"
    fi
    
    # Update user database untuk allow remote connection
    print_info "Update database user permissions..."
    
    # Ambil database credentials dari .env
    DB_DATABASE=$(grep "^DB_DATABASE=" "$ENV_FILE" | cut -d '=' -f2)
    DB_USERNAME=$(grep "^DB_USERNAME=" "$ENV_FILE" | cut -d '=' -f2)
    DB_PASSWORD=$(grep "^DB_PASSWORD=" "$ENV_FILE" | cut -d '=' -f2)
    
    if [[ -n "$DB_USERNAME" ]] && [[ -n "$DB_PASSWORD" ]]; then
        # Hapus user lama (127.0.0.1)
        mysql -e "DROP USER IF EXISTS '${DB_USERNAME}'@'127.0.0.1';" 2>/dev/null || true
        
        # Buat user baru dengan % (allow all hosts)
        mysql -e "CREATE USER IF NOT EXISTS '${DB_USERNAME}'@'%' IDENTIFIED BY '${DB_PASSWORD}';" 2>/dev/null
        mysql -e "GRANT ALL PRIVILEGES ON ${DB_DATABASE}.* TO '${DB_USERNAME}'@'%' WITH GRANT OPTION;" 2>/dev/null
        mysql -e "FLUSH PRIVILEGES;" 2>/dev/null
        
        print_success "Database user berhasil diupdate untuk remote access"
    else
        print_error "Tidak dapat membaca kredensial database dari .env"
    fi
    
    # Clear cache Laravel
    print_info "Clear cache Laravel..."
    cd /var/www/pterodactyl
    php artisan config:clear
    php artisan cache:clear
    
    echo ""
    print_success "═══════════════════════════════════════"
    print_success "  Database Host berhasil diubah!"
    print_success "═══════════════════════════════════════"
    echo ""
    print_warning "PENTING:"
    echo "  - Database sekarang listen pada 0.0.0.0"
    echo "  - Pastikan firewall dikonfigurasi dengan benar"
    echo "  - Port MySQL (3306) sekarang dapat diakses dari luar"
    echo "  - Gunakan dengan hati-hati untuk keamanan"
    echo ""
    
    if [ -f "$ENV_FILE" ]; then
        print_info "Konfigurasi database saat ini:"
        grep "^DB_" "$ENV_FILE"
    fi
    
    echo ""
}

# Fungsi uninstall panel/wings
uninstall_pterodactyl() {
    show_banner
    echo -e "${MAGENTA}═══════════════════════════════════════${NC}"
    echo -e "${MAGENTA}    UNINSTALL PANEL/WINGS${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════${NC}"
    echo ""
    
    print_warning "Ini akan menghapus Pterodactyl Panel dan/atau Wings dari server!"
    print_warning "Pastikan Anda sudah backup data penting!"
    echo ""
    
    # Deteksi instalasi
    PANEL_DETECTED=false
    WINGS_DETECTED=false
    
    if [ -d "/var/www/pterodactyl" ]; then
        PANEL_DETECTED=true
        print_info "Panel terdeteksi terinstall"
    fi
    
    if [ -f "/usr/local/bin/wings" ]; then
        WINGS_DETECTED=true
        print_info "Wings terdeteksi terinstall"
    fi
    
    if [ "$PANEL_DETECTED" = false ] && [ "$WINGS_DETECTED" = false ]; then
        print_error "Tidak ada instalasi Panel atau Wings yang terdeteksi!"
        echo ""
        echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
        read
        main_menu
        return
    fi
    
    echo ""
    print_warning "Apa yang ingin di-uninstall?"
    echo ""
    
    UNINSTALL_PANEL=false
    UNINSTALL_WINGS=false
    
    # Tanya uninstall panel
    if [ "$PANEL_DETECTED" = true ]; then
        echo -e "${YELLOW}Uninstall Panel? (y/n):${NC}"
        read -r REMOVE_PANEL
        if [[ "$REMOVE_PANEL" =~ [Yy] ]]; then
            UNINSTALL_PANEL=true
        fi
    fi
    
    # Tanya uninstall wings
    if [ "$WINGS_DETECTED" = true ]; then
        echo -e "${YELLOW}Uninstall Wings? ${RED}(SEMUA SERVER AKAN DIHAPUS!)${NC} ${YELLOW}(y/n):${NC}"
        read -r REMOVE_WINGS
        if [[ "$REMOVE_WINGS" =~ [Yy] ]]; then
            UNINSTALL_WINGS=true
        fi
    fi
    
    # Konfirmasi
    echo ""
    print_warning "═══════════════════════════════════════"
    print_warning "Konfirmasi Uninstall:"
    echo "  - Uninstall Panel: $UNINSTALL_PANEL"
    echo "  - Uninstall Wings: $UNINSTALL_WINGS"
    print_warning "═══════════════════════════════════════"
    echo ""
    echo -e "${RED}Lanjutkan uninstall? (y/n):${NC}"
    read -r CONFIRM_UNINSTALL
    
    if [[ ! "$CONFIRM_UNINSTALL" =~ [Yy] ]]; then
        print_info "Uninstall dibatalkan"
        echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
        read
        main_menu
        return
    fi
    
    # Uninstall Panel
    if [ "$UNINSTALL_PANEL" = true ]; then
        echo ""
        print_warning "Menghapus Panel..."
        
        # Stop services
        print_info "Stop panel services..."
        systemctl stop pteroq 2>/dev/null || true
        systemctl disable pteroq 2>/dev/null || true
        
        # Remove panel files
        print_info "Menghapus file panel..."
        rm -rf /var/www/pterodactyl
        
        # Remove nginx config
        print_info "Menghapus konfigurasi nginx..."
        rm -f /etc/nginx/sites-enabled/pterodactyl.conf
        rm -f /etc/nginx/sites-available/pterodactyl.conf
        systemctl reload nginx 2>/dev/null || true
        
        # Remove cron jobs
        print_info "Menghapus cron jobs..."
        crontab -l | grep -v 'pterodactyl' | crontab - 2>/dev/null || true
        
        # Remove systemd service
        rm -f /etc/systemd/system/pteroq.service
        systemctl daemon-reload
        
        print_success "Panel berhasil dihapus!"
        
        # Tanya hapus database
        echo ""
        echo -e "${YELLOW}Apakah ingin menghapus database panel? (y/n):${NC}"
        read -r REMOVE_DB
        
        if [[ "$REMOVE_DB" =~ [Yy] ]]; then
            # List databases
            print_info "List database yang tersedia:"
            mysql -e "SHOW DATABASES;" | grep -v "Database\|information_schema\|performance_schema\|mysql\|sys"
            echo ""
            read -p "Masukkan nama database yang akan dihapus (kosongkan untuk skip): " DB_NAME
            
            if [[ -n "$DB_NAME" ]]; then
                mysql -e "DROP DATABASE IF EXISTS ${DB_NAME};" 2>/dev/null
                print_success "Database ${DB_NAME} berhasil dihapus!"
            else
                print_info "Skip penghapusan database"
            fi
            
            # Tanya hapus user
            echo ""
            echo -e "${YELLOW}Apakah ingin menghapus database user? (y/n):${NC}"
            read -r REMOVE_USER
            
            if [[ "$REMOVE_USER" =~ [Yy] ]]; then
                print_info "List database user yang tersedia:"
                mysql -e "SELECT User, Host FROM mysql.user;" | grep -v "User\|root\|mysql.sys\|mysql.infoschema"
                echo ""
                read -p "Masukkan nama user yang akan dihapus (kosongkan untuk skip): " DB_USER
                
                if [[ -n "$DB_USER" ]]; then
                    mysql -e "DROP USER IF EXISTS '${DB_USER}'@'%';" 2>/dev/null || true
                    mysql -e "DROP USER IF EXISTS '${DB_USER}'@'localhost';" 2>/dev/null || true
                    mysql -e "DROP USER IF EXISTS '${DB_USER}'@'127.0.0.1';" 2>/dev/null || true
                    mysql -e "FLUSH PRIVILEGES;" 2>/dev/null
                    print_success "User ${DB_USER} berhasil dihapus!"
                else
                    print_info "Skip penghapusan user"
                fi
            fi
        fi
    fi
    
    # Uninstall Wings
    if [ "$UNINSTALL_WINGS" = true ]; then
        echo ""
        print_warning "Menghapus Wings..."
        
        # Stop wings service
        print_info "Stop wings service..."
        systemctl stop wings 2>/dev/null || true
        systemctl disable wings 2>/dev/null || true
        
        # Remove wings files
        print_info "Menghapus file wings..."
        rm -f /usr/local/bin/wings
        rm -rf /etc/pterodactyl
        
        # Remove systemd service
        rm -f /etc/systemd/system/wings.service
        systemctl daemon-reload
        
        # Tanya hapus Docker containers
        echo ""
        echo -e "${RED}PERINGATAN: Hapus semua Docker containers dan volumes? (y/n):${NC}"
        read -r REMOVE_DOCKER
        
        if [[ "$REMOVE_DOCKER" =~ [Yy] ]]; then
            print_info "Menghapus Docker containers..."
            docker stop $(docker ps -aq) 2>/dev/null || true
            docker rm $(docker ps -aq) 2>/dev/null || true
            
            print_info "Menghapus Docker volumes..."
            docker volume rm $(docker volume ls -q) 2>/dev/null || true
            
            print_success "Docker containers dan volumes berhasil dihapus!"
        else
            print_info "Docker containers dan volumes tidak dihapus"
        fi
        
        print_success "Wings berhasil dihapus!"
    fi
    
    # Selesai
    echo ""
    print_success "═══════════════════════════════════════"
    print_success "   UNINSTALL SELESAI!"
    print_success "═══════════════════════════════════════"
    echo ""
    
    echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
    read
    main_menu
}

# Fungsi menu utama
main_menu() {
    while true; do
        show_menu
        read choice
        case $choice in
            1)
                install_panel
                ;;
            2)
                install_wings
                ;;
            3)
                change_db_host
                echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
                read
                ;;
            4)
                uninstall_pterodactyl
                ;;
            5)
                clear
                echo -e "${GREEN}Terima kasih telah menggunakan Pterodactyl Auto Installer!${NC}"
                echo -e "${CYAN}Copyright © Rielliona${NC}"
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

# Cek apakah dijalankan sebagai root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Script ini harus dijalankan sebagai root!${NC}"
    echo "Gunakan: sudo bash $0"
    exit 1
fi

# Jalankan menu utama
main_menu
