#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [ ! -f .env ]; then
  cp .env.example .env
fi

docker compose up -d --build

echo "Waiting for database and OpenSearch to start..."
sleep 25

if [ -z "$(ls -A src 2>/dev/null)" ]; then
  docker compose exec php-fpm bash -lc "composer create-project --repository-url=https://repo.magento.com/ \${MAGENTO_PROJECT}=\${MAGENTO_VERSION} /var/www/html"
fi

docker compose exec php-fpm bash -lc "
bin/magento setup:install \
  --base-url=\${MAGENTO_BASE_URL} \
  --db-host=\${MAGENTO_DB_HOST} \
  --db-name=\${MAGENTO_DB_NAME} \
  --db-user=\${MAGENTO_DB_USER} \
  --db-password=\${MAGENTO_DB_PASSWORD} \
  --admin-firstname=\${MAGENTO_ADMIN_FIRSTNAME} \
  --admin-lastname=\${MAGENTO_ADMIN_LASTNAME} \
  --admin-email=\${MAGENTO_ADMIN_EMAIL} \
  --admin-user=\${MAGENTO_ADMIN_USER} \
  --admin-password=\${MAGENTO_ADMIN_PASSWORD} \
  --language=\${MAGENTO_LANGUAGE} \
  --currency=\${MAGENTO_CURRENCY} \
  --timezone=\${MAGENTO_TIMEZONE} \
  --use-rewrites=1 \
  --search-engine=opensearch \
  --opensearch-host=\${MAGENTO_OPENSEARCH_HOST} \
  --opensearch-port=\${MAGENTO_OPENSEARCH_PORT} \
  --opensearch-index-prefix=\${MAGENTO_OPENSEARCH_INDEX_PREFIX} \
  --session-save=redis \
  --session-save-redis-host=\${MAGENTO_REDIS_HOST} \
  --session-save-redis-port=\${MAGENTO_REDIS_PORT} \
  --cache-backend=redis \
  --cache-backend-redis-server=\${MAGENTO_REDIS_HOST} \
  --cache-backend-redis-port=\${MAGENTO_REDIS_PORT} \
  --page-cache=redis \
  --page-cache-redis-server=\${MAGENTO_REDIS_HOST} \
  --page-cache-redis-port=\${MAGENTO_REDIS_PORT} \
  --amqp-host=\${MAGENTO_RABBITMQ_HOST} \
  --amqp-port=\${MAGENTO_RABBITMQ_PORT} \
  --amqp-user=\${MAGENTO_RABBITMQ_USER} \
  --amqp-password=\${MAGENTO_RABBITMQ_PASSWORD}
"

docker compose exec php-fpm bash -lc "
bin/magento deploy:mode:set developer &&
bin/magento cache:flush &&
bin/magento indexer:reindex
"

echo "Magento installation completed."
echo "Frontend: http://localhost"
echo "Admin URL: http://localhost/${MAGENTO_BACKEND_FRONTNAME}"