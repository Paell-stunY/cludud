#!/bin/bash

#############################################
# PTERODACTYL AUTO INSTALLER - PRODUCTION
# 100% WORKING VERSION v4.1
# Panel & Wings Installation + Theme Support
#############################################

set -e

# ===== COLORS =====
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

# ===== FUNCTIONS =====
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_info() { echo -e "${CYAN}[i]${NC} $1"; }

gen_password() { openssl rand -base64 16 | tr -d "=+/" | cut -c1-16; }
gen_email() { echo "pterodactyl$(date +%s | tail -c 6)@gmail.com"; }
gen_db_name() { echo "pterodactyl$(shuf -i 100-999 -n 1)"; }

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
}

show_menu() {
    show_banner
    echo ""
    echo -e "${WHITE}┌────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│${NC}         ${CYAN}🚀 PTERODACTYL & THEME AUTO INSTALLER 🚀${NC}        ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}                  ${MAGENTA}100% WORKING v4.1${NC}                   ${WHITE}│${NC}"
    echo -e "${WHITE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${WHITE}┌─ ${BLUE}PANEL & WINGS${NC} ─────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│${NC}  ${GREEN}[1]${NC} Install Panel"
    echo -e "${WHITE}│${NC}  ${GREEN}[2]${NC} Install Wings"
    echo -e "${WHITE}│${NC}  ${GREEN}[3]${NC} Change DB Host (127.0.0.1 → 0.0.0.0)"
    echo -e "${WHITE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${WHITE}┌─ ${MAGENTA}THEME & CUSTOMIZATION${NC} ──────────────────────────────┐${NC}"
    echo -e "${WHITE}│${NC}  ${BLUE}[4]${NC} Install Pterodactyl Theme"
    echo -e "${WHITE}│${NC}  ${BLUE}[5]${NC} Install Blueprint Framework"
    echo -e "${WHITE}│${NC}  ${BLUE}[6]${NC} Reset Panel (Remove Theme/Tools)"
    echo -e "${WHITE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${WHITE}┌─ ${YELLOW}MANAGEMENT${NC} ─────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│${NC}  ${YELLOW}[7]${NC} Create Node & Location"
    echo -e "${WHITE}│${NC}  ${YELLOW}[8]${NC} Add Admin Account (Hack Back)"
    echo -e "${WHITE}│${NC}  ${YELLOW}[9]${NC} Change VPS Password"
    echo -e "${WHITE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${WHITE}┌─ ${RED}DANGER ZONE${NC} ──────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│${NC}  ${RED}[10]${NC} Uninstall Panel Completely"
    echo -e "${WHITE}│${NC}  ${RED}[12]${NC} Uninstall Wings Completely"
    echo -e "${WHITE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${WHITE}┌─ ${GREEN}FIX / REPAIR${NC} ────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│${NC}  ${GREEN}[11]${NC} 🔧 Fix Panel (Nginx/Login/Session/Permission)"
    echo -e "${WHITE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${WHITE}┌────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│${NC}  ${MAGENTA}[x]${NC} Exit"
    echo -e "${WHITE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -n -e "${WHITE}Pilih opsi [1-12/x]: ${NC}"
}

