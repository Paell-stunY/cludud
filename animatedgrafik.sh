#!/bin/bash
# shellcheck source=/dev/null

set -e

########################################################
# 
#    Pterodactyl AnimatedGraphics Theme Installer
#         Universal Version (v1.8.x - Latest)
#
#         Original theme by Ferks-FK
#         Modified for ALL modern versions
#
#            Protected by MIT License
#
########################################################

# Fixed Variables #
GITHUB_BASE_URL="https://raw.githubusercontent.com/Ferks-FK/Pterodactyl-AutoThemes/main"
SUPPORT_LINK="https://discord.gg/buDBbSGJmQ"
SCRIPT_VERSION="universal-v2.0"

# Update Variables #
update_variables() {
CONFIG_FILE="$PTERO/config/app.php"
if [ -f "$CONFIG_FILE" ]; then
    PANEL_VERSION=$(grep "'version'" "$CONFIG_FILE" | cut -c18-25 | sed "s/[',]//g")
else
    PANEL_VERSION="unknown"
fi
}

# Visual Functions #
print_brake() {
  for ((n = 0; n < $1; n++)); do
    echo -n "#"
  done
  echo ""
}

print_warning() {
  echo ""
  echo -e "* ${YELLOW}WARNING${RESET}: $1"
  echo ""
}

print_error() {
  echo ""
  echo -e "* ${RED}ERROR${RESET}: $1"
  echo ""
}

print() {
  echo ""
  echo -e "* ${GREEN}$1${RESET}"
  echo ""
}

print_success() {
  echo ""
  echo -e "* ${GREEN}✓${RESET} $1"
  echo ""
}

hyperlink() {
  echo -e "\e]8;;${1}\a${1}\e]8;;\a"
}

GREEN="\e[0;92m"
YELLOW="\033[1;33m"
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET="\e[0m"

# OS check #
check_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$(echo "$ID" | awk '{print tolower($0)}')
    OS_VER=$VERSION_ID
  elif type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si | awk '{print tolower($0)}')
    OS_VER=$(lsb_release -sr)
  elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    OS=$(echo "$DISTRIB_ID" | awk '{print tolower($0)}')
    OS_VER=$DISTRIB_RELEASE
  elif [ -f /etc/debian_version ]; then
    OS="debian"
    OS_VER=$(cat /etc/debian_version)
  elif [ -f /etc/SuSe-release ]; then
    OS="SuSE"
    OS_VER="?"
  elif [ -f /etc/redhat-release ]; then
    OS="Red Hat/CentOS"
    OS_VER="?"
  else
    OS=$(uname -s)
    OS_VER=$(uname -r)
  fi

  OS=$(echo "$OS" | awk '{print tolower($0)}')
  OS_VER_MAJOR=$(echo "$OS_VER" | cut -d. -f1)
}

# Find where pterodactyl is installed #
find_pterodactyl() {
print "Looking for your pterodactyl installation..."

sleep 1
if [ -d "/var/www/pterodactyl" ]; then
    PTERO_INSTALL=true
    PTERO="/var/www/pterodactyl"
  elif [ -d "/var/www/panel" ]; then
    PTERO_INSTALL=true
    PTERO="/var/www/panel"
  elif [ -d "/var/www/ptero" ]; then
    PTERO_INSTALL=true
    PTERO="/var/www/ptero"
  else
    PTERO_INSTALL=false
fi
update_variables
}

# Determine required Node.js version based on panel version #
get_required_node_version() {
    PANEL_MAJOR=$(echo "$PANEL_VERSION" | cut -d. -f1)
    PANEL_MINOR=$(echo "$PANEL_VERSION" | cut -d. -f2)
    
    # v1.12.0+ requires Node.js 22
    if [ "$PANEL_MAJOR" == "1" ] && [ "$PANEL_MINOR" -ge 12 ]; then
        REQUIRED_NODE=22
    # v1.11.x requires Node.js 20
    elif [ "$PANEL_MAJOR" == "1" ] && [ "$PANEL_MINOR" == 11 ]; then
        REQUIRED_NODE=20
    # v1.8.x - v1.10.x can use Node.js 18 or 20
    elif [ "$PANEL_MAJOR" == "1" ] && [ "$PANEL_MINOR" -ge 8 ]; then
        REQUIRED_NODE=18
    else
        REQUIRED_NODE=18  # fallback
    fi
    
    echo "$REQUIRED_NODE"
}

