#!/bin/bash
# shellcheck source=/dev/null

set -e

########################################################
# 
#    Pterodactyl AnimatedGraphics Theme Installer
#         Optimized for v1.12.0
#
#         Original theme by Ferks-FK
#         Script modified for Pterodactyl v1.12.0
#
#         Key Changes in v1.12.0:
#         - Node.js 22 required (was 14/18)
#         - Security CVE patches
#         - Updated dependencies
#
#            Protected by MIT License
#
########################################################

# Fixed Variables #
GITHUB_BASE_URL="https://raw.githubusercontent.com/Ferks-FK/Pterodactyl-AutoThemes/main"
SUPPORT_LINK="https://discord.gg/buDBbSGJmQ"
REQUIRED_NODE_VERSION=22
SCRIPT_VERSION="v1.12.0-optimized"

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

sleep 2
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
# Update the variables after detection of the pterodactyl installation #
update_variables
}

# Verify Compatibility - Strict v1.12.0 check #
compatibility() {
print "Checking compatibility with Pterodactyl v1.12.0..."

sleep 1

echo -e "${CYAN}========================================${RESET}"
echo -e "${CYAN}Panel Version Detected: ${YELLOW}$PANEL_VERSION${RESET}"
echo -e "${CYAN}Required Version: ${GREEN}1.12.0${RESET}"
echo -e "${CYAN}========================================${RESET}"

# Strict version check for v1.12.0
if [ "$PANEL_VERSION" == "1.12.0" ]; then
    print_success "Perfect! Panel version ${YELLOW}v1.12.0${RESET} detected"
    print "This script is optimized specifically for this version"
elif [ "$PANEL_VERSION" == "1.12.1" ] || [ "$PANEL_VERSION" == "1.12.2" ]; then
    print_warning "Panel version ${YELLOW}$PANEL_VERSION${RESET} detected"
    echo -e "* This script is optimized for v1.12.0"
    echo -ne "* Continue anyway? (y/N): "
    read -r CONTINUE
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        print "Installation cancelled"
        exit 1
    fi
else
    print_error "Incompatible Panel Version: ${RED}$PANEL_VERSION${RESET}"
    echo ""
    echo -e "${YELLOW}This script is specifically designed for Pterodactyl v1.12.0${RESET}"
    echo -e "Your version: ${RED}$PANEL_VERSION${RESET}"
    echo -e "Required: ${GREEN}1.12.0${RESET}"
    echo ""
    echo -e "${CYAN}Recommendations:${RESET}"
    if [[ "$PANEL_VERSION" < "1.12.0" ]]; then
        echo "• Update your panel to v1.12.0 first"
        echo "• Run: ${YELLOW}cd /var/www/pterodactyl && php artisan p:upgrade${RESET}"
    else
        echo "• Your panel is newer than v1.12.0"
        echo "• Check if theme files need updates for your version"
    fi
    echo ""
    exit 1
fi

# Check PHP version (v1.12.0 requires PHP 8.2+)
PHP_VERSION=$(php -r 'echo PHP_VERSION;' | cut -d'.' -f1-2)
PHP_MAJOR=$(echo "$PHP_VERSION" | cut -d'.' -f1)
PHP_MINOR=$(echo "$PHP_VERSION" | cut -d'.' -f2)

echo ""
echo -e "${CYAN}PHP Version Check:${RESET}"
echo -e "Detected: ${YELLOW}PHP $PHP_VERSION${RESET}"

if [ "$PHP_MAJOR" -ge 8 ] && [ "$PHP_MINOR" -ge 2 ]; then
    print_success "PHP version requirement met (8.2+)"
else
    print_error "PHP 8.2 or higher required for Pterodactyl v1.12.0"
    echo -e "Your version: ${RED}PHP $PHP_VERSION${RESET}"
    echo -e "Required: ${GREEN}PHP 8.2+${RESET}"
    exit 1
fi
}

# Install Dependencies - Node.js 22 required for v1.12.0 #
dependencies() {
print "Installing/Checking dependencies for v1.12.0..."

echo -e "${CYAN}========================================${RESET}"
echo -e "${CYAN}Checking Node.js (Required: v22)${RESET}"
echo -e "${CYAN}========================================${RESET}"

# Check Node.js version
if command -v node &>/dev/null; then
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    echo -e "Current Node.js version: ${YELLOW}v$NODE_VERSION${RESET}"
    
    if [ "$NODE_VERSION" -eq "$REQUIRED_NODE_VERSION" ]; then
        print_success "Node.js ${REQUIRED_NODE_VERSION} detected - Perfect!"
    elif [ "$NODE_VERSION" -gt "$REQUIRED_NODE_VERSION" ]; then
        print_warning "Node.js v$NODE_VERSION detected (newer than required v${REQUIRED_NODE_VERSION})"
        echo -e "* Should work fine, but v${REQUIRED_NODE_VERSION} is recommended for v1.12.0"
    else
        print_warning "Node.js v$NODE_VERSION is too old for Pterodactyl v1.12.0"
        print "Installing Node.js ${REQUIRED_NODE_VERSION}..."
        install_nodejs
    fi
else
    print "Node.js not found, installing Node.js ${REQUIRED_NODE_VERSION}..."
    install_nodejs
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
    print_success "Yarn installed successfully"
fi
}

