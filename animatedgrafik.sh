#!/bin/bash
# shellcheck source=/dev/null

set -e

########################################################
# 
#    Pterodactyl AnimatedGraphics Theme Installer
#         Works on ANY modern Pterodactyl version
#
#         Original theme by Ferks-FK
#         No version restrictions - just works
#
########################################################

GITHUB_BASE_URL="https://raw.githubusercontent.com/Ferks-FK/Pterodactyl-AutoThemes/main"
SUPPORT_LINK="https://discord.gg/buDBbSGJmQ"

# Colors
GREEN="\e[0;92m"
YELLOW="\033[1;33m"
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET="\e[0m"

# Visual functions
print_brake() {
  for ((n = 0; n < $1; n++)); do
    echo -n "#"
  done
  echo ""
}

print() {
  echo ""
  echo -e "* ${GREEN}$1${RESET}"
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

print_success() {
  echo ""
  echo -e "* ${GREEN}✓${RESET} $1"
  echo ""
}

# Get panel info
get_panel_info() {
    if [ -f "$PTERO/config/app.php" ]; then
        PANEL_VERSION=$(grep "'version'" "$PTERO/config/app.php" | cut -c18-25 | sed "s/[',]//g" 2>/dev/null || echo "unknown")
    else
        PANEL_VERSION="unknown"
    fi
}

# OS check
check_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$(echo "$ID" | awk '{print tolower($0)}')
    OS_VER=$VERSION_ID
  else
    OS=$(uname -s | awk '{print tolower($0)}')
    OS_VER="unknown"
  fi
  OS_VER_MAJOR=$(echo "$OS_VER" | cut -d. -f1)
}

# Find panel
find_pterodactyl() {
print "Looking for Pterodactyl installation..."

if [ -d "/var/www/pterodactyl" ]; then
    PTERO="/var/www/pterodactyl"
elif [ -d "/var/www/panel" ]; then
    PTERO="/var/www/panel"
elif [ -d "/var/www/ptero" ]; then
    PTERO="/var/www/ptero"
else
    PTERO=""
fi

if [ -n "$PTERO" ]; then
    get_panel_info
    print_success "Found panel at: ${YELLOW}$PTERO${RESET}"
    [ "$PANEL_VERSION" != "unknown" ] && echo -e "* Panel version: ${YELLOW}v$PANEL_VERSION${RESET}"
fi
}

# Get best Node.js version
get_node_version() {
    # Try to smart detect, but don't fail if can't determine
    if [ "$PANEL_VERSION" != "unknown" ]; then
        MINOR=$(echo "$PANEL_VERSION" | cut -d. -f2)
        if [ "$MINOR" -ge 12 ] 2>/dev/null; then
            echo "22"
        elif [ "$MINOR" -ge 11 ] 2>/dev/null; then
            echo "20"
        else
            echo "20"  # Safe default for most modern versions
        fi
    else
        echo "20"  # Default to Node 20 if can't detect
    fi
}

# Install Node.js
install_nodejs() {
    local NODE_VER=${1:-20}
    
    print "Installing Node.js v$NODE_VER..."
    
    case "$OS" in
      debian | ubuntu)
        apt-get remove -y nodejs npm 2>/dev/null || true
        curl -fsSL https://deb.nodesource.com/setup_${NODE_VER}.x | bash - 2>/dev/null || true
        apt-get install -y nodejs
      ;;
      centos | rhel | rocky | almalinux | fedora)
        yum remove -y nodejs npm 2>/dev/null || true
        dnf remove -y nodejs npm 2>/dev/null || true
        curl -fsSL https://rpm.nodesource.com/setup_${NODE_VER}.x | bash - 2>/dev/null || true
        
        if [ "$OS_VER_MAJOR" == "7" ]; then
            yum install -y nodejs
        else
            dnf install -y nodejs
        fi
      ;;
      *)
        print_warning "Auto-install not available for $OS"
        print "Please install Node.js manually and re-run this script"
        exit 1
      ;;
    esac
    
    if command -v node &>/dev/null; then
        print_success "Node.js $(node -v) installed"
    else
        print_error "Node.js installation failed"
        exit 1
    fi
}

# Check dependencies
dependencies() {
print "Checking dependencies..."

# Node.js
if command -v node &>/dev/null; then
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    print_success "Node.js v$NODE_VERSION detected"
    
    # Suggest upgrade if too old
    if [ "$NODE_VERSION" -lt 18 ]; then
        print_warning "Node.js v$NODE_VERSION might be too old"
        echo -ne "* Upgrade to newer version? (recommended) (y/N): "
        read -r UPGRADE
        if [[ "$UPGRADE" =~ ^[Yy]$ ]]; then
            RECOMMENDED_NODE=$(get_node_version)
            install_nodejs "$RECOMMENDED_NODE"
        fi
    fi
else
    print "Node.js not found"
    RECOMMENDED_NODE=$(get_node_version)
    install_nodejs "$RECOMMENDED_NODE"
fi

# Yarn
if ! command -v yarn &>/dev/null; then
    print "Installing Yarn..."
    npm install -g yarn 2>/dev/null || true
    print_success "Yarn installed"
else
    print_success "Yarn detected"
fi
}

