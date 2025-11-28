-- Add unique constraint to username
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_username_unique ON users(username);

-- Update existing users with empty or duplicate usernames to have unique ones
-- This is a safety measure in case there are existing duplicates
DO $$
DECLARE
    user_record RECORD;
    counter INTEGER := 1;
BEGIN
    FOR user_record IN
        SELECT id, username FROM users
        WHERE username IS NULL OR username = '' OR username = 'User'
    LOOP
        UPDATE users
        SET username = 'User' || counter
        WHERE id = user_record.id;
        counter := counter + 1;
    END LOOP;
END $$;

