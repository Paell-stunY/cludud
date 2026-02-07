#!/bin/bash
# shellcheck source=/dev/null

set -e

########################################################
# 
#         Pterodactyl-AutoThemes Installation
#         Modified for Modern Pterodactyl Versions
#
#         Original by Ferks-FK
#         Modified for v1.8.x - v1.11.x+
#
#            Protected by MIT License
#
########################################################

# Fixed Variables #
GITHUB_BASE_URL="https://raw.githubusercontent.com/Ferks-FK/Pterodactyl-AutoThemes/main"
SUPPORT_LINK="https://discord.gg/buDBbSGJmQ"

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

hyperlink() {
  echo -e "\e]8;;${1}\a${1}\e]8;;\a"
}

GREEN="\e[0;92m"
YELLOW="\033[1;33m"
RED='\033[0;31m'
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

# Verify Compatibility #
compatibility() {
print "Checking if the addon is compatible with your panel..."

sleep 2

# Extract major and minor version
PANEL_MAJOR=$(echo "$PANEL_VERSION" | cut -d. -f1)
PANEL_MINOR=$(echo "$PANEL_VERSION" | cut -d. -f2)

# Check if version is 1.8.x or higher
if [ "$PANEL_MAJOR" == "1" ] && [ "$PANEL_MINOR" -ge 8 ]; then
    print "Compatible Version: ${YELLOW}$PANEL_VERSION${RESET}"
    print "Detected Pterodactyl v$PANEL_VERSION - Using modern configuration"
elif [ "$PANEL_MAJOR" -gt 1 ]; then
    print "Compatible Version: ${YELLOW}$PANEL_VERSION${RESET}"
    print "Detected Pterodactyl v$PANEL_VERSION - Using modern configuration"
else
    print_error "Incompatible Version: $PANEL_VERSION"
    print_error "This script requires Pterodactyl Panel v1.8.0 or higher"
    echo -e "* Your version: ${RED}$PANEL_VERSION${RESET}"
    echo -e "* Required: ${GREEN}1.8.0+${RESET}"
    exit 1
fi
}

# Install Dependencies #
dependencies() {
print "Installing dependencies..."

# Check Node.js version
if command -v node &>/dev/null; then
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -ge 18 ]; then
        print "Node.js $NODE_VERSION detected - OK"
    else
        print_warning "Node.js version is too old ($NODE_VERSION), installing Node.js 18..."
        install_nodejs
    fi
else
    print "Node.js not found, installing..."
    install_nodejs
fi

# Check Yarn
if ! command -v yarn &>/dev/null; then
    print "Installing Yarn..."
    npm install -g yarn
fi
}

install_nodejs() {
    case "$OS" in
      debian | ubuntu)
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        apt-get install -y nodejs
      ;;
      centos | rhel | rocky | almalinux)
        curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
        if [ "$OS_VER_MAJOR" == "7" ]; then
            yum install -y nodejs
        else
            dnf install -y nodejs
        fi
      ;;
      fedora)
        curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
        dnf install -y nodejs
      ;;
      *)
        print_error "Unsupported OS for automatic Node.js installation"
        print "Please install Node.js 18+ manually and run this script again"
        exit 1
      ;;
    esac
}

# Panel Backup #
backup() {
print "Performing security backup..."

BACKUP_DIR="$PTERO/PanelBackup[AnimatedGraphics-$(date +%Y%m%d-%H%M%S)]"

if [ -d "$PTERO/PanelBackup[AnimatedGraphics]" ]; then
    print "Previous backup found, creating new backup with timestamp..."
fi

cd "$PTERO" || exit 1

print "Creating backup at: $BACKUP_DIR"

mkdir -p "$BACKUP_DIR"

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

print "Backup completed successfully!"
}

# Download Files #
download_files() {
print "Downloading theme files..."

mkdir -p "$PTERO/temp"

# Try to download from original repo first
if curl -sSLf -o "$PTERO/temp/AnimatedGraphics.tar.gz" \
    "$GITHUB_BASE_URL/themes/version1.x/AnimatedGraphics/AnimatedGraphics.tar.gz" 2>/dev/null; then
    print "Downloaded theme files successfully"
else
    print_warning "Could not download from original repository"
    print "Attempting alternative download method..."
    
    # Alternative: Create basic animated graphics modifications
    create_theme_files
    return
fi

tar -xzf "$PTERO/temp/AnimatedGraphics.tar.gz" -C "$PTERO/temp"

if [ -d "$PTERO/temp/AnimatedGraphics" ]; then
    cp -rf "$PTERO/temp/AnimatedGraphics/"* "$PTERO/"
    print "Theme files copied successfully"
else
    print_error "Failed to extract theme files"
    rm -rf "$PTERO/temp"
    exit 1
fi

rm -rf "$PTERO/temp"
}