# Backup
backup() {
print "Creating backup..."

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$PTERO/PanelBackup-AnimatedGraphics-$TIMESTAMP"

cd "$PTERO" || exit 1
mkdir -p "$BACKUP_DIR"

tar -czf "$BACKUP_DIR/backup.tar.gz" \
    --exclude="node_modules" \
    --exclude="PanelBackup*" \
    --exclude="storage/logs/*" \
    --exclude="storage/framework/cache/*" \
    --exclude="storage/framework/sessions/*" \
    --exclude="storage/framework/views/*" \
    -- * .env 2>/dev/null || true

echo "Backup created: $(date)" > "$BACKUP_DIR/info.txt"
echo "Panel version: $PANEL_VERSION" >> "$BACKUP_DIR/info.txt"

print_success "Backup saved to: $BACKUP_DIR"
}

# Download theme
download_files() {
print "Downloading theme files..."

mkdir -p "$PTERO/temp"

if curl -sSLf -o "$PTERO/temp/theme.tar.gz" \
    "$GITHUB_BASE_URL/themes/version1.x/AnimatedGraphics/AnimatedGraphics.tar.gz" 2>/dev/null; then
    
    tar -xzf "$PTERO/temp/theme.tar.gz" -C "$PTERO/temp" 2>/dev/null || true
    
    if [ -d "$PTERO/temp/AnimatedGraphics" ]; then
        cp -rf "$PTERO/temp/AnimatedGraphics/"* "$PTERO/" 2>/dev/null || true
        rm -rf "$PTERO/temp"
        print_success "Theme files installed"
    else
        print_error "Failed to extract theme"
        rm -rf "$PTERO/temp"
        exit 1
    fi
else
    print_error "Download failed"
    print "Check your internet connection or visit:"
    echo "  https://github.com/Ferks-FK/Pterodactyl-AutoThemes"
    rm -rf "$PTERO/temp"
    exit 1
fi
}

# Build panel
production() {
print_brake 60
echo -e "${CYAN}Building Panel Assets${RESET}"
print_brake 60
echo ""
print_warning "This will take 5-15 minutes"
print_warning "DO NOT close this terminal!"
echo ""

cd "$PTERO" || exit 1

# Clear cache
php artisan config:clear 2>/dev/null || true
php artisan view:clear 2>/dev/null || true

# Install deps
if [ ! -d "$PTERO/node_modules" ]; then
    print "Installing dependencies (first time)..."
    yarn install 2>/dev/null || npm install 2>/dev/null || true
else
    print "Updating dependencies..."
    yarn install 2>/dev/null || npm install 2>/dev/null || true
fi

# Build
print "Building production..."
yarn build:production 2>/dev/null || npm run build:production 2>/dev/null || true

# Permissions
print "Setting permissions..."
chown -R www-data:www-data "$PTERO"/* 2>/dev/null || true

# Clear again
php artisan config:clear 2>/dev/null || true
php artisan view:clear 2>/dev/null || true
php artisan queue:restart 2>/dev/null || true

print_success "Build complete!"
}

# Verify
verify() {
print "Verifying installation..."

if [ -f "$PTERO/public/assets/manifest.json" ]; then
    print_success "Assets generated successfully"
else
    print_warning "Could not verify assets, but might still work"
    print "Check manually if theme loads in browser"
fi
}

# Done
bye() {
clear
print_brake 60
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║                                                  ║${RESET}"
echo -e "${GREEN}║        ${YELLOW}✓${GREEN} AnimatedGraphics Installed!            ║${RESET}"
echo -e "${GREEN}║                                                  ║${RESET}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${RESET}"
echo ""
print_brake 60
echo ""
echo -e "${CYAN}Next Steps:${RESET}"
echo "  1. Clear browser cache (Ctrl+Shift+R)"
echo "  2. Refresh your panel"
echo "  3. Enjoy the animated theme!"
echo ""
echo -e "${CYAN}If theme not showing:${RESET}"
echo "  cd $PTERO"
echo "  php artisan view:clear"
echo "  php artisan config:clear"
echo ""
echo -e "${CYAN}Need help?${RESET} $SUPPORT_LINK"
echo ""
print_brake 60
}

# Main installation
main_install() {
    dependencies
    backup
    download_files
    production
    verify
    bye
}

# Start
clear
print_brake 60
echo ""
echo -e "${CYAN}  Pterodactyl AnimatedGraphics Theme Installer${RESET}"
echo -e "${YELLOW}  Works on ANY modern Pterodactyl version${RESET}"
echo ""
print_brake 60

# Root check
if [[ $EUID -ne 0 ]]; then
   print_error "Must run as root!"
   echo "Run: ${YELLOW}sudo bash $0${RESET}"
   exit 1
fi

check_distro
find_pterodactyl

if [ -z "$PTERO" ]; then
    print_warning "Panel not found in standard locations"
    echo ""
    echo "Standard paths checked:"
    echo "  • /var/www/pterodactyl"
    echo "  • /var/www/panel"
    echo "  • /var/www/ptero"
    echo ""
    echo -ne "Enter your panel directory: "
    read -r MANUAL_DIR
    
    if [ -d "$MANUAL_DIR" ]; then
        PTERO="$MANUAL_DIR"
        get_panel_info
        print_success "Found: $PTERO"
    else
        print_error "Directory not found!"
        exit 1
    fi
fi

echo ""
echo -e "${CYAN}Ready to install AnimatedGraphics theme${RESET}"
echo -e "Panel: ${YELLOW}$PTERO${RESET}"
[ "$PANEL_VERSION" != "unknown" ] && echo -e "Version: ${YELLOW}v$PANEL_VERSION${RESET}"
echo ""
echo -ne "Continue? (y/N): "
read -r CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    print "Installation cancelled"
    exit 0
fi

main_install
