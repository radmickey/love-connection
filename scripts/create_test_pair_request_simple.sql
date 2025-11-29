-- Простая версия: создание тестового пользователя и pair request
-- Выполните этот запрос в вашей PostgreSQL базе данных

-- 1. Создаем тестового пользователя (если его еще нет)
-- Сначала проверяем по email
INSERT INTO users (id, email, username, apple_id, created_at)
SELECT 
    uuid_generate_v4(),
    'testpartner@example.com',
    'testpartner',
    'test.apple.id.' || uuid_generate_v4()::text,
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM users WHERE email = 'testpartner@example.com' OR username = 'testpartner'
);

-- 2. Создаем pair request от testpartner к radmickey
INSERT INTO pair_requests (requester_id, requested_id, status, created_at, updated_at)
SELECT
    u1.id,
    u2.id,
    'pending',
    NOW(),
    NOW()
FROM users u1
CROSS JOIN users u2
WHERE u1.username = 'testpartner'
  AND u2.username = 'radmickey'
ON CONFLICT (requester_id, requested_id) DO UPDATE
SET status = 'pending',
    updated_at = NOW();

-- 3. Проверяем результат
SELECT
    pr.id as request_id,
    u1.username as requester_username,
    u2.username as requested_username,
    pr.status,
    pr.created_at
FROM pair_requests pr
JOIN users u1 ON pr.requester_id = u1.id
JOIN users u2 ON pr.requested_id = u2.id
WHERE u2.username = 'radmickey'
  AND u1.username = 'testpartner'
ORDER BY pr.created_at DESC
LIMIT 1;

