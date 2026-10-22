#!/usr/bin/env bash
# Hạn chế quyền MySQL: xóa root từ xa, thu hẹp quyền của user ứng dụng
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; source .env; set +a

docker compose exec -T -e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" db mysql -uroot <<SQL
DROP USER IF EXISTS 'root'@'%';
REVOKE ALL PRIVILEGES, GRANT OPTION FROM '${MYSQL_USER}'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
SQL

echo "=== Quyền của ${MYSQL_USER} ==="
docker compose exec -T -e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" db mysql -uroot -e "SHOW GRANTS FOR '${MYSQL_USER}'@'%';"
echo "=== Danh sách tài khoản ==="
docker compose exec -T -e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" db mysql -uroot -e "SELECT user,host FROM mysql.user ORDER BY user;"
