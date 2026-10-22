#!/usr/bin/env bash
# Sinh mật khẩu Grafana/exporter, tạo user DB quyền tối thiểu cho mysqld-exporter
set -euo pipefail
cd "$(dirname "$0")/.."

[ -f .env ] || { echo "Thiếu file .env"; exit 1; }
if [ -n "$(tail -c1 .env)" ]; then echo >> .env; fi
grep -q '^EXPORTER_PASSWORD=' .env || echo "EXPORTER_PASSWORD=$(openssl rand -hex 16)" >> .env
grep -q '^GRAFANA_ADMIN_PASSWORD=' .env || echo "GRAFANA_ADMIN_PASSWORD=$(openssl rand -hex 16)" >> .env
set -a; source .env; set +a

echo "Đợi MySQL sẵn sàng..."
until docker compose exec -T -e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" db mysqladmin ping -uroot --silent >/dev/null 2>&1; do
  sleep 3
done

docker compose exec -T -e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" db mysql -uroot <<SQL
CREATE USER IF NOT EXISTS 'exporter'@'%' IDENTIFIED BY '${EXPORTER_PASSWORD}' WITH MAX_USER_CONNECTIONS 3;
ALTER USER 'exporter'@'%' IDENTIFIED BY '${EXPORTER_PASSWORD}';
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'%';
FLUSH PRIVILEGES;
SQL

mkdir -p monitoring/mysqld-exporter
cat > monitoring/mysqld-exporter/.my.cnf <<CNF
[client]
user=exporter
password=${EXPORTER_PASSWORD}
CNF
chmod 644 monitoring/mysqld-exporter/.my.cnf

echo "Xong. Grafana đăng nhập: admin / ${GRAFANA_ADMIN_PASSWORD}"
