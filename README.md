# Magento 2 Docker Setup

A fully containerized local development environment for multiple Magento 2 projects
with HTTPS, shared services, and per-project isolation.

## Stack

| Service      | Image                          | Version  |
|--------------|--------------------------------|----------|
| Nginx        | nginx:alpine                   | 1.26     |
| PHP-FPM      | php (custom build)             | 8.3      |
| MariaDB      | mariadb                        | 10.6     |
| Redis        | redis:alpine                   | 7        |
| OpenSearch   | opensearchproject/opensearch   | 2.15     |
| RabbitMQ     | rabbitmq:management            | 3        |
| Mailpit      | axllent/mailpit                | latest   |
| phpMyAdmin   | phpmyadmin                     | latest   |
| Node.js      | node:alpine                    | 20       |

## Folder Structure

```text
docker/
├── .env.example
├── .env                          ← copied from .env.example (git-ignored)
├── docker-compose.yml
├── README.md
├── logs/
│   ├── nginx/
│   └── php-fpm/
├── mysql/
│   ├── conf.d/
│   │   └── my.cnf
│   ├── init/
│   │   └── init.sql              ← creates all project databases on first run
│   └── data/                     ← persistent MariaDB data (git-ignored)
├── nginx/
│   ├── conf.d/
│   │   ├── mydemo1.conf          ← virtual host for mydemo1.local
│   │   └── mydemo2.conf          ← virtual host for mydemo2.local
│   └── ssl/
│       ├── mydemo1.local.crt     ← self-signed SSL (generated)
│       ├── mydemo1.local.key     ← self-signed SSL (generated)
│       ├── mydemo2.local.crt     ← self-signed SSL (generated)
│       └── mydemo2.local.key     ← self-signed SSL (generated)
├── opensearch/
│   └── data/                     ← persistent OpenSearch data (git-ignored)
├── php-fpm/
│   ├── Dockerfile
│   └── php.ini
├── phpmyadmin/
├── rabbitmq/                     ← persistent RabbitMQ data (git-ignored)
├── redis/
│   └── data/                     ← persistent Redis data (git-ignored)
├── mailpit/                      ← persistent Mailpit data (git-ignored)
├── node/
├── src/
│   ├── mydemo1/                  ← Magento 2 project 1 source
│   └── mydemo2/                  ← Magento 2 project 2 source
└── scripts/
    ├── gen-ssl.sh                ← generates SSL certs for all projects
    ├── setup.sh                  ← starts all containers
    ├── setup-mydemo1.sh          ← installs Magento into mydemo1/
    ├── setup-mydemo2.sh          ← installs Magento into mydemo2/
    └── node-setup.sh             ← runs npm install inside node container
```

## Project URLs

| Project   | Frontend                    | Admin                              |
|-----------|-----------------------------|------------------------------------|
| mydemo1   | https://mydemo1.local       | https://mydemo1.local/admin        |
| mydemo2   | https://mydemo2.local       | https://mydemo2.local/admin        |

## Shared Services

| Service      | URL / Port                        |
|--------------|-----------------------------------|
| phpMyAdmin   | http://localhost:8080             |
| Mailpit UI   | http://localhost:8025             |
| RabbitMQ UI  | http://localhost:15672            |
| OpenSearch   | http://localhost:9200             |
| Redis        | localhost:6379                    |
| MariaDB      | localhost:3306                    |

All projects share the same Nginx, PHP-FPM, MariaDB, Redis, OpenSearch, RabbitMQ,
and Mailpit containers. Each project has its own virtual host, SSL certificate,
database, and OpenSearch index prefix.

## Prerequisites

- Docker Desktop or Docker Engine + Compose plugin installed
- `openssl` available on your host machine (for SSL generation)
- Adobe Commerce Marketplace credentials (for `composer create-project`)

## First-Time Setup

### Step 1 — Add hosts entries (run once on your host machine)

```bash
sudo bash -c 'echo "127.0.0.1 mydemo1.local mydemo2.local" >> /etc/hosts'
```

On Windows (WSL2), edit `C:\Windows\System32\drivers\etc\hosts` and add:
127.0.0.1   mydemo1.local   mydemo2.local

### Step 2 — Copy the environment file

```bash
cd docker/
cp .env.example .env
```

Edit `.env` if you want to change passwords or add Magento Marketplace credentials.

### Step 3 — Generate SSL certificates

