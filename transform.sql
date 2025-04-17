-- Begin transaction
BEGIN;

-- Create normalized tables if they don't exist
CREATE TABLE IF NOT EXISTS locations (
    id SERIAL PRIMARY KEY,
    latitude DECIMAL(9,6) NOT NULL,
    longitude DECIMAL(9,6) NOT NULL,
    name VARCHAR(255),
    UNIQUE(latitude, longitude)
);

CREATE TABLE IF NOT EXISTS traffic_flow (
    id SERIAL PRIMARY KEY,
    location_id INTEGER REFERENCES locations(id),
    current_speed DECIMAL(6,2),
    free_flow_speed DECIMAL(6,2),
    current_travel_time INTEGER,
    free_flow_travel_time INTEGER,
    confidence INTEGER,
    road_closure BOOLEAN,
    timestamp TIMESTAMP,
    UNIQUE(location_id, timestamp)
);

-- Extract data from JSON and insert into locations table
WITH raw_data AS (
    SELECT data, created_at FROM raw_traffic_json
)
INSERT INTO locations (latitude, longitude, name)
SELECT 
    (data->'flowSegmentData'->'coordinate'->>'latitude')::DECIMAL(9,6) AS latitude,
    (data->'flowSegmentData'->'coordinate'->>'longitude')::DECIMAL(9,6) AS longitude,
    data->'flowSegmentData'->>'roadName' AS name
FROM raw_data
ON CONFLICT (latitude, longitude) DO NOTHING;

-- Insert data into traffic_flow table
WITH raw_data AS (
    SELECT data, created_at FROM raw_traffic_json
)
INSERT INTO traffic_flow (
    location_id, current_speed, free_flow_speed, 
    current_travel_time, free_flow_travel_time, 
    confidence, road_closure, timestamp
)
SELECT 
    l.id AS location_id,
    (data->'flowSegmentData'->>'currentSpeed')::DECIMAL(6,2) AS current_speed,
    (data->'flowSegmentData'->>'freeFlowSpeed')::DECIMAL(6,2) AS free_flow_speed,
    (data->'flowSegmentData'->>'currentTravelTime')::INTEGER AS current_travel_time,
    (data->'flowSegmentData'->>'freeFlowTravelTime')::INTEGER AS free_flow_travel_time,
    (data->'flowSegmentData'->>'confidence')::INTEGER AS confidence,
    (data->'flowSegmentData'->>'roadClosure')::BOOLEAN AS road_closure,
    created_at AS timestamp
FROM raw_data
JOIN locations l ON 
    l.latitude = (data->'flowSegmentData'->'coordinate'->'coordinate'->0->>'latitude')::DECIMAL(9,6) AND
    l.longitude = (data->'flowSegmentData'->'coordinate'->'coordinate'->0->>'longitude')::DECIMAL(9,6)
ON CONFLICT (location_id, timestamp) DO NOTHING;

-- Clean up raw data after successful transformation
DELETE FROM raw_traffic_json;

-- Commit the transaction
COMMIT;