install_nodejs() {
    # Remove old Node.js versions first
    print "Removing old Node.js installations..."
    
    case "$OS" in
      debian | ubuntu)
        apt-get remove -y nodejs npm 2>/dev/null || true
        apt-get autoremove -y 2>/dev/null || true
        
        print "Installing Node.js ${REQUIRED_NODE_VERSION}..."
        curl -fsSL https://deb.nodesource.com/setup_${REQUIRED_NODE_VERSION}.x | bash -
        apt-get install -y nodejs
      ;;
      centos | rhel | rocky | almalinux)
        yum remove -y nodejs npm 2>/dev/null || true
        dnf remove -y nodejs npm 2>/dev/null || true
        
        print "Installing Node.js ${REQUIRED_NODE_VERSION}..."
        curl -fsSL https://rpm.nodesource.com/setup_${REQUIRED_NODE_VERSION}.x | bash -
        
        if [ "$OS_VER_MAJOR" == "7" ]; then
            yum install -y nodejs
        else
            dnf install -y nodejs
        fi
      ;;
      fedora)
        dnf remove -y nodejs npm 2>/dev/null || true
        
        print "Installing Node.js ${REQUIRED_NODE_VERSION}..."
        curl -fsSL https://rpm.nodesource.com/setup_${REQUIRED_NODE_VERSION}.x | bash -
        dnf install -y nodejs
      ;;
      *)
        print_error "Unsupported OS for automatic Node.js installation"
        print "Please install Node.js ${REQUIRED_NODE_VERSION} manually:"
        echo "https://nodejs.org/en/download/"
        exit 1
      ;;
    esac
    
    # Verify installation
    if command -v node &>/dev/null; then
        NODE_VERSION=$(node -v)
        print_success "Node.js ${NODE_VERSION} installed successfully"
    else
        print_error "Node.js installation failed"
        exit 1
    fi
}

# Panel Backup #
backup() {
print "Creating backup before installation..."

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$PTERO/PanelBackup[AnimatedGraphics-v1.12.0-$TIMESTAMP]"

echo -e "${CYAN}Backup location: ${YELLOW}$BACKUP_DIR${RESET}"

cd "$PTERO" || exit 1

mkdir -p "$BACKUP_DIR"

print "Creating compressed backup (this may take a moment)..."

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

# Save version info
echo "Panel Version: $PANEL_VERSION" > "$BACKUP_DIR/backup-info.txt"
echo "Backup Date: $(date)" >> "$BACKUP_DIR/backup-info.txt"
echo "Node.js Version: $(node -v)" >> "$BACKUP_DIR/backup-info.txt"
echo "PHP Version: $(php -v | head -n1)" >> "$BACKUP_DIR/backup-info.txt"

print_success "Backup created successfully!"
echo -e "Location: ${YELLOW}$BACKUP_DIR${RESET}"
}

# Download Theme Files #
download_files() {
print "Downloading AnimatedGraphics theme files..."

mkdir -p "$PTERO/temp"

# Try to download from original repo
print "Attempting download from GitHub..."

if curl -sSLf -o "$PTERO/temp/AnimatedGraphics.tar.gz" \
    "$GITHUB_BASE_URL/themes/version1.x/AnimatedGraphics/AnimatedGraphics.tar.gz" 2>/dev/null; then
    print_success "Theme files downloaded successfully"
    
    print "Extracting theme files..."
    tar -xzf "$PTERO/temp/AnimatedGraphics.tar.gz" -C "$PTERO/temp"
    
    if [ -d "$PTERO/temp/AnimatedGraphics" ]; then
        print "Copying theme files to panel directory..."
        cp -rf "$PTERO/temp/AnimatedGraphics/"* "$PTERO/"
        print_success "Theme files installed"
    else
        print_error "Failed to extract theme files"
        rm -rf "$PTERO/temp"
        exit 1
    fi
else
    print_error "Failed to download theme files from GitHub"
    print_warning "This could be because:"
    echo "  • GitHub is temporarily unavailable"
    echo "  • The theme repository structure has changed"
    echo "  • Network connectivity issues"
    echo ""
    echo "Please check: $(hyperlink "$GITHUB_BASE_URL")"
    rm -rf "$PTERO/temp"
    exit 1
fi

rm -rf "$PTERO/temp"
}

