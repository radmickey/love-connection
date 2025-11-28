-- Increase apple_id column length to accommodate longer user identifiers
ALTER TABLE users ALTER COLUMN apple_id TYPE VARCHAR(500);