# Verify Compatibility - Universal check #
compatibility() {
print "Checking panel version compatibility..."

sleep 1

echo -e "${CYAN}========================================${RESET}"
echo -e "${CYAN}Panel Version: ${YELLOW}$PANEL_VERSION${RESET}"
echo -e "${CYAN}========================================${RESET}"

# Extract version numbers
PANEL_MAJOR=$(echo "$PANEL_VERSION" | cut -d. -f1)
PANEL_MINOR=$(echo "$PANEL_VERSION" | cut -d. -f2)

# Check if version is 1.8.0 or higher
if [ "$PANEL_MAJOR" == "1" ] && [ "$PANEL_MINOR" -ge 8 ]; then
    print_success "Compatible version detected: ${YELLOW}v$PANEL_VERSION${RESET}"
    
    # Show version-specific info
    if [ "$PANEL_MINOR" -ge 12 ]; then
        echo -e "${CYAN}Version Info:${RESET} v1.12.x+ detected"
        echo -e "${CYAN}Requirements:${RESET} Node.js 22, PHP 8.2+"
    elif [ "$PANEL_MINOR" == 11 ]; then
        echo -e "${CYAN}Version Info:${RESET} v1.11.x detected"
        echo -e "${CYAN}Requirements:${RESET} Node.js 20, PHP 8.1+"
    else
        echo -e "${CYAN}Version Info:${RESET} v1.8.x-v1.10.x detected"
        echo -e "${CYAN}Requirements:${RESET} Node.js 18+, PHP 8.1+"
    fi
elif [ "$PANEL_MAJOR" -gt 1 ]; then
    print_success "Future version detected: ${YELLOW}v$PANEL_VERSION${RESET}"
    print_warning "This version is newer than tested versions"
    echo -ne "* Continue installation? (y/N): "
    read -r CONTINUE
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        print "Installation cancelled"
        exit 1
    fi
else
    print_error "Incompatible version: ${RED}v$PANEL_VERSION${RESET}"
    echo ""
    echo -e "${YELLOW}This script requires Pterodactyl Panel v1.8.0 or higher${RESET}"
    echo -e "Your version: ${RED}$PANEL_VERSION${RESET}"
    echo -e "Required: ${GREEN}v1.8.0+${RESET}"
    echo ""
    echo -e "${CYAN}Please update your panel first:${RESET}"
    echo -e "cd /var/www/pterodactyl"
    echo -e "php artisan p:upgrade"
    echo ""
    exit 1
fi

# Check PHP version
PHP_VERSION=$(php -r 'echo PHP_VERSION;' | cut -d. -f1-2)
PHP_MAJOR=$(echo "$PHP_VERSION" | cut -d. -f1)
PHP_MINOR=$(echo "$PHP_VERSION" | cut -d. -f2)

echo ""
echo -e "${CYAN}PHP Version:${RESET} ${YELLOW}$PHP_VERSION${RESET}"

# PHP version requirements based on panel version
if [ "$PANEL_MINOR" -ge 12 ]; then
    # v1.12.0+ requires PHP 8.2+
    if [ "$PHP_MAJOR" -ge 8 ] && [ "$PHP_MINOR" -ge 2 ]; then
        print_success "PHP requirement met"
    else
        print_error "PHP 8.2+ required for Pterodactyl v1.12.0+"
        echo -e "Your PHP: ${RED}$PHP_VERSION${RESET}"
        echo -e "Required: ${GREEN}8.2+${RESET}"
        exit 1
    fi
else
    # v1.8.x-v1.11.x requires PHP 8.1+
    if [ "$PHP_MAJOR" -ge 8 ] && [ "$PHP_MINOR" -ge 1 ]; then
        print_success "PHP requirement met"
    else
        print_error "PHP 8.1+ required for Pterodactyl v1.8.0+"
        echo -e "Your PHP: ${RED}$PHP_VERSION${RESET}"
        echo -e "Required: ${GREEN}8.1+${RESET}"
        exit 1
    fi
fi
}

