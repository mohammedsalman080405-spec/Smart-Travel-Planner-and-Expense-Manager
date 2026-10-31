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
- **Realistic 3D Earth Globe**: Three.js WebGL (r128) embedded via `HtmlElementView`, NASA Blue Marble equirectangular day texture (4096×2048), cloud layer with additive blending, atmospheric glow shader, specular ocean mask, directional sunlight, deep space starfield, and 3D spherical coordinate projection (`latLngToVector3`)
- **Backend**: Python 3.13, Flask 3.1, Flask-SQLAlchemy, Flask-JWT-Extended, Flask-CORS, PyMySQL, Cryptography
- **External APIs**: Google Places API (New) `POST https://places.googleapis.com/v1/places:searchNearby` with verified MySQL database fallback
- **Database**: MySQL 8.x (`smart_travel_db`), 15 Relational Tables with Foreign Keys & Cascading Deletes
- **3D Room Visualization**: Google `<model-viewer>` / `model_viewer_plus` for interactive GLB/glTF 3D room and space inspection

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

1. **Realistic 3D Earth Globe Homepage**:
   - Replaced wireframe spheres with a photorealistic 3D Earth globe powered by Three.js WebGL and embedded seamlessly into Flutter Web via `HtmlElementView`.
   - Utilizes genuine NASA Blue Marble equirectangular imagery (4096×2048), topographic normal maps, specular ocean reflection masks, realistic white cloud overlay, atmospheric halo glow shader, directional sunlight, and deep space starfield.
   - Smooth mouse/touch OrbitControls, auto-rotation when idle, zoom in/out controls, and reset view.
2. **Destination Search**:
   - Prominent search bar supporting global tourist destinations (Hyderabad, Dubai, Bali, Paris, Tokyo, Mumbai, Singapore, London, New York).
   - Autocomplete suggestions and quick destination pills.
   - Geocodes destination to actual coordinates and smoothly rotates/zooms the Earth globe towards the target location.
3. **Geographic Hotel Markers & Radius on Earth**:
   - Connects to Google Places API (New) `POST https://places.googleapis.com/v1/places:searchNearby` with verified database fallback.
   - Calculates geographic positions and projects them onto the spherical Earth surface using spherical trigonometry:
     `phi = (90 - lat) * (PI / 180)`, `theta = (lng + 180) * (PI / 180)`
   - Renders each hotel as a glowing 3D dot with a vertical pin and pulsing ring anchored directly to the Earth's surface (moves with Earth rotation).
   - Interactive hover tooltips showing hotel name, nightly price, and star rating.
4. **Right-Side Hotel Information Panel**:
   - Clicking a hotel marker turns it gold/yellow, focuses the camera, keeps the globe visible (~68% width), and slides open the luxury right-side information panel (~32% width).
   - Displays exterior photograph, star rating, verified address, starting price, facility tags, and instant accommodation expense calculator.
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
