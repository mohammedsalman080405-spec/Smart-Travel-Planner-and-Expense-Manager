# SMART TRAVEL PLANNER AND EXPENSE MANAGER

A modern, luxury, full-stack web application built from scratch featuring an interactive 3D Earth Globe for destination and hotel discovery, 3D GLB/glTF room and hotel interior inspection, hotel reservations, day-wise trip itinerary planning, and an integrated travel budget & expense tracker.

---

## Architecture Overview

```
Smart Travel Planner and Expense Manager/
├── backend/                  # Python Flask REST API & SQLAlchemy ORM
│   ├── app.py                # Application factory, extensions & error handlers
│   ├── config.py             # App & Database configuration
│   ├── extensions.py         # SQLAlchemy, JWTManager, CORS, Migrate
│   ├── models/               # Relational MySQL models (15 tables)
│   │   ├── user.py           # Traveler user profiles & password hashing
│   │   ├── destination.py    # Global destinations & geocoding coordinates
│   │   ├── hotel.py          # Luxury hotels with lat/long & ratings
│   │   ├── hotel_image.py    # Hotel exterior & interior image gallery
│   │   ├── hotel_facility.py # Verified property amenities & facilities
│   │   ├── room.py           # Guest rooms & suites with 3D GLB model URLs
│   │   ├── room_image.py     # Room photography
│   │   ├── hotel_space.py    # Ballrooms, conference halls & rooftop lounges
│   │   ├── booking.py        # Hotel reservations with overlap protection
│   │   ├── trip.py           # Trips, itineraries & day-wise activities
│   │   ├── budget.py         # Category-wise budget calculator
│   │   └── expense.py        # Itemized expense tracker
│   ├── routes/               # Modular Flask Blueprints
│   │   ├── auth.py           # JWT Authentication (register, login, profile)
│   │   ├── destinations.py   # Destination search & geocoding
│   │   ├── hotels.py         # Geographic radius search & hotel details
│   │   ├── rooms.py          # Room specifications & 3D models
│   │   ├── hotel_spaces.py   # Spaces, halls & dining facilities
│   │   ├── bookings.py       # Reservation booking workflow & history
│   │   ├── trips.py          # Trips CRUD & itinerary activities
│   │   ├── budgets.py        # Category budgets & financial summaries
│   │   └── expenses.py       # Expense logging & reporting
│   ├── services/             # Business logic & external services
│   │   ├── geocoding_service.py     # Destination coordinate resolution
│   │   ├── hotel_search_service.py  # Haversine distance calculation & radius
│   │   ├── booking_service.py       # Availability validation & pricing
│   │   ├── budget_service.py        # Financial calculations & percentages
│   │   └── expense_service.py       # Category aggregation & expense CRUD
│   ├── seed.py               # Database seeder (10 destinations, 20 hotels, 60 rooms, 60 spaces)
│   ├── requirements.txt      # Python dependencies
│   └── .env                  # Environment configuration
│
├── database/
│   └── schema.sql            # MySQL normalized database schema (smart_travel_db)
│
└── frontend/                 # Flutter Web Application
    ├── lib/
    │   ├── main.dart         # Entry point & Provider tree
    │   ├── config/           # Theme, API endpoints & GoRouter declarative routes
    │   ├── models/           # Dart data models
    │   ├── services/         # REST API communication client & Auth storage
    │   ├── providers/        # Riverpod / Provider state management
    │   ├── widgets/          # Interactive 3D Globe, Search Bar, Side Panel, ModelViewer, Charts
    │   └── screens/          # 3D Globe Home, Hotel Details, 3D Room, Booking, Trips, Budget
    ├── web/                  # Web index.html with 3D Model Viewer script & assets
    └── pubspec.yaml          # Flutter dependencies
```

---

## Technology Stack

- **Frontend**: Flutter Web (Dart 3, Material Design 3, `go_router`, `provider`, `model_viewer_plus`, `fl_chart`, `intl`, `google_fonts`)
- **Backend**: Python 3.13, Flask 3.1, Flask-SQLAlchemy, Flask-JWT-Extended, Flask-CORS, PyMySQL, Cryptography
- **Database**: MySQL 8.x (`smart_travel_db`), 15 Relational Tables with Foreign Keys & Cascading Deletes
- **3D Visualization**: Real interactive 3D Earth Globe with coordinate focus & GLB 3D Model Viewer

