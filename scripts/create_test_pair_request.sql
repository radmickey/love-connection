-- Создание тестового пользователя и отправка pair request к пользователю radmickey

-- Шаг 1: Создаем тестового пользователя
WITH test_user AS (
    INSERT INTO users (id, email, username, apple_id, created_at)
    SELECT 
        uuid_generate_v4(),
        'testuser@example.com',
        'testpartner',
        'test.apple.id.' || uuid_generate_v4()::text,
        NOW()
    WHERE NOT EXISTS (
        SELECT 1 FROM users WHERE email = 'testuser@example.com' OR username = 'testpartner'
    )
    RETURNING id
),
-- Шаг 2: Находим пользователя radmickey
target_user AS (
    SELECT id FROM users WHERE username = 'radmickey'
)
-- Шаг 3: Создаем pair request от тестового пользователя к radmickey
INSERT INTO pair_requests (requester_id, requested_id, status, created_at, updated_at)
SELECT
    tu.id,
    targ.id,
    'pending',
    NOW(),
    NOW()
FROM test_user tu
CROSS JOIN target_user targ
WHERE targ.id IS NOT NULL
ON CONFLICT (requester_id, requested_id) DO UPDATE
SET status = 'pending',
    updated_at = NOW();

-- Проверка результата
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

