#!/bin/bash

set -e

cd /var/www/html

echo "Waiting MySQL..."

until mysqladmin ping \
  --protocol=TCP \
  --ssl=0 \
  -h "$MYSQL_HOST" \
  -u root \
  -p"$MYSQL_ROOT_PASSWORD" \
  --silent; do

  echo "MySQL not ready..."
  sleep 3

done

echo "MySQL OK"

echo "Waiting OpenSearch..."

until curl -s "http://$OPENSEARCH_HOST:$OPENSEARCH_PORT" > /dev/null; do

  echo "OpenSearch not ready..."
  sleep 3

done

echo "OpenSearch OK"

echo "Waiting Redis..."

until redis-cli -h "$REDIS_HOST" ping > /dev/null; do

  echo "Redis not ready..."
  sleep 3

done

echo "Redis OK"

if [ ! -s app/etc/env.php ] || ! grep -q "'crypt'" app/etc/env.php; then

    echo "Magento not installed"

    php -d memory_limit=-1 bin/magento setup:install \
      --base-url="$MAGENTO_BASE_URL" \
      --db-host="$MYSQL_HOST" \
      --db-name="$MYSQL_DATABASE" \
      --db-user="$MYSQL_USER" \
      --db-password="$MYSQL_PASSWORD" \
      --admin-firstname="$MAGENTO_ADMIN_FIRSTNAME" \
      --admin-lastname="$MAGENTO_ADMIN_LASTNAME" \
      --admin-email="$MAGENTO_ADMIN_EMAIL" \
      --admin-user="$MAGENTO_ADMIN_USER" \
      --admin-password="$MAGENTO_ADMIN_PASSWORD" \
      --language="$MAGENTO_LANGUAGE" \
      --currency="$MAGENTO_CURRENCY" \
      --timezone="$MAGENTO_TIMEZONE" \
      --use-rewrites=1 \
      --backend-frontname="$MAGENTO_BACKEND_FRONTNAME" \
      --search-engine=opensearch \
      --opensearch-host="$OPENSEARCH_HOST" \
      --opensearch-port="$OPENSEARCH_PORT" \
      --cache-backend=redis \
      --cache-backend-redis-server="$REDIS_HOST" \
      --cache-backend-redis-db=0 \
      --page-cache=redis \
      --page-cache-redis-server="$REDIS_HOST" \
      --page-cache-redis-db=1 \
      --session-save=redis \
      --session-save-redis-host="$REDIS_HOST" \
      --session-save-redis-db=2

    echo "Magento installed"

else

    echo "Magento already installed"

fi

if [ ! -d generated/code ] || [ -z "$(find generated/code -type f 2>/dev/null)" ]; then

    echo "Running DI compile..."

    php -d memory_limit=-1 \
      bin/magento setup:di:compile

else

    echo "Generated code already exists"

fi

if [ ! -d pub/static/frontend ] || [ -z "$(find pub/static/frontend -type f 2>/dev/null)" ]; then

    echo "Deploying static content..."

    sleep 30

    php -d memory_limit=-1 \
      bin/magento setup:static-content:deploy -f pt_BR en_US

else

    echo "Static content already exists"

fi

echo "Fixing permissions..."

chown -R 33:33 app/etc pub/media generated pub/static

echo "Magento bootstrap finished"

exec php-fpm