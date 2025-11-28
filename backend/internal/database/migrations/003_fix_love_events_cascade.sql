ALTER TABLE love_events ALTER COLUMN pair_id DROP NOT NULL;

ALTER TABLE love_events DROP CONSTRAINT IF EXISTS love_events_pair_id_fkey;

ALTER TABLE love_events 
ADD CONSTRAINT love_events_pair_id_fkey 
FOREIGN KEY (pair_id) REFERENCES pairs(id) ON DELETE SET NULL;

