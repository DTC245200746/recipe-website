# Recipe Website – Đề 29

Website chia sẻ công thức nấu ăn: Node.js (Express) + MySQL + phpMyAdmin + Nginx (HTTPS tự ký).

## Yêu cầu
WSL2 (Ubuntu 22.04), Docker Engine + Docker Compose v2.

## Chạy hệ thống
    cp .env.example .env        # sửa mật khẩu mạnh (openssl rand -hex 16)
    ./scripts/gen-cert.sh       # tạo chứng chỉ tự ký
    docker compose up -d --build

## Truy cập
| Dịch vụ | URL |
|---|---|
| Website | https://localhost |
| phpMyAdmin | http://localhost:8081 |

## Kiến trúc
Browser → Nginx (443) → App (Node) → MySQL ; phpMyAdmin → MySQL.
Hai mạng Docker: `frontend` (nginx, app) và `backend` (app, db, phpmyadmin).

## Giám sát (Prometheus + Grafana)

| Dịch vụ | URL | Ghi chú |
|---|---|---|
| Prometheus | http://localhost:9090 | Xem Status → Targets |
| Grafana | http://localhost:3000 | user `admin`, mật khẩu trong `.env` (`GRAFANA_ADMIN_PASSWORD`) |

Thành phần: cAdvisor (container), nginx-prometheus-exporter (web server, đọc `stub_status`),
mysqld-exporter (database, user `exporter` quyền tối thiểu). Dashboard Grafana được provision tự động
từ `monitoring/grafana/`.

### Chạy lần đầu trên máy mới
    cp .env.example .env              # điền mật khẩu mạnh
    ./scripts/gen-cert.sh
    docker compose up -d db
    ./scripts/setup-monitoring.sh     # sinh mật khẩu + tạo user exporter
    docker compose up -d --build

### Mạng Docker
`frontend` (nginx, app) · `backend` (app, db, phpmyadmin, mysqld-exporter) · `monitoring` (nginx, exporters, prometheus, grafana).