# Install Dependencies - Auto-detect required Node.js version #
dependencies() {
print "Checking dependencies..."

# Get required Node.js version for this panel version
REQUIRED_NODE=$(get_required_node_version)

echo ""
echo -e "${CYAN}========================================${RESET}"
echo -e "${CYAN}Node.js Requirement Check${RESET}"
echo -e "${CYAN}Panel v$PANEL_VERSION requires: Node.js ${YELLOW}v$REQUIRED_NODE${RESET}"
echo -e "${CYAN}========================================${RESET}"

# Check current Node.js version
if command -v node &>/dev/null; then
    CURRENT_NODE=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    echo -e "Current Node.js: ${YELLOW}v$CURRENT_NODE${RESET}"
    
    if [ "$CURRENT_NODE" -eq "$REQUIRED_NODE" ]; then
        print_success "Perfect! Node.js v$REQUIRED_NODE is installed"
    elif [ "$CURRENT_NODE" -gt "$REQUIRED_NODE" ]; then
        print_success "Node.js v$CURRENT_NODE detected (newer than required v$REQUIRED_NODE)"
    else
        print_warning "Node.js v$CURRENT_NODE is too old"
        print "Upgrading to Node.js v$REQUIRED_NODE..."
        install_nodejs "$REQUIRED_NODE"
    fi
else
    print "Node.js not found, installing v$REQUIRED_NODE..."
    install_nodejs "$REQUIRED_NODE"
fi

# Check Yarn
echo ""
echo -e "${CYAN}Checking Yarn...${RESET}"
if command -v yarn &>/dev/null; then
    YARN_VERSION=$(yarn --version)
    print_success "Yarn v$YARN_VERSION detected"
else
    print "Installing Yarn..."
    npm install -g yarn
    print_success "Yarn installed"
fi
}

install_nodejs() {
    local NODE_VERSION=$1
    
    print "Installing Node.js v$NODE_VERSION..."
    
    # Remove old versions
    case "$OS" in
      debian | ubuntu)
        apt-get remove -y nodejs npm 2>/dev/null || true
        apt-get autoremove -y 2>/dev/null || true
        
        curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
        apt-get install -y nodejs
      ;;
      centos | rhel | rocky | almalinux)
        yum remove -y nodejs npm 2>/dev/null || true
        dnf remove -y nodejs npm 2>/dev/null || true
        
        curl -fsSL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | bash -
        
        if [ "$OS_VER_MAJOR" == "7" ]; then
            yum install -y nodejs
        else
            dnf install -y nodejs
        fi
      ;;
      fedora)
        dnf remove -y nodejs npm 2>/dev/null || true
        curl -fsSL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | bash -
        dnf install -y nodejs
      ;;
      *)
        print_error "Unsupported OS for auto Node.js installation"
        print "Please install Node.js v$NODE_VERSION manually"
        exit 1
      ;;
    esac
    
    # Verify
    if command -v node &>/dev/null; then
        NODE_VER=$(node -v)
        print_success "Node.js $NODE_VER installed successfully"
    else
        print_error "Node.js installation failed"
        exit 1
    fi
}

