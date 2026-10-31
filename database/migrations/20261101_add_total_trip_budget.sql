-- Apply once to existing Smart Travel databases before deploying this feature.
ALTER TABLE trips
    ADD COLUMN total_trip_budget DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    ADD COLUMN currency VARCHAR(10) NOT NULL DEFAULT 'INR';

-- Preserve each existing trip's current overall budget where one is configured.
UPDATE trips AS t
JOIN budgets AS b ON b.trip_id = t.trip_id
SET t.total_trip_budget = b.total_budget,
    t.currency = COALESCE(b.currency, 'INR')
WHERE t.total_trip_budget = 0;