---

## Local Execution Guide (macOS)

### 1. Database Setup (MySQL)

Ensure MySQL is running on your machine:
```bash
brew services start mysql
```

Initialize the database schema:
```bash
mysql -u root < database/schema.sql
```

### 2. Backend Setup (Flask REST API)

Navigate to the `backend/` directory:
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

Run the database seed script:
```bash
python seed.py
```
*This populates 10 destinations, 20 verified demonstration hotels, 60 guest rooms with 3D model URLs, 60 banquet & conference spaces, verified facilities, and sample trips/budgets.*

Start the Flask server on port 5001:
```bash
python app.py
```
*The backend API will be live at `http://127.0.0.1:5001`.*

### 3. Frontend Setup (Flutter Web)

Navigate to the `frontend/` directory:
```bash
cd frontend
flutter pub get
```

Run the Flutter Web development server:
```bash
flutter run -d chrome
```

Or build and serve production release web assets:
```bash
flutter build web --release
cd build/web
python3 -m http.server 8080
```
*Access the application in your browser at `http://localhost:8080`.*

---

## Default Demo Credentials

For instant sign-in and testing:
- **Email**: `traveler@smarttravel.com`
- **Password**: `Travel123!`

---

## User Workflows Implemented

1. **Interactive 3D Earth Globe Homepage**:
   - Opens with a full-screen luxury 3D Earth globe on deep navy background with wireframe landmasses and atmosphere.
   - Mouse drag rotation, touch rotation, zoom in/out controls, and automatic rotation when idle.
2. **Destination Search**:
   - Prominent search bar supporting global tourist destinations (Hyderabad, Bali, Paris, Tokyo, Dubai, Mumbai, Singapore, London, New York).
   - Autocomplete suggestions and quick destination pills.
   - Smoothly rotates the globe and zooms into searched coordinates.
3. **Geographic Hotel Markers & Radius**:
   - Fetches hotels located within the configurable radius (5 km, 10 km, 20 km, 30 km, 50 km) using actual Haversine distance calculations.
   - Small glowing pins appear directly on the 3D globe surface with hover price badges.
4. **Right-Side Hotel Information Panel**:
   - Clicking a hotel marker highlights the marker, keeps the globe visible (68% width), and slides open the right-side information panel (32% width).
   - Displays exterior photograph, star rating, verified amenities, starting price, and an instant accommodation expense calculator for check-in and check-out dates.
5. **Hotel Interior & Property Exploration Page**:
   - Clicking the hotel exterior photograph or "Explore Hotel" opens `/hotel/:id`.
   - Displays exterior photo gallery, full description, verified facilities, and exploration tabs:
     - Deluxe Rooms & Suites
     - Banquet & Conference Halls
     - Restaurants & Sky Lounges
     - Swimming Pool, Spa & Wellness
6. **Interactive 3D Room & Space Viewer**:
   - Clicking "Explore 3D" opens the room's dedicated GLB 3D model viewer (`/room/:id` or `/space/:id`).
   - Supports 360-degree rotation, angle inspection, zoom, auto-rotation toggle, and specifications.
7. **Hotel Reservation Module**:
   - Select check-in and check-out dates, guest count (adults & children).
   - Automatically calculates number of nights, nightly rates, configured 12% taxes/fees, and total amount.
   - Concurrency protection on backend prevents overlapping bookings for the same room.
8. **Smart Trip Itinerary Planner**:
   - Create new travel itineraries (`/trips`).
   - Day-wise organization with activity start time, end time, location, notes, and Google Maps directions link.
9. **Travel Budget & Expense Management**:
   - Set category targets: Accommodation, Transportation, Food, Activities, Shopping, Other.
   - Automatic calculations: Total planned budget, actual expenses, remaining balance, percentage used.
   - Interactive `fl_chart` pie chart for category spending distribution.
