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

## Log tập trung (Loki + Promtail)

Promtail đọc log của mọi container trong project qua Docker API (gắn nhãn `service`, `container`),
đẩy về Loki (lưu 7 ngày). Xem log tại Grafana → Explore → datasource Loki, hoặc dashboard
`Recipe Website - Logs`. Lưu ý: Promtail đã EOL từ 03/2026 (thay thế bởi Grafana Alloy), đề bài yêu cầu Promtail
nên dùng bản cuối 3.6.0.

Ví dụ LogQL:

    {service="nginx"}
    {service="app"} |= "ERROR"
    {service="nginx"} | pattern `<ip> - [<_>] "<method> <uri> <_>" <status> <size> "<agent>" rt=<rt>` | status >= 400

## Hardening

| Nhóm | Biện pháp |
|---|---|
| Container | `no-new-privileges`, `cap_drop: ALL`, `read_only` (app, nginx, exporters), giới hạn mem/cpu/pids, xoay vòng log |
| Non-root | app (`USER node`), prometheus, grafana, loki, exporters chạy user thường; MySQL hạ quyền về `mysql` |
| Mạng | `frontend` và `backend` là `internal` (không ra Internet); `edge` chỉ nginx; `admin` chỉ phpMyAdmin; DB không publish port |
| Database | Xóa `root@%`; `recipe_user` chỉ `SELECT/INSERT/UPDATE/DELETE` trên DB `recipes`; `exporter` chỉ quyền đọc metrics |
| Nginx | HTTPS, security headers, rate limit (429), chỉ GET/HEAD/POST (405), chặn file ẩn, timeout chống slowloris, ẩn `X-Powered-By` |
| Bí mật | Mật khẩu ngẫu nhiên 32 ký tự, `.env` quyền 600, không commit secret |

Rủi ro chấp nhận: cAdvisor chạy `privileged` (đọc cgroup host) và Promtail mount `docker.sock` (đọc log container).
Hướng khắc phục production: dùng docker-socket-proxy, thay Promtail bằng Grafana Alloy.

### Chạy lần đầu trên máy mới (thứ tự đầy đủ)
    cp .env.example .env
    ./scripts/gen-cert.sh
    docker compose up -d db
    ./scripts/setup-monitoring.sh
    ./scripts/harden-db.sh
    docker compose up -d --build
