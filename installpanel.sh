#!/bin/bash

#############################################
# PTERODACTYL AUTO INSTALLER - PRODUCTION
# 100% WORKING VERSION
# Panel & Wings Installation Script
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

gen_password() {
    openssl rand -base64 16 | tr -d "=+/" | cut -c1-16
}

gen_email() {
    echo "pterodactyl$(date +%s | tail -c 6)@gmail.com"
}

gen_db_name() {
    echo "pterodactyl$(shuf -i 100-999 -n 1)"
}

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
    echo ""
    echo -e "${MAGENTA}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC}                  ${WHITE}🚀 PTERODACTYL AUTO INSTALLER 🚀${NC}                  ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}                    ${CYAN}100% WORKING VERSION v3.0${NC}                        ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}                   ${GREEN}Copyright © Paell-stunY & Rielliona${NC}               ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_menu() {
    show_banner
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "                      ${CYAN}Pilih opsi instalasi di bawah:${NC}"
    echo ""
    echo -e "  ${GREEN}┌────────────────────────���────────────────┐${NC}"
    echo -e "  ${GREEN}│${NC}  ${WHITE}[1]${NC} ${BLUE}🖥️  Install Panel${NC}${GREEN}                   │${NC}"
    echo -e "  ${GREEN}│${NC}     ${CYAN}Instalasi Panel Pterodactyl Lengkap${NC}  ${GREEN}│${NC}"
    echo -e "  ${GREEN}└─────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "  ${BLUE}┌─────────────────────────────────────────┐${NC}"
    echo -e "  ${BLUE}│${NC}  ${WHITE}[2]${NC} ${MAGENTA}🪶 Install Wings${NC}${BLUE}                   │${NC}"
    echo -e "  ${BLUE}│${NC}     ${CYAN}Instalasi Wings Node Daemon${NC}          ${BLUE}│${NC}"
    echo -e "  ${BLUE}└─────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "  ${YELLOW}┌─────────────────────────────────────────┐${NC}"
    echo -e "  ${YELLOW}│${NC}  ${WHITE}[3]${NC} ${RED}🔄 Change DB Host${NC}${YELLOW}                 │${NC}"
    echo -e "  ${YELLOW}│${NC}     ${CYAN}Ubah dari 127.0.0.1 → 0.0.0.0${NC}          ${YELLOW}│${NC}"
    echo -e "  ${YELLOW}└─────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "  ${RED}┌─────────────────────────────────────────┐${NC}"
    echo -e "  ${RED}│${NC}  ${WHITE}[4]${NC} ${RED}🗑️  Uninstall${NC}${RED}                       │${NC}"
    echo -e "  ${RED}│${NC}     ${CYAN}Hapus Panel / Wings${NC}               ${RED}│${NC}"
    echo -e "  ${RED}└─────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "  ${MAGENTA}┌─────────────────────────────────────────┐${NC}"
    echo -e "  ${MAGENTA}│${NC}  ${WHITE}[5]${NC} ${MAGENTA}❌ Exit${NC}${MAGENTA}                           │${NC}"
    echo -e "  ${MAGENTA}│${NC}     ${CYAN}Keluar dari installer${NC}             ${MAGENTA}│${NC}"
    echo -e "  ${MAGENTA}└─────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━���━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -n -e "${WHITE}Masukkan pilihan [1-5]: ${NC}"
}

