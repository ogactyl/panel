#!/usr/bin/env bash
# ============================================================
#   ██████╗  ██████╗  █████╗  ██████╗████████╗██╗   ██╗██╗
#  ██╔═══██╗██╔════╝ ██╔══██╗██╔════╝╚══██╔══╝╚██╗ ██╔╝██║
#  ██║   ██║██║  ███╗███████║██║        ██║    ╚████╔╝ ██║
#  ██║   ██║██║   ██║██╔══██║██║        ██║     ╚██╔╝  ██║
#  ╚██████╔╝╚██████╔╝██║  ██║╚██████╗   ██║      ██║   ███████╗
#   ╚═════╝  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝   ╚═╝      ╚═╝   ╚══════╝
#
#   Ogactyl Panel — One-Click Auto Installer v1.0
#   Supports: Ubuntu 20.04, 22.04, Debian 11, 12
# ============================================================

set -euo pipefail
IFS=$'\n\t'

# ── COLORS ─────────────────────────────────────────────────
RED='\033[0;31m';GREEN='\033[0;32m';YELLOW='\033[1;33m'
CYAN='\033[0;36m';BLUE='\033[0;34m';BOLD='\033[1m';NC='\033[0m'

# ── HELPERS ─────────────────────────────────────────────────
info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }
step()    { echo -e "\n${BOLD}${BLUE}━━━ $* ${NC}\n"; }
ask()     { echo -en "${CYAN}  → ${NC}$* "; }

# ── BANNER ──────────────────────────────────────────────────
clear
echo -e "${CYAN}"
cat << 'EOF'
  ██████╗  ██████╗  █████╗  ██████╗████████╗██╗   ██╗██╗
 ██╔═══██╗██╔════╝ ██╔══██╗██╔════╝╚══██╔══╝╚██╗ ██╔╝██║
 ██║   ██║██║  ███╗███████║██║        ██║    ╚████╔╝ ██║
 ██║   ██║██║   ██║██╔══██║██║        ██║     ╚██╔╝  ██║
 ╚██████╔╝╚██████╔╝██║  ██║╚██████╗   ██║      ██║   ███████╗
  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝   ╚═╝      ╚═╝   ╚══════╝
EOF
echo -e "${NC}"
echo -e "  ${BOLD}One-Click Panel Installer${NC} — v1.0"
echo -e "  ${CYAN}https://ogactyl.io${NC}\n"
echo -e "  This script will install:"
echo -e "  ${GREEN}✓${NC} PHP 8.2 + all extensions"
echo -e "  ${GREEN}✓${NC} MySQL / MariaDB"
echo -e "  ${GREEN}✓${NC} Nginx + SSL (Let's Encrypt)"
echo -e "  ${GREEN}✓${NC} Composer"
echo -e "  ${GREEN}✓${NC} Redis"
echo -e "  ${GREEN}✓${NC} Queue Worker (systemd)"
echo -e "  ${GREEN}✓${NC} Cron Jobs"
echo -e "  ${GREEN}✓${NC} Ogactyl Panel (latest)"
echo -e "  ${GREEN}✓${NC} Admin user\n"

# ── ROOT CHECK ───────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
  error "This installer must be run as root. Use: sudo bash install.sh"
fi

# ── OS DETECTION ─────────────────────────────────────────────
if [[ -f /etc/os-release ]]; then
  source /etc/os-release
  OS_ID="${ID:-unknown}"
  OS_VER="${VERSION_ID:-0}"
else
  error "Cannot detect OS. Only Ubuntu 20.04/22.04 and Debian 11/12 are supported."
fi

case "$OS_ID" in
  ubuntu)
    if [[ "$OS_VER" != "20.04" && "$OS_VER" != "22.04" && "$OS_VER" != "24.04" ]]; then
      warn "Untested Ubuntu version: $OS_VER. Proceeding anyway..."
    fi
    ;;
  debian)
    if [[ "$OS_VER" != "11" && "$OS_VER" != "12" ]]; then
      warn "Untested Debian version: $OS_VER. Proceeding anyway..."
    fi
    ;;
  *)
    error "Unsupported OS: $OS_ID. Only Ubuntu and Debian are supported."
    ;;
esac
success "OS detected: ${OS_ID^} $OS_VER"

# ── COLLECT USER INPUT ────────────────────────────────────────
echo -e "\n${BOLD}Please answer a few questions before we begin:${NC}\n"

ask "Panel domain (e.g. panel.yourdomain.com):"
read -r PANEL_DOMAIN
[[ -z "$PANEL_DOMAIN" ]] && error "Domain cannot be empty."

ask "Enable SSL with Let's Encrypt? (y/n) [y]:"
read -r ENABLE_SSL
ENABLE_SSL="${ENABLE_SSL:-y}"

