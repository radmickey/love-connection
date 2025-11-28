# Love Connection

iOS приложение для пар на расстоянии, где пользователи могут отправлять друг другу "love" через удержание анимированной кнопки-сердца.

## Структура проекта

- `iOS/` - iOS приложение на SwiftUI
- `backend/` - Backend сервер на Go с Gin framework
- `docker-compose.yml` - Конфигурация для запуска PostgreSQL и backend

## Требования

- Go 1.21+
- PostgreSQL 15+
- Docker и Docker Compose
- Xcode 14+ (для iOS разработки)

## Запуск Backend

1. Установите зависимости:
```bash
cd backend
go mod download
```

2. Настройте переменные окружения (создайте `.env` файл или экспортируйте):
```bash
export JWT_SECRET=your-secret-key
export APNS_KEY_PATH=/path/to/apns/key.p8
export APNS_KEY_ID=your-key-id
export APNS_TEAM_ID=your-team-id
export APNS_BUNDLE_ID=com.yourapp.loveconnection
```

3. Запустите через Docker Compose:
```bash
docker-compose up -d
```

Или запустите локально:
```bash
# Убедитесь что PostgreSQL запущен
cd backend
go run cmd/server/main.go
```

## Настройка iOS приложения

1. Откройте проект в Xcode
2. Обновите `Constants.swift` с URL вашего backend сервера
3. Настройте Sign in with Apple в Xcode capabilities
4. Настройте Push Notifications в Xcode capabilities

## API Endpoints

- `POST /api/auth/register` - Регистрация
- `POST /api/auth/login` - Вход
- `POST /api/auth/apple` - Sign in with Apple
- `GET /api/user/me` - Текущий пользователь
- `POST /api/user/device-token` - Обновить device token
- `POST /api/pairs/create` - Создать пару
- `GET /api/pairs/current` - Текущая пара
- `POST /api/love/send` - Отправить love событие
- `GET /api/love/history` - История событий
- `GET /api/stats` - Статистика

## Безопасность

Все меры безопасности из плана реализованы:
- HTTPS/TLS для всех соединений
- JWT токены с коротким временем жизни
- Bcrypt хеширование паролей
- Валидация всех входных данных
- Защита от SQL injection через prepared statements