# ===== INSTALL PANEL FULL AUTO =====
install_panel() {
    show_banner
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}            🖥️  PTERODACTYL PANEL - FULL AUTO INSTALLATION${NC}"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Input dari user
    read -p "📍 Domain Panel (ex: panel.example.com): " PANEL_DOMAIN
    read -p "📧 Email Admin (ex: admin@example.com): " PANEL_EMAIL
    
    # Validasi
    if [[ -z "$PANEL_DOMAIN" ]] || [[ -z "$PANEL_EMAIL" ]]; then
        print_error "Domain dan email harus diisi!"
        sleep 2
        install_panel
        return
    fi
    
    # Generate credentials RANDOM
    DB_NAME=$(gen_db_name)
    DB_USER="pterodactyl"
    DB_PASS=$(gen_password)
    ADMIN_USER="admin"
    ADMIN_PASS=$(gen_password)
    CERT_EMAIL=$(gen_email)
    
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}           🔑 GENERATED CREDENTIALS${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${WHITE}📦 Database Name:${NC}      ${YELLOW}$DB_NAME${NC}"
    echo -e "  ${WHITE}👤 Database User:${NC}      ${YELLOW}$DB_USER${NC}"
    echo -e "  ${WHITE}🔐 Database Pass:${NC}      ${YELLOW}$DB_PASS${NC}"
    echo ""
    echo -e "  ${WHITE}👨 Admin User:${NC}         ${YELLOW}$ADMIN_USER${NC}"
    echo -e "  ${WHITE}🔑 Admin Pass:${NC}         ${YELLOW}$ADMIN_PASS${NC}"
    echo ""
    echo -e "  ${WHITE}📧 SSL Email:${NC}          ${YELLOW}$CERT_EMAIL${NC}"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    print_info "Starting Panel Installation..."
    sleep 3
    
    # Buat input file untuk installer
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
    
    # Jalankan installer
    echo -e "${CYAN}📥 Downloading and running official Pterodactyl installer...${NC}"
    echo ""
    bash <(curl -s https://pterodactyl-installer.se) < $INPUT_FILE 2>&1 | tee /tmp/pterodactyl_install.log
    
    # Clean up
    rm -f $INPUT_FILE
    
    # Tunggu beberapa saat
    sleep 5
    
    # Verify installation
    echo ""
    print_info "Verifying installation..."
    
    if [ -d "/var/www/pterodactyl" ] && [ -f "/var/www/pterodactyl/.env" ]; then
        print_success "Panel installation verified!"
        
        # Save credentials to file
        INFO_FILE="/root/pterodactyl_panel_info.txt"
        cat > $INFO_FILE <<EOF
╔═══════════════════════════════════════════════════════════════════════╗
║                   PTERODACTYL PANEL - CREDENTIALS                     ║
╚═══════════════════════════════════════════════════════════════════════╝

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

╔═══════════════════════════════════════════════════════════════════════╗
⚠️  SIMPAN INFORMASI INI DI TEMPAT AMAN!
╚═══════════════════════════════════════════════════════════════════════╝

NEXT STEPS:
1. Open https://$PANEL_DOMAIN in browser
2. Login with:
   - Username: $ADMIN_USER
   - Password: $ADMIN_PASS
3. Go to Admin → Locations → Create Location (for Wings)
4. Go to Admin → Nodes → Create Node
5. Copy configuration command from Node
6. Run on Wings server

═══════════════════════════════════════════════════════════════════════════
EOF
        
        print_success "Panel info saved to: $INFO_FILE"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
        cat $INFO_FILE
        echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
        
    else
        print_error "Panel installation FAILED!"
        print_warning "Check log: /tmp/pterodactyl_install.log"
        echo ""
        tail -50 /tmp/pterodactyl_install.log
    fi
    
    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
}

# ===== INSTALL WINGS =====
install_wings() {
    show_banner
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}              🪶 PTERODACTYL WINGS - INSTALLATION${NC}"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
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
    
    # Create input file
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
    
    # Run installer
    echo -e "${CYAN}📥 Downloading and running official Pterodactyl installer...${NC}"
    echo ""
    bash <(curl -s https://pterodactyl-installer.se) < $INPUT_FILE 2>&1 | tee /tmp/wings_install.log
    
    rm -f $INPUT_FILE
    
    sleep 5
    
    # Verify
    if [ -f "/usr/local/bin/wings" ]; then
        print_success "Wings binary installed!"
        
        # Create pterodactyl directory if not exists
        mkdir -p /etc/pterodactyl
        
        echo ""
        echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
        echo -e "${MAGENTA}        🔧 WINGS CONFIGURATION - IKUTI LANGKAH BERIKUT${NC}"
        echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "  ${WHITE}STEP 1:${NC} Go to Panel"
        echo -e "           ${CYAN}https://your-panel-domain${NC}"
        echo ""
        echo -e "  ${WHITE}STEP 2:${NC} Navigate to:"
        echo -e "           ${YELLOW}Admin → Locations → Create Location${NC}"
        echo -e "           ${CYAN}(ex: Main Location)${NC}"
        echo ""
        echo -e "  ${WHITE}STEP 3:${NC} Navigate to:"
        echo -e "           ${YELLOW}Admin → Nodes → Create New Node${NC}"
        echo ""
        echo -e "  ${WHITE}STEP 4:${NC} Fill in the form:"
        echo -e "           ${CYAN}Name: Node1${NC}"
        echo -e "           ${CYAN}Location: Main (pilih yang sudah dibuat)${NC}"
        echo -e "           ${CYAN}FQDN: $NODE_DOMAIN${NC}"
        echo -e "           ${CYAN}Scheme: HTTPS${NC}"
        echo ""
        echo -e "  ${WHITE}STEP 5:${NC} After creating, click:"
        echo -e "           ${YELLOW}Configuration Tab${NC}"
        echo ""
        echo -e "  ${WHITE}STEP 6:${NC} Copy the FULL command that shown:"
        echo -e "           ${YELLOW}cd /etc/pterodactyl && sudo wings configure...${NC}"
        echo ""
        echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
        echo ""
        print_info "Paste the configuration command here:"
        read -r CONFIG_CMD
        
        if [[ -n "$CONFIG_CMD" ]]; then
            print_info "Running configuration command..."
            cd /etc/pterodactyl
            eval "$CONFIG_CMD" 2>&1 | tee /tmp/wings_config.log
            
            sleep 3
            
            # Start wings
            print_info "Starting Wings service..."
            systemctl start wings
            sleep 3
            
            # Check status
            if systemctl is-active --quiet wings; then
                print_success "Wings is RUNNING! ✅"
                
                # Save info
                WINGS_INFO="/root/pterodactyl_wings_info.txt"
                cat > $WINGS_INFO <<EOF
╔═══════════════════════════════════════════════════════════════════════╗
║                  PTERODACTYL WINGS - INFORMATION                      ║
╚═══════════════════════════════════════════════════════════════════════╝

🖥️  NODE DOMAIN: $NODE_DOMAIN
📧 SSL EMAIL: $NODE_EMAIL

✅ STATUS: RUNNING

═══════════════════════════════════════════════════════════════════════════

🛠️  USEFUL COMMANDS:

  Check Status:
  $ systemctl status wings

  View Live Logs:
  $ journalctl -u wings -f

  Restart Wings:
  $ systemctl restart wings

  Stop Wings:
  $ systemctl stop wings

═══════════════════════════════════════════════════════════════════════════

🔥 FIREWALL PORTS NEEDED:

  8080 (TCP)     → Wings Communication
  2022 (TCP)     → SFTP Access

═══════════════════════════════════════════════════════════════════════════
EOF
                
                print_success "Wings info saved to: $WINGS_INFO"
                echo ""
                cat $WINGS_INFO
            else
                print_error "Wings failed to start! ❌"
                print_warning "Check logs with: journalctl -u wings -f"
            fi
        else
            print_warning "Configuration skipped. Configure manually with:"
            echo ""
            echo -e "${CYAN}cd /etc/pterodactyl && sudo wings configure --panel-url https://panel.domain --token YOUR_TOKEN --node NODE_ID${NC}"
        fi
    else
        print_error "Wings installation FAILED!"
        print_warning "Check log: /tmp/wings_install.log"
        echo ""
        tail -50 /tmp/wings_install.log
    fi
    
    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
}

# ===== CHANGE DATABASE HOST =====
change_db_host() {
    show_banner
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}               🔄 CHANGE DATABASE HOST${NC}"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    ENV_FILE="/var/www/pterodactyl/.env"
    
    if [ ! -f "$ENV_FILE" ]; then
        print_error "Panel tidak terinstall! File .env tidak ditemukan."
        echo ""
        echo -e "${YELLOW}Press Enter to continue...${NC}"
        read
        return
    fi
    
    print_info "Backing up .env..."
    cp "$ENV_FILE" "${ENV_FILE}.backup.$(date +%s)"
    
    print_info "Changing DB_HOST to 0.0.0.0..."
    sed -i 's/DB_HOST=127.0.0.1/DB_HOST=0.0.0.0/g' "$ENV_FILE"
    
    print_info "Configuring MariaDB..."
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
    
    # Get DB credentials
    DB_USER=$(grep "^DB_USERNAME=" "$ENV_FILE" | cut -d '=' -f2)
    DB_PASS=$(grep "^DB_PASSWORD=" "$ENV_FILE" | cut -d '=' -f2)
    DB_NAME=$(grep "^DB_DATABASE=" "$ENV_FILE" | cut -d '=' -f2)
    
    print_info "Updating database permissions..."
    
    # Update MySQL permissions
    mysql -e "DROP USER IF EXISTS '${DB_USER}'@'127.0.0.1';" 2>/dev/null || true
    mysql -e "DROP USER IF EXISTS '${DB_USER}'@'localhost';" 2>/dev/null || true
    mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';" 2>/dev/null
    mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%' WITH GRANT OPTION;" 2>/dev/null
    mysql -e "FLUSH PRIVILEGES;" 2>/dev/null
    
    print_success "Database user updated for remote access"
    
    # Clear Laravel cache
    print_info "Clearing Laravel cache..."
    cd /var/www/pterodactyl
    php artisan config:clear
    php artisan cache:clear
    
    print_success "Database host changed to 0.0.0.0! ✅"
    echo ""
    print_warning "⚠️  Database sekarang dapat diakses dari semua host!"
    echo ""
    
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
}

