-- Проверка device tokens для пользователей

SELECT
    u.id,
    u.username,
    u.email,
    CASE
        WHEN u.device_token IS NULL OR u.device_token = '' THEN 'NO TOKEN'
        ELSE 'HAS TOKEN'
    END as token_status,
    LENGTH(u.device_token) as token_length,
    LEFT(u.device_token, 20) || '...' as token_preview
FROM users u
ORDER BY u.username;

