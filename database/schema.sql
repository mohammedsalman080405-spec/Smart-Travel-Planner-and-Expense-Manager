-- Smart Travel Planner and Expense Manager
-- Database Schema for MySQL (smart_travel_db)

CREATE DATABASE IF NOT EXISTS smart_travel_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE smart_travel_db;

-- 1. Users Table
CREATE TABLE IF NOT EXISTS users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(191) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(30),
    profile_image TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 2. Destinations Table
CREATE TABLE IF NOT EXISTS destinations (
    destination_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    city VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    description TEXT,
    latitude DECIMAL(10, 7) NOT NULL,
    longitude DECIMAL(10, 7) NOT NULL,
    image_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 3. Hotels Table
CREATE TABLE IF NOT EXISTS hotels (
    hotel_id INT AUTO_INCREMENT PRIMARY KEY,
    destination_id INT,
    hotel_name VARCHAR(200) NOT NULL,
    description TEXT,
    address VARCHAR(300) NOT NULL,
    city VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    latitude DECIMAL(10, 7) NOT NULL,
    longitude DECIMAL(10, 7) NOT NULL,
    star_rating DECIMAL(2, 1) DEFAULT 4.5,
    review_rating DECIMAL(2, 1) DEFAULT 4.5,
    review_count INT DEFAULT 0,
    starting_price DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    exterior_image_url TEXT,
    exterior_model_url TEXT,
    place_id VARCHAR(100),
    data_source VARCHAR(50) DEFAULT 'database',
    is_demo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (destination_id) REFERENCES destinations(destination_id) ON DELETE SET NULL,
    INDEX idx_location (latitude, longitude),
    INDEX idx_city (city)
) ENGINE=InnoDB;

-- 4. Hotel Images Table
CREATE TABLE IF NOT EXISTS hotel_images (
    image_id INT AUTO_INCREMENT PRIMARY KEY,
    hotel_id INT NOT NULL,
    image_url TEXT NOT NULL,
    image_category VARCHAR(50) DEFAULT 'exterior', -- exterior, interior, lobby, dining, amenity
    caption VARCHAR(200),
    display_order INT DEFAULT 0,
    FOREIGN KEY (hotel_id) REFERENCES hotels(hotel_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 5. Hotel Facilities Table
CREATE TABLE IF NOT EXISTS hotel_facilities (
    facility_id INT AUTO_INCREMENT PRIMARY KEY,
    hotel_id INT NOT NULL,
    facility_name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    FOREIGN KEY (hotel_id) REFERENCES hotels(hotel_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 6. Rooms Table
CREATE TABLE IF NOT EXISTS rooms (
    room_id INT AUTO_INCREMENT PRIMARY KEY,
    hotel_id INT NOT NULL,
    room_name VARCHAR(150) NOT NULL,
    room_type VARCHAR(80) NOT NULL, -- Standard, Deluxe, Premium, Executive Suite, Presidential Suite
    description TEXT,
    price_per_night DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    bed_type VARCHAR(50) DEFAULT 'King Bed',
    room_size VARCHAR(50) DEFAULT '45 sq.m',
    maximum_occupancy INT DEFAULT 2,
    amenities TEXT, -- JSON or comma-separated string
    availability_status VARCHAR(30) DEFAULT 'available',
    image_url TEXT,
    model_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (hotel_id) REFERENCES hotels(hotel_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 7. Room Images Table
CREATE TABLE IF NOT EXISTS room_images (
    image_id INT AUTO_INCREMENT PRIMARY KEY,
    room_id INT NOT NULL,
    image_url TEXT NOT NULL,
    caption VARCHAR(200),
    display_order INT DEFAULT 0,
    FOREIGN KEY (room_id) REFERENCES rooms(room_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 8. Hotel Spaces Table (Halls, Restaurants, Pools, Spa, Gym, Lounge, Garden)
CREATE TABLE IF NOT EXISTS hotel_spaces (
    space_id INT AUTO_INCREMENT PRIMARY KEY,
    hotel_id INT NOT NULL,
    space_name VARCHAR(150) NOT NULL,
    category VARCHAR(60) NOT NULL, -- banquet_hall, conference_hall, restaurant, pool, spa, gym, lounge, garden
    description TEXT,
    capacity INT DEFAULT 50,
    size VARCHAR(50) DEFAULT '120 sq.m',
    price DECIMAL(10, 2) DEFAULT 0.00,
    currency VARCHAR(10) DEFAULT 'USD',
    opening_hours VARCHAR(100) DEFAULT '06:00 - 23:00',
    amenities TEXT,
    image_url TEXT,
    model_url TEXT,
    availability_status VARCHAR(30) DEFAULT 'available',
    FOREIGN KEY (hotel_id) REFERENCES hotels(hotel_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 9. Trips Table
CREATE TABLE IF NOT EXISTS trips (
    trip_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    trip_name VARCHAR(150) NOT NULL,
    destination VARCHAR(150) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    traveller_count INT DEFAULT 1,
    status VARCHAR(30) DEFAULT 'planned', -- planned, ongoing, completed, cancelled
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 10. Bookings Table
CREATE TABLE IF NOT EXISTS bookings (
    booking_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    hotel_id INT NOT NULL,
    room_id INT NOT NULL,
    trip_id INT,
    check_in DATE NOT NULL,
    check_out DATE NOT NULL,
    guest_count INT DEFAULT 1,
    number_of_nights INT NOT NULL,
    price_per_night DECIMAL(10, 2) NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    booking_status VARCHAR(30) DEFAULT 'confirmed', -- confirmed, cancelled, completed
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (hotel_id) REFERENCES hotels(hotel_id) ON DELETE CASCADE,
    FOREIGN KEY (room_id) REFERENCES rooms(room_id) ON DELETE CASCADE,
    FOREIGN KEY (trip_id) REFERENCES trips(trip_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 11. Trip Destinations Table
CREATE TABLE IF NOT EXISTS trip_destinations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    trip_id INT NOT NULL,
    destination_id INT NOT NULL,
    visit_order INT DEFAULT 1,
    FOREIGN KEY (trip_id) REFERENCES trips(trip_id) ON DELETE CASCADE,
    FOREIGN KEY (destination_id) REFERENCES destinations(destination_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 12. Trip Activities Table
CREATE TABLE IF NOT EXISTS trip_activities (
    activity_id INT AUTO_INCREMENT PRIMARY KEY,
    trip_id INT NOT NULL,
    destination_id INT,
    activity_name VARCHAR(150) NOT NULL,
    activity_date DATE NOT NULL,
    start_time VARCHAR(20),
    end_time VARCHAR(20),
    location VARCHAR(200),
    latitude DECIMAL(10, 7),
    longitude DECIMAL(10, 7),
    notes TEXT,
    FOREIGN KEY (trip_id) REFERENCES trips(trip_id) ON DELETE CASCADE,
    FOREIGN KEY (destination_id) REFERENCES destinations(destination_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 13. Budgets Table
CREATE TABLE IF NOT EXISTS budgets (
    budget_id INT AUTO_INCREMENT PRIMARY KEY,
    trip_id INT NOT NULL UNIQUE,
    accommodation_budget DECIMAL(10, 2) DEFAULT 0.00,
    transport_budget DECIMAL(10, 2) DEFAULT 0.00,
    food_budget DECIMAL(10, 2) DEFAULT 0.00,
    activities_budget DECIMAL(10, 2) DEFAULT 0.00,
    shopping_budget DECIMAL(10, 2) DEFAULT 0.00,
    other_budget DECIMAL(10, 2) DEFAULT 0.00,
    total_budget DECIMAL(10, 2) DEFAULT 0.00,
    currency VARCHAR(10) DEFAULT 'USD',
    FOREIGN KEY (trip_id) REFERENCES trips(trip_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 14. Expenses Table
CREATE TABLE IF NOT EXISTS expenses (
    expense_id INT AUTO_INCREMENT PRIMARY KEY,
    trip_id INT NOT NULL,
    user_id INT NOT NULL,
    category VARCHAR(50) NOT NULL, -- Accommodation, Food, Transportation, Shopping, Entertainment, Activities, Other
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    expense_date DATE NOT NULL,
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (trip_id) REFERENCES trips(trip_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 15. Search History Table (Optional)
CREATE TABLE IF NOT EXISTS search_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    query VARCHAR(200) NOT NULL,
    searched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;