# ===== INSTALL PANEL =====
install_panel() {
    show_banner
    echo ""
    echo -e "${WHITE}┌─ ${GREEN}INSTALL PTERODACTYL PANEL${NC} ───────────────────────────┐${NC}"
    echo -e "${WHITE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""

    read -p "📍 Domain Panel (ex: panel.example.com): " PANEL_DOMAIN
    read -p "📧 Email Admin (ex: admin@example.com): " PANEL_EMAIL

    if [[ -z "$PANEL_DOMAIN" ]] || [[ -z "$PANEL_EMAIL" ]]; then
        print_error "Domain dan email harus diisi!"
        sleep 2
        install_panel
        return
    fi

    DB_NAME=$(gen_db_name)
    DB_USER="rielliona"
    DB_PASS=$(gen_password)
    ADMIN_USER="admin"
    ADMIN_PASS=$(gen_password)
    CERT_EMAIL=$(gen_email)

    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}🔑 GENERATED CREDENTIALS${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "  📦 Database: ${YELLOW}$DB_NAME${NC}"
    echo -e "  👤 DB User: ${YELLOW}$DB_USER${NC}"
    echo -e "  🔐 DB Pass: ${YELLOW}$DB_PASS${NC}"
    echo -e "  👨 Admin: ${YELLOW}$ADMIN_USER${NC}"
    echo -e "  🔑 Admin Pass: ${YELLOW}$ADMIN_PASS${NC}"
    echo -e "  📧 SSL Email: ${YELLOW}$CERT_EMAIL${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    print_info "Starting Panel Installation..."

    # Pre-cleanup: hapus user & database lama jika ada
    print_info "Membersihkan sisa instalasi lama di MySQL..."
    mysql -e "DROP USER IF EXISTS 'pterodactyl'@'127.0.0.1';" 2>/dev/null || true
    mysql -e "DROP USER IF EXISTS 'pterodactyl'@'localhost';" 2>/dev/null || true
    mysql -e "DROP USER IF EXISTS 'pterodactyl'@'%';" 2>/dev/null || true
    mysql -e "DROP USER IF EXISTS 'rielliona'@'127.0.0.1';" 2>/dev/null || true
    mysql -e "DROP USER IF EXISTS 'rielliona'@'localhost';" 2>/dev/null || true
    mysql -e "DROP USER IF EXISTS 'rielliona'@'%';" 2>/dev/null || true
    mysql -e "DROP DATABASE IF EXISTS $DB_NAME;" 2>/dev/null || true
    # Hapus semua database pterodactyl yang mungkin ada
    for db in $(mysql -e "SHOW DATABASES LIKE 'pterodactyl%';" 2>/dev/null | grep pterodactyl); do
        mysql -e "DROP DATABASE IF EXISTS \`$db\`;" 2>/dev/null || true
    done
    mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true
    print_success "Cleanup MySQL selesai"

    sleep 2

    INPUT_FILE="/tmp/panel_input.txt"
    cat > $INPUT_FILE <<EOF
0
$DB_NAME
$DB_USER
$DB_PASS
Asia/Jakarta
$CERT_EMAIL
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

    echo -e "${CYAN}📥 Downloading official Pterodactyl installer...${NC}"
    bash <(curl -s https://pterodactyl-installer.se) < $INPUT_FILE 2>&1 | tee /tmp/pterodactyl_install.log

    rm -f $INPUT_FILE
    sleep 5

    if [ -d "/var/www/pterodactyl" ] && [ -f "/var/www/pterodactyl/.env" ]; then
        print_success "Panel installation verified!"

        INFO_FILE="/root/pterodactyl_panel_info.txt"
        cat > $INFO_FILE <<EOF
╔════════════════════════════════════════════════════════════════╗
║          PTERODACTYL PANEL - INSTALLATION SUCCESS             ║
╚════════════════════════════════════════════════════════════════╝

🖥️  PANEL URL:
    https://$PANEL_DOMAIN

👤 ADMIN ACCOUNT:
   Username:  $ADMIN_USER
   Password:  $ADMIN_PASS
   Email:     $PANEL_EMAIL

🗄️  DATABASE:
   Name:      $DB_NAME
   User:      $DB_USER
   Password:  $DB_PASS
   Host:      127.0.0.1
   Port:      3306

📧 SSL CERTIFICATE EMAIL:
   $CERT_EMAIL

════════════════════════════════════════════════════════════════
NEXT STEPS:
1. Open https://$PANEL_DOMAIN in browser
2. Login with Admin credentials
3. Go to Admin → Locations → Create Location
4. Go to Admin → Nodes → Create Node
5. Configure Wings on another server

⚠️  SIMPAN INFORMASI INI DI TEMPAT AMAN!
════════════════════════════════════════════════════════════════
EOF

        print_success "Panel info saved to: $INFO_FILE"
        cat $INFO_FILE
    else
        print_error "Panel installation FAILED!"
        tail -50 /tmp/pterodactyl_install.log
    fi

    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
}

# ===== INSTALL WINGS =====
install_wings() {
    show_banner
    echo ""
    echo -e "${WHITE}┌─ ${BLUE}INSTALL PTERODACTYL WINGS${NC} ──────────────────────────┐${NC}"
    echo -e "${WHITE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""

    read -p "📍 Domain Node (ex: node1.example.com): " NODE_DOMAIN
    read -p "📧 Email for SSL (ex: admin@example.com): " NODE_EMAIL

    if [[ -z "$NODE_DOMAIN" ]] || [[ -z "$NODE_EMAIL" ]]; then
        print_error "Domain dan email harus diisi!"
        sleep 2
        install_wings
        return
    fi

    print_info "Starting Wings Installation..."
    sleep 2

    INPUT_FILE="/tmp/wings_input.txt"
    cat > $INPUT_FILE <<EOF
1
y
n
y
$NODE_DOMAIN
y
$NODE_EMAIL
y
EOF

    echo -e "${CYAN}📥 Downloading official Pterodactyl installer...${NC}"
    bash <(curl -s https://pterodactyl-installer.se) < $INPUT_FILE 2>&1 | tee /tmp/wings_install.log

    rm -f $INPUT_FILE
    sleep 5

    if [ -f "/usr/local/bin/wings" ]; then
        print_success "Wings binary installed!"
        mkdir -p /etc/pterodactyl

        echo ""
        echo -e "${MAGENTA}════════════════════════════════════════════════════════════${NC}"
        echo -e "${MAGENTA}🔧 WINGS CONFIGURATION STEPS${NC}"
        echo -e "${MAGENTA}════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "${WHITE}1. Go to Panel → Admin → Nodes → Create New Node${NC}"
        echo -e "${WHITE}2. FQDN: ${CYAN}$NODE_DOMAIN${NC}"
        echo -e "${WHITE}3. Click Configuration tab → Copy the command${NC}"
        echo -e "${WHITE}4. Paste command here:${NC}"
        echo ""

        read -r CONFIG_CMD

        if [[ -n "$CONFIG_CMD" ]]; then
            print_info "Running configuration command..."
            cd /etc/pterodactyl
            eval "$CONFIG_CMD" 2>&1 | tee /tmp/wings_config.log

            # Auto-fix SSL di config.yml
            # Jika SSL cert belum ada, matikan SSL agar wings bisa start
            WINGS_CONFIG="/etc/pterodactyl/config.yml"
            if [ -f "$WINGS_CONFIG" ]; then
                CERT_PATH=$(grep "cert:" "$WINGS_CONFIG" | awk '{print $2}' | tr -d '"')
                if [[ -n "$CERT_PATH" ]] && [[ ! -f "$CERT_PATH" ]]; then
                    print_warning "SSL certificate tidak ditemukan, menonaktifkan SSL sementara..."
                    sed -i '/^api:/,/^[^ ]/{/ssl:/{n;s/enabled: true/enabled: false/}}' "$WINGS_CONFIG"
                    # Cara alternatif yang lebih robust dengan Python
                    python3 -c "
import re
with open('$WINGS_CONFIG', 'r') as f:
    content = f.read()
# Set ssl enabled false di bagian api
content = re.sub(r'(api:.*?ssl:\s*\n\s*)enabled: true', r'\1enabled: false', content, flags=re.DOTALL)
with open('$WINGS_CONFIG', 'w') as f:
    f.write(content)
" 2>/dev/null || true
                    print_success "SSL dinonaktifkan di config.yml"
                    print_warning "Jalankan certbot setelah wings running untuk aktifkan SSL:"
                    echo -e "  ${CYAN}certbot certonly --standalone -d $NODE_DOMAIN${NC}"
                else
                    print_success "SSL certificate ditemukan, SSL tetap aktif"
                fi
            fi

            sleep 2
            systemctl start wings
            sleep 3

            if systemctl is-active --quiet wings; then
                print_success "Wings is RUNNING! ✅"
            else
                print_error "Wings failed to start! Cek log:"
                journalctl -u wings -n 20 --no-pager
            fi
        fi
    else
        print_error "Wings installation FAILED!"
        tail -50 /tmp/wings_install.log
    fi

    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
}

# ===== CHANGE DB HOST =====
change_db_host() {
    show_banner
    echo ""
    echo -e "${WHITE}┌─ ${YELLOW}CHANGE DATABASE HOST${NC} ──────────────────────────────┐${NC}"
    echo -e "${WHITE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""

    ENV_FILE="/var/www/pterodactyl/.env"

    if [ ! -f "$ENV_FILE" ]; then
        print_error "Panel tidak terinstall! File .env tidak ditemukan."
        sleep 2
        return
    fi

    print_info "Backing up .env..."
    cp "$ENV_FILE" "${ENV_FILE}.backup.$(date +%s)"

    print_info "Changing DB_HOST to 0.0.0.0..."
    sed -i 's/DB_HOST=127.0.0.1/DB_HOST=0.0.0.0/g' "$ENV_FILE"

    MARIADB_CONF="/etc/mysql/mariadb.conf.d/50-server.cnf"
    if [ -f "$MARIADB_CONF" ]; then
        cp "$MARIADB_CONF" "${MARIADB_CONF}.backup.$(date +%s)"
        sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' "$MARIADB_CONF"
        print_info "Restarting MariaDB..."
        systemctl restart mariadb
        if systemctl is-active --quiet mariadb; then
            print_success "MariaDB restarted successfully"
        else
            print_error "MariaDB failed to restart!"
        fi
    fi

    DB_USER=$(grep "^DB_USERNAME=" "$ENV_FILE" | cut -d '=' -f2)
    DB_PASS=$(grep "^DB_PASSWORD=" "$ENV_FILE" | cut -d '=' -f2)
    DB_NAME=$(grep "^DB_DATABASE=" "$ENV_FILE" | cut -d '=' -f2)

    mysql -e "DROP USER IF EXISTS '${DB_USER}'@'127.0.0.1';" 2>/dev/null || true
    mysql -e "DROP USER IF EXISTS '${DB_USER}'@'localhost';" 2>/dev/null || true
    mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';" 2>/dev/null
    mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%' WITH GRANT OPTION;" 2>/dev/null
    mysql -e "FLUSH PRIVILEGES;" 2>/dev/null

    print_success "Database host changed to 0.0.0.0! ✅"

    cd /var/www/pterodactyl
    php artisan config:clear
    php artisan cache:clear

    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
}

# ===== INSTALL THEME =====
install_theme() {
    show_banner
    echo ""
    echo -e "${WHITE}┌─ ${BLUE}INSTALL PTERODACTYL THEME${NC} ───────────────────────────┐${NC}"
    echo -e "${WHITE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${CYAN}Downloading theme installer...${NC}"
    bash <(curl -s https://raw.githubusercontent.com/Bangsano/themeinstaller/main/install.sh)
    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
}

# ===== INSTALL BLUEPRINT =====
install_blueprint() {
    show_banner
    echo ""
    echo -e "${WHITE}┌─ ${BLUE}INSTALL BLUEPRINT FRAMEWORK${NC} ──────────────────────────┐${NC}"
    echo -e "${WHITE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""

    if [ ! -d "/var/www/pterodactyl" ]; then
        print_error "Panel tidak terinstall!"
        sleep 2
        return
    fi

    print_info "Installing Blueprint..."
    export DEBIAN_FRONTEND=noninteractive
    export NEEDRESTART_MODE=a

    sudo DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt-get update -y
    sudo DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt-get install -y ca-certificates curl gnupg zip unzip git wget

    DOWNLOAD_URL=$(curl -s https://api.github.com/repos/BlueprintFramework/framework/releases/latest | grep 'browser_download_url' | grep 'release.zip' | cut -d '"' -f 4)

    if [ -z "$DOWNLOAD_URL" ]; then
        print_error "Gagal mendapatkan link download Blueprint!"
        return 1
    fi

    cd /var/www/pterodactyl
    wget -q "$DOWNLOAD_URL" -O /tmp/blueprint.zip
    unzip -oq /tmp/blueprint.zip -d /var/www/pterodactyl
    rm /tmp/blueprint.zip

    print_info "Installing Node.js v22..."
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor --yes | sudo tee /etc/apt/keyrings/nodesource.gpg > /dev/null
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list > /dev/null
    sudo DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt-get update -y
    sudo DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt-get install -y nodejs

    hash -r
    sudo npm i -g yarn

    cd /var/www/pterodactyl
    yarn add cross-env
    yarn install

    print_info "Running blueprint.sh..."
    chmod +x blueprint.sh
    yes | sudo bash blueprint.sh

    print_success "Blueprint installed successfully! ✅"

    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
}

# ===== RESET PANEL =====
reset_panel() {
    show_banner
    echo ""
    echo -e "${WHITE}┌─ ${RED}RESET PANEL${NC} ─────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""

    echo -n -e "${RED}⚠️  This will REMOVE all themes/tools. Are you sure? (y/n): ${NC}"
    read confirmation

    if [[ "$confirmation" != [yY] ]]; then
        print_info "Reset cancelled"
        return
    fi

    if [ ! -d "/var/www/pterodactyl" ]; then
        print_error "Panel tidak terinstall!"
        return
    fi

    cd /var/www/pterodactyl
    php artisan down || true
    print_info "Backup .env..."
    cp .env /tmp/.env.backup
    print_info "Removing all panel files..."
    sudo find . -mindepth 1 -delete
    print_info "Downloading original panel..."
    curl -L https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | sudo tar -xzf - -C /var/www/pterodactyl
    print_info "Restoring .env..."
    mv /tmp/.env.backup .env
    print_info "Installing dependencies..."
    sudo chmod -R 755 storage/* bootstrap/cache/
    sudo chown -R www-data:www-data /var/www/pterodactyl
    curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
    sudo -u www-data env COMPOSER_PROCESS_TIMEOUT=2000 composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist
    sudo -u www-data php artisan migrate --seed --force
    sudo -u www-data php artisan optimize:clear
    sudo -u www-data php artisan view:clear
    sudo -u www-data php artisan config:clear
    sudo -u www-data php artisan up

    print_success "Panel reset successfully! ✅"

    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
}

# ===== CREATE NODE =====
create_node() {
    show_banner
    echo ""
    echo -e "${WHITE}┌─ ${YELLOW}CREATE NODE & LOCATION${NC} ───────────────────────────────┐${NC}"
    echo -e "${WHITE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    bash <(curl -s https://raw.githubusercontent.com/Bangsano/themeinstaller/main/createnode.sh)
    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
}

# ===== ADD ADMIN ACCOUNT =====
add_admin() {
    show_banner
    echo ""
    echo -e "${WHITE}┌─ ${YELLOW}ADD ADMIN ACCOUNT${NC} ───────────────────────────────────┐${NC}"
    echo -e "${WHITE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""

    read -p "Username: " user
    read -sp "Password: " pwhb
    echo ""

    if [[ -z "$user" ]] || [[ -z "$pwhb" ]]; then
        print_error "Username dan password harus diisi!"
        return 1
    fi

    if ! cd /var/www/pterodactyl; then
        print_error "Gagal akses Pterodactyl directory!"
        return 1
    fi

    print_info "Creating admin account..."
    printf 'yes\n%s@admin.com\n%s\n%s\n%s\n%s\n' "$user" "$user" "$user" "$user" "$pwhb" | php artisan p:user:make

    PANEL_URL=$(grep '^APP_URL=' /var/www/pterodactyl/.env | cut -d '=' -f2 | tr -d '"')

    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ ADMIN ACCOUNT CREATED${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo -e "  Username: ${YELLOW}$user${NC}"
    echo -e "  Password: ${YELLOW}(as you entered)${NC}"
    echo -e "  URL: ${YELLOW}$PANEL_URL${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"

    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
}

# ===== CHANGE VPS PASSWORD =====
change_vps_password() {
    show_banner
    echo ""
    echo -e "${WHITE}┌─ ${YELLOW}CHANGE VPS PASSWORD${NC} ─────────────────────────────────┐${NC}"
    echo -e "${WHITE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""

    while true; do
        read -sp "New Password: " pw1
        echo ""
        read -sp "Confirm Password: " pw2
        echo ""
        if [[ "$pw1" == "$pw2" ]]; then
            break
        else
            print_error "Passwords do not match!"
        fi
    done

    print_info "Changing password..."
    passwd <<EOF
$pw1
$pw1
EOF

    if [ $? -eq 0 ]; then
        print_success "VPS password changed successfully! ✅"
    else
        print_error "Failed to change password!"
    fi

    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
}

# ===== UNINSTALL PANEL =====
uninstall_panel() {
    show_banner
    echo ""
    echo -e "${WHITE}┌─ ${RED}UNINSTALL PANEL${NC} ────────────────────────────────────┐${NC}"
    echo -e "${WHITE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""

    echo -n -e "${RED}⚠️  WARNING: This will DELETE everything! Are you sure? (y/n): ${NC}"
    read confirmation

    if [[ "$confirmation" != [yY] ]]; then
        print_info "Uninstall cancelled"
        return
    fi

    print_warning "Starting uninstall process..."

    systemctl stop pteroq 2>/dev/null || true
    systemctl disable pteroq 2>/dev/null || true
    systemctl stop wings 2>/dev/null || true
    systemctl disable wings 2>/dev/null || true

    rm -rf /var/www/pterodactyl
    rm -rf /etc/pterodactyl
    rm -f /usr/local/bin/wings
    rm -f /etc/systemd/system/wings.service
    rm -f /etc/systemd/system/pteroq.service
    rm -f /etc/nginx/sites-enabled/pterodactyl.conf
    rm -f /etc/nginx/sites-available/pterodactyl.conf

    docker stop $(docker ps -aq) 2>/dev/null || true
    docker rm $(docker ps -aq) 2>/dev/null || true

    systemctl daemon-reload
    systemctl restart nginx 2>/dev/null || true

    print_success "Panel uninstalled successfully! ✅"

    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
}

# ===== FIX PANEL =====
fix_panel() {
    show_banner
    echo ""
    echo -e "${WHITE}┌─ ${GREEN}🔧 FIX / REPAIR PTERODACTYL PANEL${NC} ──────────────────┐${NC}"
    echo -e "${WHITE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${CYAN}Fixes yang akan dilakukan:${NC}"
    echo -e "  • Nginx welcome page → panel pterodactyl"
    echo -e "  • CSRF / login error"
    echo -e "  • Session driver & secure cookie"
    echo -e "  • File permissions"
    echo -e "  • Clear semua cache Laravel"
    echo ""

    PANEL_DIR="/var/www/pterodactyl"
    NGINX_AVAILABLE="/etc/nginx/sites-available/pterodactyl.conf"
    NGINX_ENABLED="/etc/nginx/sites-enabled/pterodactyl.conf"

    # Detect PHP version
    PHP_VERSION=$(php -v 2>/dev/null | head -1 | grep -oP 'PHP \K[0-9]+\.[0-9]+')
    if [ -z "$PHP_VERSION" ]; then
        print_error "PHP tidak ditemukan!"
        echo -e "${YELLOW}Press Enter to continue...${NC}"
        read
        return
    fi
    PHP_FPM_SOCK="/run/php/php${PHP_VERSION}-fpm.sock"
    print_success "Detected PHP version: ${PHP_VERSION}"

    # Get domain
    if [ -f "$PANEL_DIR/.env" ]; then
        DOMAIN=$(grep APP_URL "$PANEL_DIR/.env" | sed 's/APP_URL=//;s/"//g' | sed 's|https\?://||')
    fi
    if [ -z "$DOMAIN" ]; then
        read -p "📍 Masukkan domain panel (ex: panel.example.com): " DOMAIN
    fi
    print_success "Domain: ${DOMAIN}"
    echo ""

    # FIX 1: Nginx config
    echo -e "${YELLOW}[1] Fixing Nginx configuration...${NC}"
    cat > "$NGINX_AVAILABLE" <<EOF
server {
    listen 80;
    server_name ${DOMAIN};

    root /var/www/pterodactyl/public;
    index index.php;

    access_log /var/log/nginx/pterodactyl.app-access.log;
    error_log  /var/log/nginx/pterodactyl.app-error.log error;

    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;

    location ~* \.(css|js|gif|png|jpeg|jpg|ico|woff|woff2)$ {
        expires 365d;
    }

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:${PHP_FPM_SOCK};
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }
}
EOF

    rm -f /etc/nginx/sites-enabled/default
    if [ ! -L "$NGINX_ENABLED" ]; then
        ln -s "$NGINX_AVAILABLE" "$NGINX_ENABLED"
    fi
    print_success "Nginx config fixed & default page removed"

    # FIX 2: .env fixes
    echo -e "${YELLOW}[2] Fixing .env settings...${NC}"
    if [ -f "$PANEL_DIR/.env" ]; then
        sed -i "s|APP_URL=.*|APP_URL=\"http://${DOMAIN}\"|" "$PANEL_DIR/.env"
        sed -i 's/SESSION_SECURE_COOKIE=true/SESSION_SECURE_COOKIE=false/' "$PANEL_DIR/.env"
        sed -i 's/SESSION_DRIVER=redis/SESSION_DRIVER=file/' "$PANEL_DIR/.env"
        print_success "APP_URL, SESSION_DRIVER, SESSION_SECURE_COOKIE fixed"
    else
        print_warning ".env tidak ditemukan, skip..."
    fi

    # FIX 3: Permissions
    echo -e "${YELLOW}[3] Fixing file permissions...${NC}"
    chown -R www-data:www-data "$PANEL_DIR"
    chmod -R 755 "$PANEL_DIR/storage" "$PANEL_DIR/bootstrap/cache"
    print_success "Permissions fixed"

    # FIX 4: Clear cache
    echo -e "${YELLOW}[4] Clearing Laravel cache...${NC}"
    cd "$PANEL_DIR"
    php artisan cache:clear
    php artisan config:clear
    php artisan route:clear
    php artisan view:clear
    print_success "Cache cleared"

    # FIX 5: Restart services
    echo -e "${YELLOW}[5] Restarting services...${NC}"
    nginx -t && systemctl restart nginx
    systemctl restart "php${PHP_VERSION}-fpm"
    print_success "Nginx & PHP-FPM restarted"

    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ Semua fix berhasil diterapkan!${NC}"
    echo -e "${GREEN}🌐 Buka browser: http://${DOMAIN}${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"

    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
}

# ===== UNINSTALL WINGS =====
uninstall_wings() {
    show_banner
    echo ""
    echo -e "${WHITE}┌─ ${RED}UNINSTALL WINGS${NC} ────────────────────────────────────┐${NC}"
    echo -e "${WHITE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""

    echo -n -e "${RED}⚠️  WARNING: Wings dan semua konfigurasinya akan dihapus! Lanjutkan? (y/n): ${NC}"
    read confirmation

    if [[ "$confirmation" != [yY] ]]; then
        print_info "Uninstall Wings dibatalkan"
        sleep 1
        return
    fi

    print_warning "Menghentikan Wings..."
    systemctl stop wings 2>/dev/null || true
    systemctl disable wings 2>/dev/null || true
    print_success "Wings service dihentikan"

    print_warning "Menghapus Wings binary..."
    rm -f /usr/local/bin/wings
    print_success "Wings binary dihapus"

    print_warning "Menghapus Wings service..."
    rm -f /etc/systemd/system/wings.service
    systemctl daemon-reload
    print_success "Wings service dihapus"

    print_warning "Menghapus konfigurasi Wings..."
    rm -rf /etc/pterodactyl
    print_success "Konfigurasi Wings dihapus"

    echo -n -e "${YELLOW}Hapus juga data server (volumes, backups, archives)? (y/n): ${NC}"
    read del_data

    if [[ "$del_data" == [yY] ]]; then
        print_warning "Menghapus data server..."
        rm -rf /var/lib/pterodactyl
        rm -rf /tmp/pterodactyl
        print_success "Data server dihapus"
    else
        print_info "Data server dipertahankan di /var/lib/pterodactyl"
    fi

    print_warning "Membersihkan Docker containers..."
    docker stop $(docker ps -aq) 2>/dev/null || true
    docker rm $(docker ps -aq) 2>/dev/null || true
    print_success "Docker containers dibersihkan"

    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ Wings berhasil di-uninstall!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"

    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
}

# ===== ROOT CHECK =====
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}This script must be run as root!${NC}"
    echo "Usage: sudo bash installpanel.sh"
    exit 1
fi

# ===== MAIN LOOP =====
while true; do
    show_menu
    read choice
    case $choice in
        1) install_panel ;;
        2) install_wings ;;
        3) change_db_host ;;
        4) install_theme ;;
        5) install_blueprint ;;
        6) reset_panel ;;
        7) create_node ;;
        8) add_admin ;;
        9) change_vps_password ;;
        10) uninstall_panel ;;
        11) fix_panel ;;
        12) uninstall_wings ;;
        x|X)
            clear
            show_banner
            echo ""
            echo -e "${GREEN}Terima kasih telah menggunakan Pterodactyl Auto Installer!${NC}"
            echo -e "${CYAN}Copyright © Paell-stunY & Rielliona${NC}"
            echo ""
            exit 0
            ;;
        *) print_error "Invalid choice!"; sleep 2 ;;
    esac
done