# ===== UNINSTALL =====
uninstall_pterodactyl() {
    show_banner
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}                 🗑️  UNINSTALL PTERODACTYL${NC}"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    print_warning "⚠️  WARNING: This will DELETE Panel/Wings and all data!"
    echo ""
    
    echo -e "${CYAN}What to uninstall?${NC}"
    echo ""
    echo -e "  ${RED}[1]${NC} Panel only"
    echo -e "  ${RED}[2]${NC} Wings only"
    echo -e "  ${RED}[3]${NC} Both Panel & Wings"
    echo -e "  ${RED}[4]${NC} Cancel"
    echo ""
    echo -n "Choice [1-4]: "
    read uninstall_choice
    
    case $uninstall_choice in
        1)
            print_warning "Uninstalling Panel..."
            systemctl stop pteroq 2>/dev/null || true
            systemctl disable pteroq 2>/dev/null || true
            rm -rf /var/www/pterodactyl
            rm -f /etc/nginx/sites-enabled/pterodactyl.conf
            rm -f /etc/nginx/sites-available/pterodactyl.conf
            systemctl reload nginx 2>/dev/null || true
            print_success "Panel uninstalled! ✅"
            ;;
        2)
            print_warning "Uninstalling Wings..."
            systemctl stop wings 2>/dev/null || true
            systemctl disable wings 2>/dev/null || true
            rm -f /usr/local/bin/wings
            rm -rf /etc/pterodactyl
            docker stop $(docker ps -aq) 2>/dev/null || true
            docker rm $(docker ps -aq) 2>/dev/null || true
            print_success "Wings uninstalled! ✅"
            ;;
        3)
            print_warning "Uninstalling Panel & Wings..."
            systemctl stop pteroq 2>/dev/null || true
            systemctl disable pteroq 2>/dev/null || true
            rm -rf /var/www/pterodactyl
            rm -f /etc/nginx/sites-enabled/pterodactyl.conf
            systemctl stop wings 2>/dev/null || true
            systemctl disable wings 2>/dev/null || true
            rm -f /usr/local/bin/wings
            rm -rf /etc/pterodactyl
            docker stop $(docker ps -aq) 2>/dev/null || true
            docker rm $(docker ps -aq) 2>/dev/null || true
            print_success "Panel & Wings uninstalled! ✅"
            ;;
        4)
            print_info "Uninstall cancelled"
            ;;
    esac
    
    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
}

