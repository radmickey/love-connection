DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'love_events'
        AND column_name = 'pair_id'
        AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE love_events ALTER COLUMN pair_id DROP NOT NULL;
    END IF;
END $$;

ALTER TABLE love_events DROP CONSTRAINT IF EXISTS love_events_pair_id_fkey;

ALTER TABLE love_events
ADD CONSTRAINT love_events_pair_id_fkey
FOREIGN KEY (pair_id) REFERENCES pairs(id) ON DELETE SET NULL;