ask "MySQL root password (leave blank to auto-generate):"
read -rs MYSQL_ROOT_PASS
echo ""
if [[ -z "$MYSQL_ROOT_PASS" ]]; then
  MYSQL_ROOT_PASS=$(openssl rand -base64 20 | tr -dc 'A-Za-z0-9' | head -c 20)
  warn "Auto-generated MySQL root password: ${BOLD}${MYSQL_ROOT_PASS}${NC}"
  warn "Save this somewhere safe!"
fi

ask "MySQL panel database name [ogactyl]:"
read -r DB_NAME
DB_NAME="${DB_NAME:-ogactyl}"

ask "MySQL panel user [ogactyl]:"
read -r DB_USER
DB_USER="${DB_USER:-ogactyl}"

ask "MySQL panel password (leave blank to auto-generate):"
read -rs DB_PASS
echo ""
if [[ -z "$DB_PASS" ]]; then
  DB_PASS=$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9' | head -c 16)
  info "Auto-generated DB password: ${BOLD}${DB_PASS}${NC}"
fi

echo -e "\n${BOLD}Admin account setup:${NC}"
ask "Admin email:"
read -r ADMIN_EMAIL
[[ -z "$ADMIN_EMAIL" ]] && error "Email cannot be empty."

ask "Admin username [admin]:"
read -r ADMIN_USER
ADMIN_USER="${ADMIN_USER:-admin}"

ask "Admin first name:"
read -r ADMIN_FIRST
ADMIN_FIRST="${ADMIN_FIRST:-Admin}"

ask "Admin last name:"
read -r ADMIN_LAST
ADMIN_LAST="${ADMIN_LAST:-User}"