# Panel Backup #
backup() {
print "Creating backup..."

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$PTERO/PanelBackup[AnimatedGraphics-$TIMESTAMP]"

cd "$PTERO" || exit 1
mkdir -p "$BACKUP_DIR"

print "Compressing files (excluding node_modules)..."

if [ -d "$PTERO/node_modules" ]; then
    tar -czf "$BACKUP_DIR/panel-backup.tar.gz" \
        --exclude="node_modules" \
        --exclude="PanelBackup*" \
        --exclude="storage/logs/*" \
        --exclude="storage/framework/cache/*" \
        --exclude="storage/framework/sessions/*" \
        --exclude="storage/framework/views/*" \
        -- * .env 2>/dev/null
else
    tar -czf "$BACKUP_DIR/panel-backup.tar.gz" \
        --exclude="PanelBackup*" \
        --exclude="storage/logs/*" \
        --exclude="storage/framework/cache/*" \
        --exclude="storage/framework/sessions/*" \
        --exclude="storage/framework/views/*" \
        -- * .env 2>/dev/null
fi

# Save info
echo "Panel Version: $PANEL_VERSION" > "$BACKUP_DIR/info.txt"
echo "Backup Date: $(date)" >> "$BACKUP_DIR/info.txt"
echo "Node.js: $(node -v)" >> "$BACKUP_DIR/info.txt"
echo "PHP: $(php -v | head -n1)" >> "$BACKUP_DIR/info.txt"

print_success "Backup created at: ${YELLOW}$BACKUP_DIR${RESET}"
}

# Download Theme Files #
download_files() {
print "Downloading theme files..."

mkdir -p "$PTERO/temp"

if curl -sSLf -o "$PTERO/temp/AnimatedGraphics.tar.gz" \
    "$GITHUB_BASE_URL/themes/version1.x/AnimatedGraphics/AnimatedGraphics.tar.gz" 2>/dev/null; then
    print_success "Download successful"
    
    tar -xzf "$PTERO/temp/AnimatedGraphics.tar.gz" -C "$PTERO/temp"
    
    if [ -d "$PTERO/temp/AnimatedGraphics" ]; then
        cp -rf "$PTERO/temp/AnimatedGraphics/"* "$PTERO/"
        print_success "Theme files installed"
    else
        print_error "Extraction failed"
        rm -rf "$PTERO/temp"
        exit 1
    fi
else
    print_error "Download failed"
    echo -e "Check: ${YELLOW}$(hyperlink "$GITHUB_BASE_URL")${RESET}"
    rm -rf "$PTERO/temp"
    exit 1
fi

rm -rf "$PTERO/temp"
}

# Check conflicts #
check_conflict() {
print "Checking for conflicts..."

sleep 1

CONFLICT_FOUND=false
CONFLICT_FILES=(
    "$PTERO/resources/scripts/components/server/StatGraphs.tsx"
    "$PTERO/resources/scripts/components/server/Console.tsx"
)

for file in "${CONFLICT_FILES[@]}"; do
    if [ -f "$file" ] && grep -q "Installed by Auto-Addons\|BIGGER_CONSOLE\|BiggerConsole" "$file" 2>/dev/null; then
        CONFLICT_FOUND=true
        print_warning "Conflict in: $(basename "$file")"
    fi
done

if [ "$CONFLICT_FOUND" = true ]; then
    echo ""
    echo -ne "* Continue anyway? (y/N): "
    read -r CONTINUE
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        print "Cancelled"
        exit 1
    fi
else
    print_success "No conflicts"
fi
}