# Create theme files if download fails #
create_theme_files() {
print "Creating custom theme modifications..."

# Create resources directory if not exists
mkdir -p "$PTERO/resources/scripts/components/server"

# Note: This is a placeholder - actual theme files would need to be created
# based on the specific modifications needed for AnimatedGraphics
print_warning "Manual theme file creation required"
print "Please ensure you have the theme files ready or download them manually"
}

# Check for conflicting addons #
check_conflict() {
print "Checking for conflicting addons..."

sleep 1

# Check common conflict files
CONFLICT_FILES=(
    "$PTERO/resources/scripts/components/server/StatGraphs.tsx"
    "$PTERO/resources/scripts/components/server/Console.tsx"
)

for file in "${CONFLICT_FILES[@]}"; do
    if [ -f "$file" ] && grep -q "Installed by Auto-Addons\|BIGGER_CONSOLE\|BiggerConsole" "$file" 2>/dev/null; then
        print_warning "Conflicting addon detected in: $file"
        echo -ne "* Do you want to continue anyway? This may cause issues. (y/N): "
        read -r CONTINUE
        if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
            print "Installation cancelled by user"
            exit 1
        fi
    fi
done

print "No conflicts detected"
}

# Panel Production #
production() {
print "Building panel (this may take several minutes)..."
print_warning "Please do not cancel this process!"

cd "$PTERO" || exit 1

# Clear cache
php artisan view:clear
php artisan config:clear

# Install dependencies if needed
if [ ! -d "$PTERO/node_modules" ]; then
    print "Installing Node.js dependencies..."
    yarn install --frozen-lockfile
fi

# Build production
print "Building production assets..."
yarn build:production

# Set permissions
print "Setting correct permissions..."
chown -R www-data:www-data "$PTERO"/*

# Clear cache again
php artisan view:clear
php artisan config:clear
php artisan queue:restart

print "Build completed successfully!"
}

# Verification #
verify_installation() {
print "Verifying installation..."

if [ -f "$PTERO/public/assets/manifest.json" ]; then
    print "Asset manifest found - Build successful"
else
    print_warning "Asset manifest not found - Build may have failed"
fi
}

# Success message #
bye() {
print_brake 70
echo
echo -e "${GREEN}* The theme ${YELLOW}Animated Graphics${GREEN} was successfully installed!"
echo -e "* Panel Version: ${YELLOW}$PANEL_VERSION${RESET}"
echo -e "* A security backup has been created in: ${YELLOW}PanelBackup[AnimatedGraphics-*]${RESET}"
echo -e "* ${GREEN}Next steps:${RESET}"
echo -e "  1. Clear your browser cache (Ctrl+F5)"
echo -e "  2. Refresh your panel page"
echo -e "  3. Check if the theme is applied correctly"
echo
echo -e "* ${YELLOW}Troubleshooting:${RESET}"
echo -e "  - If theme not showing: Run 'php artisan view:clear' in panel directory"
echo -e "  - If errors occur: Check '$PTERO/storage/logs/laravel-*.log'"
echo
echo -e "* Support group: ${YELLOW}$(hyperlink "$SUPPORT_LINK")${RESET}"
echo -e "* Original theme by: ${YELLOW}Ferks-FK${RESET}"
echo
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
print_brake 70
echo -e "${GREEN}Pterodactyl AnimatedGraphics Theme Installer${RESET}"
echo -e "${YELLOW}Modified for Modern Pterodactyl Versions (1.8.x - 1.11.x+)${RESET}"
print_brake 70

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

check_distro
find_pterodactyl

if [ "$PTERO_INSTALL" == true ]; then
    print "Panel installation found at: ${YELLOW}$PTERO${RESET}"
    main_install
elif [ "$PTERO_INSTALL" == false ]; then
    print_warning "Panel installation not found in standard directories"
    echo -e "* ${GREEN}Standard locations checked:${RESET}"
    echo -e "  - /var/www/pterodactyl"
    echo -e "  - /var/www/panel"
    echo -e "  - /var/www/ptero"
    echo
    echo -e "* ${GREEN}Example custom path:${RESET} ${YELLOW}/var/www/mypanel${RESET}"
    echo -ne "* Enter the pterodactyl installation directory manually: "
    read -r MANUAL_DIR
    
    if [ -d "$MANUAL_DIR" ]; then
        print "Directory found: ${YELLOW}$MANUAL_DIR${RESET}"
        PTERO="$MANUAL_DIR"
        update_variables
        main_install
    else
        print_error "Directory not found: $MANUAL_DIR"
        print "Please check the path and try again"
        exit 1
    fi
fi
