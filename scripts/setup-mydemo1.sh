#!/usr/bin/env bash
set -e
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

bash scripts/gen-ssl.sh

if [ -z "$(ls -A src/mydemo1 2>/dev/null)" ]; then
  docker compose exec php-fpm bash -lc "composer create-project \
    --repository-url=https://repo.magento.com/ \
    magento/project-community-edition=2.4.8 \
    /var/www/html/mydemo1"
fi

docker compose exec php-fpm bash -lc "
cd /var/www/html/mydemo1 && bin/magento setup:install \
  --base-url=https://mydemo1.local/ \
  --base-url-secure=https://mydemo1.local/ \
  --use-secure=1 \
  --use-secure-admin=1 \
  --db-host=db \
  --db-name=mydemo1 \
  --db-user=mydemo1 \
  --db-password=mydemo1pass \
  --admin-firstname=Admin \
  --admin-lastname=User \
  --admin-email=admin@mydemo1.local \
  --admin-user=admin \
  --admin-password=Admin123!@# \
  --language=en_US \
  --currency=USD \
  --timezone=Asia/Kolkata \
  --use-rewrites=1 \
  --search-engine=opensearch \
  --opensearch-host=opensearch \
  --opensearch-port=9200 \
  --opensearch-index-prefix=mydemo1 \
  --session-save=redis \
  --session-save-redis-host=redis \
  --cache-backend=redis \
  --cache-backend-redis-server=redis \
  --page-cache=redis \
  --page-cache-redis-server=redis \
  --amqp-host=rabbitmq \
  --amqp-port=5672 \
  --amqp-user=guest \
  --amqp-password=guest
"

docker compose exec php-fpm bash -lc "
cd /var/www/html/mydemo1 && \
bin/magento deploy:mode:set developer && \
bin/magento cache:flush && \
bin/magento indexer:reindex
"
echo "mydemo1 ready at https://mydemo1.local"