# ===== MAIN =====
# Check root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}This script must be run as root!${NC}"
    echo "Usage: sudo bash installpanel.sh"
    exit 1
fi

# Main loop
while true; do
    show_menu
    read choice
    case $choice in
        1) install_panel ;;
        2) install_wings ;;
        3) change_db_host ;;
        4) uninstall_pterodactyl ;;
        5) 
            clear
            echo -e "${MAGENTA}"
            echo "  ██████╗ ██╗███████╗██╗     ██╗     ██╗ ██████╗ ███╗   ██╗ █████╗ "
            echo "  ██╔══██╗██║██╔════╝██║     ██║     ██║██╔═══██╗████╗  ██║██╔══██╗"
            echo "  ██████╔╝██║█████╗  ██║     ██║     ██║██║   ██║██╔██╗ ██║███████║"
            echo "  ██╔══██╗██║██╔══╝  ██║     ██║     ██║██║   ██║██║╚██╗██║██╔══██║"
            echo "  ██║  ██║██║███████╗███████╗███████╗██║╚██████╔╝██║ ╚████║██║  ██║"
            echo "  ╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝"
            echo -e "${NC}"
            echo ""
            echo -e "${GREEN}Terima kasih telah menggunakan Pterodactyl Auto Installer!${NC}"
            echo -e "${CYAN}Copyright © Paell-stunY & Rielliona${NC}"
            echo ""
            exit 0 
            ;;
        *) print_error "Invalid choice!"; sleep 2 ;;
    esac
done