# Check for conflicting addons #
check_conflict() {
print "Checking for conflicting themes/addons..."

sleep 1

# Check common conflict files
CONFLICT_FOUND=false

CONFLICT_FILES=(
    "$PTERO/resources/scripts/components/server/StatGraphs.tsx"
    "$PTERO/resources/scripts/components/server/Console.tsx"
    "$PTERO/resources/scripts/components/dashboard/DashboardContainer.tsx"
)

for file in "${CONFLICT_FILES[@]}"; do
    if [ -f "$file" ]; then
        if grep -q "Installed by Auto-Addons\|BIGGER_CONSOLE\|BiggerConsole\|Custom-Theme" "$file" 2>/dev/null; then
            CONFLICT_FOUND=true
            print_warning "Potential conflict detected in: $(basename "$file")"
        fi
    fi
done

if [ "$CONFLICT_FOUND" = true ]; then
    echo ""
    echo -e "${YELLOW}⚠ Conflicts detected with other themes/addons${RESET}"
    echo ""
    echo -e "${CYAN}Recommended actions:${RESET}"
    echo "1. Backup and remove conflicting themes first"
    echo "2. Or continue and manually resolve conflicts later"
    echo ""
    echo -ne "* Continue installation anyway? (y/N): "
    read -r CONTINUE
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        print "Installation cancelled by user"
        exit 1
    fi
else
    print_success "No conflicts detected"
fi
}