```bash
chmod +x scripts/gen-ssl.sh
./scripts/gen-ssl.sh
```

This creates self-signed certificates in `nginx/ssl/` for each project domain.
Accept the browser security warning on first visit, or trust the cert in your OS
keychain to remove it permanently.

### Step 4 — Start all containers

```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

This builds the PHP-FPM image and starts all services. Wait for OpenSearch and
MariaDB to be ready (about 20–30 seconds).

### Step 5 — Install Magento projects

Install each project independently:

```bash
chmod +x scripts/setup-mydemo1.sh scripts/setup-mydemo2.sh
./scripts/setup-mydemo1.sh
./scripts/setup-mydemo2.sh
```

Each script:
1. Downloads Magento via Composer into `src/projectname/`
2. Runs `bin/magento setup:install` with HTTPS, Redis, OpenSearch, and RabbitMQ
3. Sets developer mode and flushes cache

### Step 6 — Node.js (optional, for frontend builds)

```bash
chmod +x scripts/node-setup.sh
./scripts/node-setup.sh
```

## Adding a New Project

To add a third project `mydemo3`:

1. Add host entry:
   ```bash
   sudo bash -c 'echo "127.0.0.1 mydemo3.local" >> /etc/hosts'
   ```

2. Add `mydemo3.local` to the loop in `scripts/gen-ssl.sh` and re-run it.

3. Create `nginx/conf.d/mydemo3.conf` — copy `mydemo1.conf` and replace all
   `mydemo1` references with `mydemo3`.

4. Add the new database to `mysql/init/init.sql`:
   ```sql
   CREATE DATABASE IF NOT EXISTS mydemo3 ...;
   CREATE USER IF NOT EXISTS 'mydemo3'@'%' ...;
   GRANT ALL PRIVILEGES ON mydemo3.* TO 'mydemo3'@'%';
   FLUSH PRIVILEGES;
   ```
   > Note: `init.sql` only runs on a **fresh** MariaDB data volume. If the
   > container has already started, create the DB manually via phpMyAdmin or:
   > `docker compose exec db mysql -uroot -proot -e "SOURCE /docker-entrypoint-initdb.d/init.sql;"`

5. Add volume mounts for `src/mydemo3` in `docker-compose.yml` under both
   `php-fpm` and `nginx` services.

6. Copy `scripts/setup-mydemo1.sh` to `scripts/setup-mydemo3.sh` and replace
   all `mydemo1` references with `mydemo3`.

7. Run:
   ```bash
   docker compose restart nginx
   ./scripts/setup-mydemo3.sh
   ```

## Useful Commands

```bash
# Start all containers
docker compose up -d

# Stop all containers
docker compose down

# Rebuild PHP-FPM image
docker compose build php-fpm

# Open PHP-FPM shell for a project
docker compose exec php-fpm bash
cd /var/www/html/mydemo1

# Run Magento CLI for mydemo1
docker compose exec php-fpm bash -lc "cd /var/www/html/mydemo1 && bin/magento cache:flush"

# View Nginx logs
tail -f logs/nginx/error.log

# View PHP-FPM logs
tail -f logs/php-fpm/error.log

# Access MariaDB
docker compose exec db mysql -uroot -proot

# Wipe and restart everything (destructive!)
docker compose down -v
rm -rf mysql/data opensearch/data redis/data rabbitmq
docker compose up -d --build
```

## Notes

- **SSL warnings** — Browsers will warn about self-signed certs. Either accept
  the warning or import the `.crt` file into your OS/browser trust store.
- **Magento marketplace keys** — When Composer asks for authentication, enter
  your Public Key as username and Private Key as password from
  https://marketplace.magento.com/customer/accessKeys/
- **Email testing** — All outgoing mail is captured by Mailpit. No real emails
  are sent. View them at http://localhost:8025.
- **Session isolation** — Each project uses a different Redis database index
  (db 0 for mydemo1, db 1 for mydemo2) to avoid session/cache collisions.
- **OpenSearch isolation** — Each project uses a unique index prefix
  (`mydemo1_`, `mydemo2_`) so indexes do not conflict.
- **Developer mode** — All projects are installed in `developer` mode by default.
  Switch to `production` mode before any performance testing.
- **Data persistence** — MariaDB, Redis, OpenSearch, RabbitMQ, and Mailpit data
  are stored in local folders and survive container restarts. Delete the folders
  to start fresh.