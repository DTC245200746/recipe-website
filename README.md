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