# Panel Production Build #
production() {
print_brake 70
echo -e "${CYAN}Building Panel Assets (Optimized for v1.12.0)${RESET}"
print_brake 70

echo ""
print_warning "This process will take 5-15 minutes depending on your server"
print_warning "DO NOT cancel or close this terminal!"
echo ""

cd "$PTERO" || exit 1

# Clear old cache
print "Clearing Laravel cache..."
php artisan config:clear 2>/dev/null || true
php artisan view:clear 2>/dev/null || true
php artisan route:clear 2>/dev/null || true

# Check if node_modules exists
if [ ! -d "$PTERO/node_modules" ]; then
    print "Installing Node.js dependencies with Yarn..."
    echo -e "${YELLOW}This is the first time building, it will take longer...${RESET}"
    yarn install --frozen-lockfile
else
    print "Updating Node.js dependencies..."
    yarn install --frozen-lockfile
fi

# Build production assets
print "Building production assets for v1.12.0..."
echo -e "${CYAN}Progress will be shown below:${RESET}"
echo ""

yarn build:production

echo ""
print_success "Build completed successfully!"

# Set correct permissions
print "Setting correct permissions..."
chown -R www-data:www-data "$PTERO"/* 2>/dev/null || true

# Clear cache again after build
print "Clearing cache after build..."
php artisan config:clear
php artisan view:clear
php artisan queue:restart 2>/dev/null || true

print_success "Production build completed!"
}

# Verification #
verify_installation() {
print "Verifying installation..."

VERIFICATION_PASSED=true

# Check if manifest exists
if [ -f "$PTERO/public/assets/manifest.json" ]; then
    print_success "Asset manifest found"
else
    print_warning "Asset manifest not found"
    VERIFICATION_PASSED=false
fi

# Check if public assets exist
if [ -d "$PTERO/public/assets" ] && [ "$(ls -A "$PTERO/public/assets")" ]; then
    print_success "Public assets generated"
else
    print_warning "Public assets directory empty"
    VERIFICATION_PASSED=false
fi

# Check permissions
if [ -w "$PTERO/storage" ]; then
    print_success "Storage directory writable"
else
    print_warning "Storage directory not writable"
    VERIFICATION_PASSED=false
fi

echo ""
if [ "$VERIFICATION_PASSED" = true ]; then
    print_success "All verification checks passed!"
else
    print_warning "Some verification checks failed"
    echo -e "* Check ${YELLOW}$PTERO/storage/logs/${RESET} for errors"
fi
}

# Success message #
bye() {
clear
print_brake 70
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║                                                               ║${RESET}"
echo -e "${GREEN}║      ${YELLOW}✓${GREEN} AnimatedGraphics Theme Successfully Installed!      ║${RESET}"
echo -e "${GREEN}║                                                               ║${RESET}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${RESET}"
echo ""
print_brake 70
echo ""
echo -e "${CYAN}Installation Summary:${RESET}"
echo -e "  • Panel Version: ${YELLOW}$PANEL_VERSION${RESET}"
echo -e "  • Node.js Version: ${YELLOW}$(node -v)${RESET}"
echo -e "  • Theme: ${YELLOW}AnimatedGraphics${RESET}"
echo -e "  • Backup: ${YELLOW}PanelBackup[AnimatedGraphics-v1.12.0-*]${RESET}"
echo ""
print_brake 70
echo ""
echo -e "${GREEN}Next Steps:${RESET}"
echo -e "  ${YELLOW}1.${RESET} Clear your browser cache (Ctrl+F5 or Cmd+Shift+R)"
echo -e "  ${YELLOW}2.${RESET} Refresh your Pterodactyl panel page"
echo -e "  ${YELLOW}3.${RESET} Check if animated graphics are working"
echo -e "  ${YELLOW}4.${RESET} Test server statistics display"
echo ""
print_brake 70
echo ""
echo -e "${CYAN}Troubleshooting (if theme not showing):${RESET}"
echo -e "  ${YELLOW}→${RESET} cd $PTERO"
echo -e "  ${YELLOW}→${RESET} php artisan view:clear"
echo -e "  ${YELLOW}→${RESET} php artisan config:clear"
echo -e "  ${YELLOW}→${RESET} Hard refresh browser (Ctrl+Shift+R)"
echo ""
print_brake 70
echo ""
echo -e "${CYAN}Need Help?${RESET}"
echo -e "  • Support: ${YELLOW}$(hyperlink "$SUPPORT_LINK")${RESET}"
echo -e "  • Logs: ${YELLOW}$PTERO/storage/logs/${RESET}"
echo -e "  • Original Theme: ${YELLOW}Ferks-FK${RESET}"
echo ""
print_brake 70
echo ""
echo -e "${GREEN}Thank you for using this installer!${RESET}"
echo ""
print_brake 70
}

# Main installation function #
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

# Exec Script #
clear
print_brake 70
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║                                                               ║${RESET}"
echo -e "${CYAN}║       ${YELLOW}Pterodactyl AnimatedGraphics Theme Installer${CYAN}        ║${RESET}"
echo -e "${CYAN}║              ${GREEN}Optimized for v1.12.0${CYAN}                         ║${RESET}"
echo -e "${CYAN}║                                                               ║${RESET}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${RESET}"
print_brake 70
echo ""
echo -e "${YELLOW}Script Version: $SCRIPT_VERSION${RESET}"
echo -e "${YELLOW}Original Theme: Ferks-FK${RESET}"
echo ""
print_brake 70

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root"
   echo -e "* Please run with: ${YELLOW}sudo bash $(basename "$0")${RESET}"
   exit 1
fi

# Show requirements
echo ""
echo -e "${CYAN}Requirements for Pterodactyl v1.12.0:${RESET}"
echo -e "  ✓ Panel Version: ${GREEN}v1.12.0${RESET}"
echo -e "  ✓ PHP Version: ${GREEN}8.2+${RESET}"
echo -e "  ✓ Node.js Version: ${GREEN}22${RESET}"
echo -e "  ✓ Composer: ${GREEN}2.x${RESET}"
echo ""
print_brake 70

sleep 2

check_distro
find_pterodactyl

if [ "$PTERO_INSTALL" == true ]; then
    print_success "Panel installation found at: ${YELLOW}$PTERO${RESET}"
    echo ""
    echo -ne "${CYAN}Press Enter to start installation or Ctrl+C to cancel...${RESET}"
    read -r
    main_install
elif [ "$PTERO_INSTALL" == false ]; then
    print_warning "Panel installation not found in standard directories"
    echo ""
    echo -e "${CYAN}Standard locations checked:${RESET}"
    echo -e "  • /var/www/pterodactyl"
    echo -e "  • /var/www/panel"
    echo -e "  • /var/www/ptero"
    echo ""
    echo -e "${GREEN}Example custom path:${RESET} ${YELLOW}/var/www/mypanel${RESET}"
    echo ""
    echo -ne "* Enter the pterodactyl installation directory: "
    read -r MANUAL_DIR
    
    if [ -d "$MANUAL_DIR" ]; then
        print_success "Directory found: ${YELLOW}$MANUAL_DIR${RESET}"
        PTERO="$MANUAL_DIR"
        update_variables
        echo ""
        echo -ne "${CYAN}Press Enter to start installation or Ctrl+C to cancel...${RESET}"
        read -r
        main_install
    else
        print_error "Directory not found: $MANUAL_DIR"
        echo ""
        echo "Please check the path and try again"
        exit 1
    fi
fi
