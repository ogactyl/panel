# Ogactyl Panel - Installation Guide

## Requirements
- PHP 8.1+ with extensions: bcmath, ctype, fileinfo, json, mbstring, openssl, pdo, tokenizer, xml, gd, zip, curl
- MySQL 5.7+ or MariaDB 10.2+
- Redis 6+
- Node.js 18+ & Yarn
- Composer 2+
- Nginx or Apache

## Installation Steps

### 1. Upload files
```bash
cd /var/www
git clone or upload the panel files
cd ogactyl
chmod -R 755 storage bootstrap/cache
```

### 2. Install dependencies
```bash
composer install --no-dev --optimize-autoloader
yarn install
yarn build:production
```

### 3. Configure environment
```bash
cp .env.example .env
php artisan key:generate --force
```
Edit `.env` file:
```
APP_NAME="Ogactyl"
APP_URL=https://your-domain.com
DB_HOST=127.0.0.1
DB_DATABASE=ogactyl
DB_USERNAME=ogactyl
DB_PASSWORD=yourpassword
CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis
REDIS_HOST=127.0.0.1
```

### 4. Database setup
```bash
php artisan migrate --seed --force
```
This will:
- Create all database tables
- Seed all **251 game eggs** across **67 nests** automatically!

### 5. Create admin user
```bash
php artisan p:user:make
```

### 6. Set permissions
```bash
chown -R www-data:www-data /var/www/ogactyl
chmod -R 755 storage bootstrap/cache
```

### 7. Queue worker (systemd)
```bash
php artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
```

## Eggs Included (251 total across 67 nests)
- **Minecraft** (53 eggs) - Java, Bedrock, Forge, Fabric, Paper, Spigot, Bungeecord, Velocity...
- **Survival** (32 eggs) - Valheim, ARK, DayZ, Project Zomboid, V Rising, Palworld, Enshrouded...
- **Sandbox** (31 eggs) - Terraria, Satisfactory, Factorio, Space Engineers, Eco, Vintage Story...
- **Source Engine** (26 eggs) - CS2, Garry's Mod, L4D2, TF2 Classic, Insurgency...
- **FPS Shooters** (21 eggs) - Squad, Arma, KF2, CoD, Quake, Doom...
- **GTA Roleplay** (10 eggs) - FiveM, AltV, RageMP, RedM...
- **Racing** (10 eggs) - Assetto Corsa, BeamNG, Trackmania...
- **Rust** (3 eggs) - Standard, Autowipe, Staging
- **VR Games** (3 eggs) - Pavlov VR, NeosVR, Resonite
- ...and 58 more nests!

## Theme (Ogactyl/@shivambroog)
The panel uses the Ogactyl theme (based on Arix v1.3.1).
Configure theme settings in Admin Panel → Settings → Ogactyl Theme.
