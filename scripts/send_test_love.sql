-- Скрипт для отправки love события от testpartner к radmickey с длительностью 10 секунд

-- 1. Находим пользователей и их пару
WITH test_user AS (
    SELECT id FROM users WHERE username = 'testpartner'
),
target_user AS (
    SELECT id FROM users WHERE username = 'radmickey'
),
pair_info AS (
    SELECT
        p.id as pair_id,
        tu.id as sender_id
    FROM pairs p
    CROSS JOIN test_user tu
    CROSS JOIN target_user targ
    WHERE (p.user1_id = tu.id AND p.user2_id = targ.id)
       OR (p.user1_id = targ.id AND p.user2_id = tu.id)
)
-- 2. Вставляем love event
INSERT INTO love_events (pair_id, sender_id, duration_seconds, created_at)
SELECT
    pair_id,
    sender_id,
    10, -- 10 секунд
    NOW()
FROM pair_info
WHERE pair_id IS NOT NULL AND sender_id IS NOT NULL;

-- 3. Проверяем результат
SELECT
    le.id as event_id,
    u1.username as sender_username,
    u2.username as partner_username,
    le.duration_seconds,
    le.created_at
FROM love_events le
JOIN pairs p ON le.pair_id = p.id
JOIN users u1 ON le.sender_id = u1.id
JOIN users u2 ON (p.user1_id = u2.id OR p.user2_id = u2.id) AND u2.id != u1.id
WHERE u1.username = 'testpartner'
  AND u2.username = 'radmickey'
ORDER BY le.created_at DESC
LIMIT 1;