# Production Build #
production() {
print_brake 70
echo -e "${CYAN}Building Panel Assets${RESET}"
print_brake 70
echo ""
print_warning "This takes 5-15 minutes - DO NOT cancel!"
echo ""

cd "$PTERO" || exit 1

# Clear cache
print "Clearing cache..."
php artisan config:clear 2>/dev/null || true
php artisan view:clear 2>/dev/null || true
php artisan route:clear 2>/dev/null || true

# Install/update dependencies
if [ ! -d "$PTERO/node_modules" ]; then
    print "Installing dependencies (first time - will be slow)..."
    yarn install --frozen-lockfile
else
    print "Updating dependencies..."
    yarn install --frozen-lockfile
fi

# Build
print "Building production assets..."
yarn build:production

# Permissions
print "Setting permissions..."
chown -R www-data:www-data "$PTERO"/* 2>/dev/null || true

# Clear again
print "Final cache clear..."
php artisan config:clear
php artisan view:clear
php artisan queue:restart 2>/dev/null || true

print_success "Build complete!"
}

# Verify #
verify_installation() {
print "Verifying..."

if [ -f "$PTERO/public/assets/manifest.json" ]; then
    print_success "Asset manifest OK"
else
    print_warning "Asset manifest missing"
fi

if [ -d "$PTERO/public/assets" ] && [ "$(ls -A "$PTERO/public/assets")" ]; then
    print_success "Public assets OK"
else
    print_warning "Public assets missing"
fi
}

# Success #
bye() {
clear
print_brake 70
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║                                                    ║${RESET}"
echo -e "${GREEN}║  ${YELLOW}✓${GREEN} AnimatedGraphics Theme Installed Successfully! ║${RESET}"
echo -e "${GREEN}║                                                    ║${RESET}"
echo -e "${GREEN}╚════════════════════════════════════════════════════╝${RESET}"
echo ""
print_brake 70
echo ""
echo -e "${CYAN}Installation Summary:${RESET}"
echo -e "  Panel: ${YELLOW}v$PANEL_VERSION${RESET}"
echo -e "  Node.js: ${YELLOW}$(node -v)${RESET}"
echo -e "  PHP: ${YELLOW}$(php -v | head -n1 | cut -d' ' -f2)${RESET}"
echo ""
print_brake 70
echo ""
echo -e "${GREEN}Next Steps:${RESET}"
echo -e "  1. Clear browser cache (Ctrl+Shift+R)"
echo -e "  2. Refresh panel page"
echo -e "  3. Enjoy animated graphics!"
echo ""
echo -e "${CYAN}Troubleshooting:${RESET}"
echo -e "  cd $PTERO"
echo -e "  php artisan view:clear"
echo -e "  php artisan config:clear"
echo ""
echo -e "${CYAN}Support:${RESET} ${YELLOW}$(hyperlink "$SUPPORT_LINK")${RESET}"
echo ""
print_brake 70
}

# Main #
main_install() {
    compatibility
    check_conflict
    dependencies
    backup
    download_files
    production
    verify_installation
    bye
}

# Start #
clear
print_brake 70
echo -e "${CYAN}╔════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║                                                    ║${RESET}"
echo -e "${CYAN}║    ${YELLOW}Pterodactyl AnimatedGraphics Installer${CYAN}        ║${RESET}"
echo -e "${CYAN}║         ${GREEN}Universal Version (v1.8.x - Latest)${CYAN}        ║${RESET}"
echo -e "${CYAN}║                                                    ║${RESET}"
echo -e "${CYAN}╚════════════════════════════════════════════════════╝${RESET}"
print_brake 70
echo ""
echo -e "${YELLOW}Original Theme: Ferks-FK${RESET}"
echo -e "${YELLOW}Script Version: $SCRIPT_VERSION${RESET}"
echo ""
print_brake 70

# Root check
if [[ $EUID -ne 0 ]]; then
   print_error "Run as root!"
   echo -e "Use: ${YELLOW}sudo bash $0${RESET}"
   exit 1
fi

echo ""
echo -e "${CYAN}Supports:${RESET}"
echo -e "  • Pterodactyl v1.8.x - Latest"
echo -e "  • Auto Node.js version detection"
echo -e "  • All modern PHP versions"
echo ""
print_brake 70

sleep 2

check_distro
find_pterodactyl

if [ "$PTERO_INSTALL" == true ]; then
    print_success "Panel found: ${YELLOW}$PTERO${RESET}"
    echo ""
    echo -ne "${CYAN}Press Enter to continue or Ctrl+C to cancel...${RESET}"
    read -r
    main_install
else
    print_warning "Panel not found in standard locations"
    echo ""
    echo -e "${CYAN}Checked:${RESET}"
    echo "  • /var/www/pterodactyl"
    echo "  • /var/www/panel"
    echo "  • /var/www/ptero"
    echo ""
    echo -ne "* Enter panel directory: "
    read -r MANUAL_DIR
    
    if [ -d "$MANUAL_DIR" ]; then
        print_success "Found: ${YELLOW}$MANUAL_DIR${RESET}"
        PTERO="$MANUAL_DIR"
        update_variables
        echo ""
        echo -ne "${CYAN}Press Enter to continue...${RESET}"
        read -r
        main_install
    else
        print_error "Not found: $MANUAL_DIR"
        exit 1
    fi
fi