ask "Admin password (min 8 chars):"
read -rs ADMIN_PASS
echo ""
[[ ${#ADMIN_PASS} -lt 8 ]] && error "Password must be at least 8 characters."

# ── CONFIRM ──────────────────────────────────────────────────
echo -e "\n${BOLD}━━━ Installation Summary ━━━${NC}"
echo -e "  Domain  : ${CYAN}${PANEL_DOMAIN}${NC}"
echo -e "  SSL     : ${CYAN}${ENABLE_SSL}${NC}"
echo -e "  DB Name : ${CYAN}${DB_NAME}${NC}"
echo -e "  DB User : ${CYAN}${DB_USER}${NC}"
echo -e "  Admin   : ${CYAN}${ADMIN_EMAIL}${NC}"
echo ""
ask "Looks good? Start installation? (y/n):"
read -r CONFIRM
[[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]] && error "Installation cancelled."

# ── LOG FILE ─────────────────────────────────────────────────
LOG_FILE="/var/log/ogactyl-install.log"
exec > >(tee -a "$LOG_FILE") 2>&1
info "Install log: $LOG_FILE"

# ── STEP 1: UPDATE SYSTEM ────────────────────────────────────
step "Step 1/9 — Updating System"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y
success "System updated"

# ── STEP 2: PHP + DEPS ───────────────────────────────────────
step "Step 2/9 — Installing PHP 8.2 & Dependencies"

# Add PHP repo
if [[ "$OS_ID" == "ubuntu" ]]; then
  apt-get install -y software-properties-common
  add-apt-repository -y ppa:ondrej/php
  apt-get update -y
elif [[ "$OS_ID" == "debian" ]]; then
  apt-get install -y apt-transport-https lsb-release ca-certificates curl
  curl -sSLo /tmp/debsuryorg-archive-keyring.deb https://packages.sury.org/php/apt.gpg
  apt-key add /tmp/debsuryorg-archive-keyring.deb 2>/dev/null || true
  echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
  apt-get update -y
fi

apt-get install -y \
  php8.2 \
  php8.2-cli \
  php8.2-gd \
  php8.2-mysql \
  php8.2-pdo \
  php8.2-mbstring \
  php8.2-tokenizer \
  php8.2-bcmath \
  php8.2-xml \
  php8.2-fpm \
  php8.2-curl \
  php8.2-zip \
  php8.2-intl \
  php8.2-sqlite3 \
  php8.2-redis \
  nginx \
  mariadb-server \
  redis-server \
  tar unzip curl wget git certbot \
  python3-certbot-nginx

success "PHP 8.2, Nginx, MariaDB, Redis installed"

# ── STEP 3: MYSQL SETUP ──────────────────────────────────────
step "Step 3/9 — Configuring MySQL"

systemctl enable --now mariadb

# Set root password & secure install
mysql -u root <<MYSQL_SCRIPT
ALTER USER IF EXISTS 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASS}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
CREATE USER IF NOT EXISTS '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'127.0.0.1';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

success "MySQL configured — database '${DB_NAME}' created"

# ── STEP 4: COMPOSER ─────────────────────────────────────────
step "Step 4/9 — Installing Composer"

if ! command -v composer &>/dev/null; then
  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
fi
success "Composer $(composer --version 2>/dev/null | grep -oP 'Composer \K[\d.]+') installed"

# ── STEP 5: DOWNLOAD PANEL ───────────────────────────────────
step "Step 5/9 — Downloading Ogactyl Panel"

mkdir -p /var/www/ogactyl
cd /var/www/ogactyl

# Try GitHub releases first
RELEASE_URL="https://github.com/ogactyl/panel/releases/latest/download/panel.tar.gz"
info "Downloading from: $RELEASE_URL"

if curl -fsSL -o panel.tar.gz "$RELEASE_URL" 2>/dev/null; then
  tar -xzf panel.tar.gz
  rm -f panel.tar.gz
  success "Panel downloaded and extracted"
else
  warn "Release download failed. Attempting git clone..."
  if command -v git &>/dev/null; then
    git clone https://github.com/ogactyl/panel.git /tmp/ogactyl-panel
    cp -r /tmp/ogactyl-panel/. /var/www/ogactyl/
    rm -rf /tmp/ogactyl-panel
    success "Panel cloned from git"
  else
    error "Could not download panel. Please check your internet connection and try again."
  fi
fi

chmod -R 755 storage/* bootstrap/cache/

# ── STEP 6: CONFIGURE ENV ────────────────────────────────────
step "Step 6/9 — Configuring Environment"

cp .env.example .env

# Generate app key
php artisan key:generate --force

# Write .env values
APP_KEY=$(grep '^APP_KEY=' .env | cut -d= -f2)

cat > .env <<ENV_EOF
APP_NAME="Ogactyl"
APP_ENV=production
APP_KEY=${APP_KEY}
APP_DEBUG=false
APP_THEME=ogactyl
APP_URL=https://${PANEL_DOMAIN}
APP_TIMEZONE=UTC
APP_LOCALE=en

LOG_CHANNEL=daily
LOG_LEVEL=error

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=${DB_NAME}
DB_USERNAME=${DB_USER}
DB_PASSWORD=${DB_PASS}

CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis

REDIS_HOST=127.0.0.1
REDIS_PORT=6379

MAIL_MAILER=log
MAIL_FROM_ADDRESS="panel@${PANEL_DOMAIN}"
MAIL_FROM_NAME="Ogactyl Panel"
ENV_EOF

success ".env configured"

# ── STEP 7: COMPOSER INSTALL + MIGRATIONS ────────────────────
step "Step 7/9 — Installing Dependencies & Running Migrations"

composer install --no-dev --optimize-autoloader --no-interaction
php artisan migrate --seed --force
chown -R www-data:www-data /var/www/ogactyl

success "Dependencies installed, database migrated, eggs seeded"

# ── STEP 8: NGINX + SSL ──────────────────────────────────────
step "Step 8/9 — Configuring Nginx"

# Initial HTTP-only config
cat > /etc/nginx/sites-available/ogactyl.conf <<NGINX_EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${PANEL_DOMAIN};

    root /var/www/ogactyl/public;
    index index.php;

    access_log /var/log/nginx/ogactyl.access.log;
    error_log  /var/log/nginx/ogactyl.error.log error;

    client_max_body_size 100m;
    client_body_timeout  120s;
    sendfile off;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass   unix:/run/php/php8.2-fpm.sock;
        fastcgi_index  index.php;
        include        fastcgi_params;
        fastcgi_param  SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_read_timeout 300;
    }

    location ~ /\.ht { deny all; }
}
NGINX_EOF

# Disable default site & enable ogactyl
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/ogactyl.conf /etc/nginx/sites-enabled/

nginx -t
systemctl enable --now nginx
systemctl restart nginx

success "Nginx configured"

# SSL via Certbot
if [[ "$ENABLE_SSL" == "y" || "$ENABLE_SSL" == "Y" ]]; then
  info "Requesting SSL certificate for ${PANEL_DOMAIN}..."
  if certbot --nginx -d "$PANEL_DOMAIN" --non-interactive --agree-tos -m "$ADMIN_EMAIL" 2>/dev/null; then
    success "SSL certificate obtained!"
  else
    warn "SSL setup failed — panel will run on HTTP only."
    warn "Make sure ${PANEL_DOMAIN} points to this server's IP."
    warn "Re-run SSL later: certbot --nginx -d ${PANEL_DOMAIN}"
  fi
fi

# ── STEP 9: QUEUE WORKER + CRON ──────────────────────────────
step "Step 9/9 — Setting Up Queue Worker & Cron Jobs"

# Systemd service
cat > /etc/systemd/system/ogactyl.service <<SERVICE_EOF
[Unit]
Description=Ogactyl Queue Worker
After=redis-server.service mysql.service mariadb.service
Wants=redis-server.service

[Service]
User=www-data
Group=www-data
WorkingDirectory=/var/www/ogactyl
Restart=always
ExecStart=/usr/bin/php /var/www/ogactyl/artisan queue:work --sleep=3 --tries=3 --max-time=3600
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
SERVICE_EOF

systemctl daemon-reload
systemctl enable --now ogactyl.service

# Cron job
CRON_LINE="* * * * * php /var/www/ogactyl/artisan schedule:run >> /dev/null 2>&1"
(crontab -l 2>/dev/null | grep -qF "ogactyl/artisan schedule:run") \
  || (crontab -l 2>/dev/null; echo "$CRON_LINE") | crontab -

success "Queue worker and cron job configured"

# ── CREATE ADMIN USER ────────────────────────────────────────
step "Creating Admin Account"

cd /var/www/ogactyl

php artisan p:user:make \
  --email="${ADMIN_EMAIL}" \
  --username="${ADMIN_USER}" \
  --name-first="${ADMIN_FIRST}" \
  --name-last="${ADMIN_LAST}" \
  --password="${ADMIN_PASS}" \
  --admin=1 2>/dev/null || \
php artisan tinker --execute="
\$u = new \Ogactyl\Models\User;
\$u->email = '${ADMIN_EMAIL}';
\$u->username = '${ADMIN_USER}';
\$u->name_first = '${ADMIN_FIRST}';
\$u->name_last = '${ADMIN_LAST}';
\$u->password = bcrypt('${ADMIN_PASS}');
\$u->root_admin = true;
\$u->language = 'en';
\$u->uuid = \Ramsey\Uuid\Uuid::uuid4()->toString();
\$u->save();
echo 'Admin user created.';
" 2>/dev/null || warn "Admin user creation via artisan failed — you can register at /auth/register"

success "Admin user created: ${ADMIN_EMAIL}"

# ── FINAL PERMISSIONS ────────────────────────────────────────
chown -R www-data:www-data /var/www/ogactyl
chmod -R 755 /var/www/ogactyl/storage /var/www/ogactyl/bootstrap/cache

# ── OPTIMIZE ─────────────────────────────────────────────────
php /var/www/ogactyl/artisan config:cache
php /var/www/ogactyl/artisan route:cache
php /var/www/ogactyl/artisan view:cache

# ── SUMMARY ──────────────────────────────────────────────────
PANEL_PROTO="http"
[[ "$ENABLE_SSL" == "y" || "$ENABLE_SSL" == "Y" ]] && PANEL_PROTO="https"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${BOLD}${GREEN}🎉  INSTALLATION COMPLETED SUCCESSFULLY!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${BOLD}Panel URL${NC}    : ${CYAN}${PANEL_PROTO}://${PANEL_DOMAIN}${NC}"
echo -e "  ${BOLD}Admin Email${NC}  : ${CYAN}${ADMIN_EMAIL}${NC}"
echo -e "  ${BOLD}DB User${NC}      : ${CYAN}${DB_USER}${NC}"
echo -e "  ${BOLD}DB Password${NC}  : ${CYAN}${DB_PASS}${NC}"
echo -e "  ${BOLD}DB Name${NC}      : ${CYAN}${DB_NAME}${NC}"
echo -e "  ${BOLD}MySQL Root${NC}   : ${CYAN}${MYSQL_ROOT_PASS}${NC}"
echo ""
echo -e "  ${YELLOW}⚠  Save the credentials above in a safe place!${NC}"
echo ""
echo -e "  ${BOLD}Next steps:${NC}"
echo -e "  ${GREEN}1.${NC} Visit ${CYAN}${PANEL_PROTO}://${PANEL_DOMAIN}${NC} and log in"
echo -e "  ${GREEN}2.${NC} Go to Admin → Nodes → Create Node"
echo -e "  ${GREEN}3.${NC} Install Wings on your game server node"
echo ""
echo -e "  ${BOLD}Useful commands:${NC}"
echo -e "  ${CYAN}systemctl status ogactyl${NC}   — Queue worker status"
echo -e "  ${CYAN}systemctl status nginx${NC}     — Web server status"
echo -e "  ${CYAN}systemctl status mariadb${NC}   — Database status"
echo -e "  ${CYAN}tail -f /var/log/nginx/ogactyl.error.log${NC}   — Error logs"
echo ""
echo -e "  ${BOLD}Install log saved to:${NC} ${LOG_FILE}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

