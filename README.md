# 🧾 ProCash — Telegram бот для оплаты заказа в ресторане

Telegram-бот и веб-сервер, интегрированный с r-Keeper и платёжной системой FreedomPay. Клиент сканирует QR, получает счёт, оплачивает, а бот уведомляет его и сохраняет информацию об оплате.

---

## ⚙️ Стек технологий

- [x] Ruby 3.x
- [x] [Roda](https://roda.jeremyevans.net/)
- [x] [Sequel](https://sequel.jeremyevans.net/) + SQLite
- [x] Telegram Bot API
- [x] FreedomPay API (init_payment.php)
- [x] r-Keeper API (White Server)

---

## 🚀 Запуск

1. Установи зависимости:

bundle install

2. Запусти веб-сервер:

rackup -p 8080