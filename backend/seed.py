import os
import json
from datetime import date, timedelta
from app import create_app
from extensions import db
from models import (
    User, Destination, Hotel, HotelImage, HotelFacility,
    Room, RoomImage, HotelSpace, Booking, Trip,
    TripDestination, TripActivity, Budget, Expense
)

app = create_app()

# Reliable, publicly hosted GLB models for 3D exploration
GLB_ROOM_MODELS = [
    "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/SheenChair/glTF-Binary/SheenChair.glb",
    "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/AntiqueCamera/glTF-Binary/AntiqueCamera.glb",
    "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/Lantern/glTF-Binary/Lantern.glb",
    "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/Corset/glTF-Binary/Corset.glb",
    "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/DamagedHelmet/glTF-Binary/DamagedHelmet.glb"
]

def seed_database():
    with app.app_context():
        print("🌱 Seeding Smart Travel Planner Database...")

        # 1. Create or retrieve Default Demo User
        demo_user = User.query.filter_by(email="traveler@smarttravel.com").first()
        if not demo_user:
            demo_user = User(
                full_name="Alexander Wright",
                email="traveler@smarttravel.com",
                phone="+1 (555) 234-5678",
                profile_image="https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80"
            )
            demo_user.set_password("Travel123!")
            db.session.add(demo_user)
            db.session.commit()
            print("  ✓ Created demo user: traveler@smarttravel.com (password: Travel123!)")
        else:
            print("  ℹ Demo user already exists.")

        # 2. Destinations (10 Top Global Cities)
        destinations_data = [
            {
                "name": "Hyderabad",
                "city": "Hyderabad",
                "country": "India",
                "description": "City of Pearls, majestic Nizami palaces, aromatic Biryani and thriving global tech corridors.",
                "latitude": 17.385044,
                "longitude": 78.486671,
                "image_url": "https://images.unsplash.com/photo-1603816245457-36e2f1f45c26?auto=format&fit=crop&w=1200&q=80"
            },
            {
                "name": "Mumbai",
                "city": "Mumbai",
                "country": "India",
                "description": "India's dazzling financial metropolis, historic Gateway of India and Arabian Sea promenades.",
                "latitude": 19.076090,
                "longitude": 72.877426,
                "image_url": "https://images.unsplash.com/photo-1570168007204-dfb528c6958f?auto=format&fit=crop&w=1200&q=80"
            },
            {
                "name": "Delhi",
                "city": "Delhi",
                "country": "India",
                "description": "Vibrant capital of monumental heritage, Mughal architecture, and modern diplomatic avenues.",
                "latitude": 28.613939,
                "longitude": 77.209021,
                "image_url": "https://images.unsplash.com/photo-1587474260584-136574528ed5?auto=format&fit=crop&w=1200&q=80"
            },
            {
                "name": "Dubai",
                "city": "Dubai",
                "country": "United Arab Emirates",
                "description": "Ultra-luxury oasis of Burj Khalifa, futuristic architecture, and desert glamour.",
                "latitude": 25.204849,
                "longitude": 55.270783,
                "image_url": "https://images.unsplash.com/photo-1512453979798-5ea266f8880c?auto=format&fit=crop&w=1200&q=80"
            },
            {
                "name": "Bali",
                "city": "Denpasar",
                "country": "Indonesia",
                "description": "Tropical paradise renowned for coastal cliffs, surf breaks, sacred temples, and lush emerald terraces.",
                "latitude": -8.409518,
                "longitude": 115.188916,
                "image_url": "https://images.unsplash.com/photo-1537996194471-e657df975ab4?auto=format&fit=crop&w=1200&q=80"
            },
            {
                "name": "Paris",
                "city": "Paris",
                "country": "France",
                "description": "The City of Light, haute cuisine, iconic Eiffel Tower, and classical romance.",
                "latitude": 48.856614,
                "longitude": 2.352222,
                "image_url": "https://images.unsplash.com/photo-1502602898657-3e91760cbb34?auto=format&fit=crop&w=1200&q=80"
            },
            {
                "name": "Singapore",
                "city": "Singapore",
                "country": "Singapore",
                "description": "Futuristic garden metropolis with world-class skyline, Marina Bay, and vibrant culinary culture.",
                "latitude": 1.352083,
                "longitude": 103.819836,
                "image_url": "https://images.unsplash.com/photo-1525625293386-3f8f99389edd?auto=format&fit=crop&w=1200&q=80"
            },
            {
                "name": "Tokyo",
                "city": "Tokyo",
                "country": "Japan",
                "description": "Seamless harmony of neon-lit innovation, ancient shrines, and unparalleled hospitality.",
                "latitude": 35.676192,
                "longitude": 139.650311,
                "image_url": "https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=1200&q=80"
            },
            {
                "name": "London",
                "city": "London",
                "country": "United Kingdom",
                "description": "Historic royal landmarks, Thames panoramas, world-class West End theaters, and stately elegance.",
                "latitude": 51.507351,
                "longitude": -0.127758,
                "image_url": "https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?auto=format&fit=crop&w=1200&q=80"
            },
            {
                "name": "New York",
                "city": "New York",
                "country": "United States",
                "description": "The city that never sleeps, Central Park, Empire State skyline, and premier luxury suites.",
                "latitude": 40.712776,
                "longitude": -74.005974,
                "image_url": "https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?auto=format&fit=crop&w=1200&q=80"
            }
        ]

        dest_map = {}
        for d_info in destinations_data:
            dest = Destination.query.filter_by(name=d_info['name']).first()
            if not dest:
                dest = Destination(**d_info)
                db.session.add(dest)
                db.session.flush()
            dest_map[d_info['name']] = dest
        db.session.commit()
        print(f"  ✓ {len(dest_map)} destinations verified.")

        # 3. 20 Clearly Identified Demonstration Hotels (Geographically Accurate)
        hotels_data = [
            # Hyderabad Hotels
            {
                "destination_name": "Hyderabad",
                "hotel_name": "Taj Falaknuma Palace (Demo)",
                "description": "Perched 2,000 feet above Hyderabad, this 1893 royal palace whispers tales of Nizams with Venetian chandeliers and Italian marble.",
                "address": "Engine Bowli, Fatima Nagar, Falaknuma, Hyderabad, Telangana 500053",
                "city": "Hyderabad",
                "country": "India",
                "latitude": 17.331400,
                "longitude": 78.467800,
                "star_rating": 5.0,
                "review_rating": 4.9,
                "review_count": 1840,
                "starting_price": 420.00,
                "currency": "USD",
                "exterior_image_url": "https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1200&q=80"
            },
            {
                "destination_name": "Hyderabad",
                "hotel_name": "ITC Kohenur Luxury Collection (Demo)",
                "description": "Overlooking Durgam Cheruvu lake in the heart of HITEC City, inspired by the legendary Koh-i-Noor diamond with state-of-the-art wellness.",
                "address": "Plot No. 5, Survey No. 83/1, Hyderabad Knowledge City, Madhapur, Hyderabad 500081",
                "city": "Hyderabad",
                "country": "India",
                "latitude": 17.435700,
                "longitude": 78.381200,
                "star_rating": 4.9,
                "review_rating": 4.8,
                "review_count": 1260,
                "starting_price": 240.00,
                "currency": "USD",
                "exterior_image_url": "https://images.unsplash.com/photo-1582719508461-905c673771fd?auto=format&fit=crop&w=1200&q=80"
            },
            {
                "destination_name": "Hyderabad",
                "hotel_name": "Park Hyatt Hyderabad (Demo)",
                "description": "An opulent residence in affluent Banjara Hills featuring museum-quality art, soaring atrium, and temperature-controlled swimming pools.",
                "address": "Road No. 2, Banjara Hills, Hyderabad, Telangana 500034",
                "city": "Hyderabad",
                "country": "India",
                "latitude": 17.424300,
                "longitude": 78.435200,
                "star_rating": 4.8,
                "review_rating": 4.7,
                "review_count": 940,
                "starting_price": 195.00,
                "currency": "USD",
                "exterior_image_url": "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=1200&q=80"
            },
            # Mumbai Hotels
            {
                "destination_name": "Mumbai",
                "hotel_name": "The Taj Mahal Palace (Demo)",
                "description": "Flagship iconic landmark overlooking the Gateway of India since 1903, host to royalty, presidents and world dignitaries.",
                "address": "Apollo Bandar, Colaba, Mumbai, Maharashtra 400001",
                "city": "Mumbai",
                "country": "India",
                "latitude": 18.921700,
                "longitude": 72.833100,
                "star_rating": 5.0,
                "review_rating": 4.9,
                "review_count": 3120,
                "starting_price": 450.00,
                "currency": "USD",
                "exterior_image_url": "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?auto=format&fit=crop&w=1200&q=80"
            },
            {
                "destination_name": "Mumbai",
                "hotel_name": "The Oberoi Nariman Point (Demo)",
                "description": "Overlooking Marine Drive and the Queen's Necklace, offering tranquil sea-facing suites and Michelin-level gastronomic journeys.",
                "address": "Nariman Point, Marine Drive, Mumbai, Maharashtra 400021",
                "city": "Mumbai",
                "country": "India",
                "latitude": 18.927200,
                "longitude": 72.821100,
                "star_rating": 4.9,
                "review_rating": 4.8,
                "review_count": 1420,
                "starting_price": 380.00,
                "currency": "USD",
                "exterior_image_url": "https://images.unsplash.com/photo-1571896349842-33c89424de2d?auto=format&fit=crop&w=1200&q=80"
            },
            # Delhi Hotels
            {
                "destination_name": "Delhi",
                "hotel_name": "The Leela Palace New Delhi (Demo)",
                "description": "Royal Lutyens architectural grandeur with majestic gold domes, crystal chandeliers, and infinity rooftop pool overlooking the capital.",
                "address": "Diplomatic Enclave, Chanakyapuri, New Delhi 110023",
                "city": "Delhi",
                "country": "India",
                "latitude": 28.583000,
                "longitude": 77.190200,
                "star_rating": 5.0,
                "review_rating": 4.9,
                "review_count": 2100,
                "starting_price": 390.00,
                "currency": "USD",
                "exterior_image_url": "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?auto=format&fit=crop&w=1200&q=80"
            },
            {
                "destination_name": "Delhi",
                "hotel_name": "The Imperial New Delhi (Demo)",
                "description": "Legendary art-deco heritage haven dating to 1931, celebrated for Victorian salons, lush palm gardens, and colonial art collections.",
                "address": "Janpath Lane, Connaught Place, New Delhi 110001",
                "city": "Delhi",
                "country": "India",
                "latitude": 28.623100,
                "longitude": 77.218500,
                "star_rating": 4.8,
                "review_rating": 4.7,
                "review_count": 1650,
                "starting_price": 280.00,
                "currency": "USD",
                "exterior_image_url": "https://images.unsplash.com/photo-1564501049412-61c2a3083791?auto=format&fit=crop&w=1200&q=80"
            },
            # Dubai Hotels
            {
                "destination_name": "Dubai",
                "hotel_name": "Burj Al Arab Jumeirah (Demo)",
                "description": "The world's most iconic sail-shaped luxury hotel, featuring 24-carat gold leaf interiors, private butler service, and private helicopter pad.",
                "address": "Umm Suqeim 3, Jumeirah Beach Road, Dubai, UAE",
                "city": "Dubai",
                "country": "United Arab Emirates",
                "latitude": 25.141200,
                "longitude": 55.185200,
                "star_rating": 5.0,
                "review_rating": 4.9,
                "review_count": 4890,
                "starting_price": 1400.00,
                "currency": "USD",
                "exterior_image_url": "https://images.unsplash.com/photo-1580674684081-7617fbf3d745?auto=format&fit=crop&w=1200&q=80"
            },
            {
                "destination_name": "Dubai",
                "hotel_name": "Atlantis The Royal (Demo)",
                "description": "An architectural marvel on the Palm Jumeirah with 90-metre high sky pool, celebrity chef restaurants, and fire-and-water fountain displays.",
                "address": "Crescent Road, Palm Jumeirah, Dubai, UAE",
                "city": "Dubai",
                "country": "United Arab Emirates",
                "latitude": 25.138900,
                "longitude": 55.129800,
                "star_rating": 5.0,
                "review_rating": 4.8,
                "review_count": 3200,
                "starting_price": 850.00,
                "currency": "USD",
                "exterior_image_url": "https://images.unsplash.com/photo-1544984243-ec57ea16fe25?auto=format&fit=crop&w=1200&q=80"
            },
            # Bali Hotels
            {
                "destination_name": "Bali",
                "hotel_name": "Bulgari Resort Bali (Demo)",
                "description": "Perched dramatically on 150-metre sea cliffs in Uluwatu, combining traditional Balinese architecture with Italian jewelry precision.",
                "address": "Jalan Goa Lempeh, Banjar Dinas Kangin, Uluwatu, Bali 80364",
                "city": "Denpasar",
                "country": "Indonesia",
                "latitude": -8.847500,
                "longitude": 115.144700,
                "star_rating": 5.0,
                "review_rating": 4.9,
                "review_count": 1780,
                "starting_price": 980.00,
                "currency": "USD",
                "exterior_image_url": "https://images.unsplash.com/photo-1540541338287-41700207dee6?auto=format&fit=crop&w=1200&q=80"
            },
            {
                "destination_name": "Bali",
                "hotel_name": "Four Seasons Resort Bali at Sayan (Demo)",
                "description": "Hidden within the emerald Ayung River valley in Ubud, accessed via an iconic suspension bridge leading to a lotus pond suspended in the canopy.",
                "address": "Sayan, Ubud, Gianyar, Bali 80571",
                "city": "Denpasar",
                "country": "Indonesia",
                "latitude": -8.508900,
                "longitude": 115.245800,
                "star_rating": 4.9,
                "review_rating": 4.9,
                "review_count": 2150,
                "starting_price": 760.00,
                "currency": "USD",
                "exterior_image_url": "https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?auto=format&fit=crop&w=1200&q=80"
            },
            # Paris Hotels
            {
                "destination_name": "Paris",
                "hotel_name": "The Ritz Paris (Demo)",
                "description": "Synonymous with French high society overlooking Place Vendôme, legendary home of Coco Chanel and Ernest Hemingway.",
                "address": "15 Place Vendôme, 75001 Paris, France",
                "city": "Paris",
                "country": "France",
                "latitude": 48.868200,
                "longitude": 2.329400,
                "star_rating": 5.0,
                "review_rating": 4.9,
                "review_count": 2490,
                "starting_price": 1250.00,
                "currency": "USD",
                "exterior_image_url": "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?auto=format&fit=crop&w=1200&q=80"
            },
            {
                "destination_name": "Paris",
                "hotel_name": "Hôtel Plaza Athénée (Demo)",
                "description": "Haute couture palace on Avenue Montaigne adorned with signature red geraniums, Dior Institute spa, and Eiffel Tower balconies.",
                "address": "25 Avenue Montaigne, 75008 Paris, France",
                "city": "Paris",
                "country": "France",
                "latitude": 48.866000,
                "longitude": 2.304500,
                "star_rating": 5.0,
                "review_rating": 4.8,
                "review_count": 1820,
                "starting_price": 1100.00,
                "currency": "USD",
                "exterior_image_url": "https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1200&q=80"
            },
            # Singapore Hotels
            {
                "destination_name": "Singapore",
                "hotel_name": "Marina Bay Sands (Demo)",
                "description": "World-famous integrated resort featuring three cascading towers crowned by the SkyPark and the world's highest rooftop infinity pool.",
                "address": "10 Bayfront Avenue, Singapore 018956",
                "city": "Singapore",
                "country": "Singapore",
                "latitude": 1.283400,
                "longitude": 103.860700,
                "star_rating": 5.0,
                "review_rating": 4.8,
                "review_count": 6400,
                "starting_price": 620.00,
                "currency": "USD",
                "exterior_image_url": "https://images.unsplash.com/photo-1506354666786-959d6d497f1a?auto=format&fit=crop&w=1200&q=80"
            },
            {
                "destination_name": "Singapore",
                "hotel_name": "Raffles Hotel Singapore (Demo)",
                "description": "Grand colonial dame established in 1887, birthplace of the Singapore Sling cocktail with tranquil tropical courtyards.",
                "address": "1 Beach Road, Singapore 189673",
                "city": "Singapore",
                "country": "Singapore",
                "latitude": 1.294900,
                "longitude": 103.854400,
                "star_rating": 5.0,
                "review_rating": 4.9,
                "review_count": 2780,
                "starting_price": 750.00,
                "currency": "USD",
                "exterior_image_url": "https://images.unsplash.com/photo-1582719508461-905c673771fd?auto=format&fit=crop&w=1200&q=80"
            },
            # Tokyo Hotels
            {
                "destination_name": "Tokyo",
                "hotel_name": "Aman Tokyo (Demo)",
                "description": "Serene urban sanctuary atop the Otemachi Tower, featuring monumental washi paper lantern ceilings and panoramic views of Mount Fuji.",
                "address": "The Otemachi Tower, 1-5-6 Otemachi, Chiyoda-ku, Tokyo 100-0004",
                "city": "Tokyo",
                "country": "Japan",
                "latitude": 35.687200,
                "longitude": 139.764500,
                "star_rating": 5.0,
                "review_rating": 4.9,
                "review_count": 1540,
                "starting_price": 1150.00,
                "currency": "USD",
                "exterior_image_url": "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=1200&q=80"
            },
            {
                "destination_name": "Tokyo",
                "hotel_name": "Park Hyatt Tokyo (Demo)",
                "description": "High in Shinjuku Park Tower with glittering 360-degree city views, made legendary by cinema and the iconic New York Bar jazz lounge.",
                "address": "3-7-1-2 Nishi-Shinjuku, Shinjuku-ku, Tokyo 163-1055",
                "city": "Tokyo",
                "country": "Japan",
                "latitude": 35.685400,
                "longitude": 139.691200,
                "star_rating": 4.8,
                "review_rating": 4.7,
                "review_count": 2300,
                "starting_price": 680.00,
                "currency": "USD",
                "exterior_image_url": "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?auto=format&fit=crop&w=1200&q=80"
            },
            # London Hotels
            {
                "destination_name": "London",
                "hotel_name": "The Savoy London (Demo)",
                "description": "On the Strand overlooking the River Thames, London's most historic luxury hotel blending Edwardian and Art Deco opulence.",
                "address": "Strand, London WC2R 0EZ, United Kingdom",
                "city": "London",
                "country": "United Kingdom",
                "latitude": 51.510300,
                "longitude": -0.120500,
                "star_rating": 5.0,
                "review_rating": 4.8,
                "review_count": 3400,
                "starting_price": 820.00,
                "currency": "USD",
                "exterior_image_url": "https://images.unsplash.com/photo-1571896349842-33c89424de2d?auto=format&fit=crop&w=1200&q=80"
            },
            {
                "destination_name": "London",
                "hotel_name": "Claridge's Mayfair (Demo)",
                "description": "The quintessential Mayfair art-deco jewel, host to kings and fashion legends, renowned for quintessential British afternoon tea.",
                "address": "Brook Street, Mayfair, London W1K 4HR, United Kingdom",
                "city": "London",
                "country": "United Kingdom",
                "latitude": 51.512600,
                "longitude": -0.148700,
                "star_rating": 5.0,
                "review_rating": 4.9,
                "review_count": 2100,
                "starting_price": 950.00,
                "currency": "USD",
                "exterior_image_url": "https://images.unsplash.com/photo-1564501049412-61c2a3083791?auto=format&fit=crop&w=1200&q=80"
            },
            # New York Hotels
            {
                "destination_name": "New York",
                "hotel_name": "The Plaza Hotel Fifth Avenue (Demo)",
                "description": "The timeless castle at Fifth Avenue and Central Park South, providing quintessential Manhattan grandeur for more than a century.",
                "address": "768 5th Ave, New York, NY 10019, United States",
                "city": "New York",
                "country": "United States",
                "latitude": 40.764500,
                "longitude": -73.974400,
                "star_rating": 5.0,
                "review_rating": 4.8,
                "review_count": 4500,
                "starting_price": 980.00,
                "currency": "USD",
                "exterior_image_url": "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?auto=format&fit=crop&w=1200&q=80"
            }
        ]

        standard_facilities = [
            ("High-Speed Wi-Fi", "Complimentary multi-gigabit wireless throughout property"),
            ("Infinity Swimming Pool", "Heated temperature-controlled panoramic pool"),
            ("Signature Fine Dining", "Multi-cuisine Michelin-starred culinary options"),
            ("Spa & Wellness Sanctuary", "Holistic therapy, sauna, steam and hydrotherapy"),
            ("Modern Fitness Center", "24/7 Technogym equipped workout club with personal trainers"),
            ("Valet Parking", "Secure subterranean valet parking with EV charging stations"),
            ("24/7 Concierge Service", "Personal butler and city excursion desk"),
            ("Airport Limousine", "Chauffeured luxury sedan transfers on demand")
        ]

        for h_data in hotels_data:
            dest = dest_map.get(h_data["destination_name"])
            existing_hotel = Hotel.query.filter_by(hotel_name=h_data["hotel_name"]).first()
            if not existing_hotel:
                hotel = Hotel(
                    destination_id=dest.destination_id if dest else None,
                    hotel_name=h_data["hotel_name"],
                    description=h_data["description"],
                    address=h_data["address"],
                    city=h_data["city"],
                    country=h_data["country"],
                    latitude=h_data["latitude"],
                    longitude=h_data["longitude"],
                    star_rating=h_data["star_rating"],
                    review_rating=h_data["review_rating"],
                    review_count=h_data["review_count"],
                    starting_price=h_data["starting_price"],
                    currency=h_data["currency"],
                    exterior_image_url=h_data["exterior_image_url"],
                    exterior_model_url=GLB_ROOM_MODELS[0],
                    data_source="database",
                    is_demo=True
                )
                db.session.add(hotel)
                db.session.flush()

                # Add facilities
                for fac_name, fac_desc in standard_facilities:
                    facility = HotelFacility(
                        hotel_id=hotel.hotel_id,
                        facility_name=fac_name,
                        description=fac_desc
                    )
                    db.session.add(facility)

                # Add Hotel Gallery Images
                gallery_imgs = [
                    (hotel.exterior_image_url, "exterior", "Grand Entrance & Facade", 1),
                    ("https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=1200&q=80", "lobby", "Opulent Reception & Atrium", 2),
                    ("https://images.unsplash.com/photo-1578683010236-d716f9a3f461?auto=format&fit=crop&w=1200&q=80", "interior", "Presidential Suite Living Area", 3),
                    ("https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1200&q=80", "dining", "Fine Dining Pavilion", 4),
                    ("https://images.unsplash.com/photo-1571896349842-33c89424de2d?auto=format&fit=crop&w=1200&q=80", "amenity", "Skyline Infinity Pool", 5)
                ]
                for url, cat, cap, order in gallery_imgs:
                    img = HotelImage(
                        hotel_id=hotel.hotel_id,
                        image_url=url,
                        image_category=cat,
                        caption=cap,
                        display_order=order
                    )
                    db.session.add(img)

                # 4. At least 3 Rooms per Hotel
                rooms_specs = [
                    {
                        "room_name": "Deluxe King Room",
                        "room_type": "Deluxe Room",
                        "description": "Generous soundproof room with custom Italian furniture, king bed, marble bathroom with rain shower, and floor-to-ceiling city views.",
                        "price_per_night": float(hotel.starting_price),
                        "bed_type": "1 King Bed",
                        "room_size": "50 sq.m",
                        "maximum_occupancy": 2,
                        "amenities": json.dumps(["King Bed", "Rain Shower", "Smart 65\" 4K TV", "Nespresso Bar", "Complimentary High-Speed Wi-Fi", "Walk-in Wardrobe"]),
                        "image_url": "https://images.unsplash.com/photo-1618773928121-c32242e63f39?auto=format&fit=crop&w=1200&q=80",
                        "model_url": GLB_ROOM_MODELS[0] # Interactive 3D GLB model
                    },
                    {
                        "room_name": "Executive Horizon Suite",
                        "room_type": "Executive Suite",
                        "description": "Expansive suite featuring separate master bedroom, executive boardroom lounge, butler pantry, and bespoke designer appointments.",
                        "price_per_night": round(float(hotel.starting_price) * 1.65, 2),
                        "bed_type": "1 Super King Bed",
                        "room_size": "95 sq.m",
                        "maximum_occupancy": 3,
                        "amenities": json.dumps(["Super King Bed", "Deep Soaking Jacuzzi", "Executive Club Access", "Private Balcony", "Soundproof Work Desk", "Wine Chiller"]),
                        "image_url": "https://images.unsplash.com/photo-1591088398332-8a7791972843?auto=format&fit=crop&w=1200&q=80",
                        "model_url": GLB_ROOM_MODELS[1]
                    },
                    {
                        "room_name": "Royal Presidential Villa",
                        "room_type": "Presidential Suite",
                        "description": "The ultimate pinnacle of private luxury: dual master suites, private heated plunge pool, dedicated butler kitchen, and panoramic skyline vistas.",
                        "price_per_night": round(float(hotel.starting_price) * 3.2, 2),
                        "bed_type": "2 Emperor Beds",
                        "room_size": "260 sq.m",
                        "maximum_occupancy": 5,
                        "amenities": json.dumps(["Private Plunge Pool", "24/7 Butler Service", "Private Dining Hall", "Bespoke Bar", "Steam Room", "Bang & Olufsen Audio"]),
                        "image_url": "https://images.unsplash.com/photo-1578683010236-d716f9a3f461?auto=format&fit=crop&w=1200&q=80",
                        "model_url": GLB_ROOM_MODELS[2]
                    }
                ]

                for r_spec in rooms_specs:
                    room = Room(
                        hotel_id=hotel.hotel_id,
                        room_name=r_spec["room_name"],
                        room_type=r_spec["room_type"],
                        description=r_spec["description"],
                        price_per_night=r_spec["price_per_night"],
                        currency=hotel.currency,
                        bed_type=r_spec["bed_type"],
                        room_size=r_spec["room_size"],
                        maximum_occupancy=r_spec["maximum_occupancy"],
                        amenities=r_spec["amenities"],
                        image_url=r_spec["image_url"],
                        model_url=r_spec["model_url"]
                    )
                    db.session.add(room)
                    db.session.flush()

                    # Room gallery image
                    r_img = RoomImage(
                        room_id=room.room_id,
                        image_url=r_spec["image_url"],
                        caption=r_spec["room_name"] + " Overview",
                        display_order=1
                    )
                    db.session.add(r_img)

                # 5. Hotel Property Spaces (Banquet Hall, Conference, Dining, Pool)
                spaces_specs = [
                    {
                        "space_name": "Grand Imperial Ballroom",
                        "category": "banquet_hall",
                        "description": "Magnificent pillar-less crystal ballroom ideal for prestigious international galas and royal banquets.",
                        "capacity": 650,
                        "size": "950 sq.m",
                        "price": 2500.00,
                        "opening_hours": "08:00 - 02:00",
                        "amenities": json.dumps(["Stage Lighting", "Concert Acoustic System", "VIP Green Rooms", "Dedicated Banquet Kitchen"]),
                        "image_url": "https://images.unsplash.com/photo-1519167758481-83f550bb49b3?auto=format&fit=crop&w=1200&q=80",
                        "model_url": GLB_ROOM_MODELS[3]
                    },
                    {
                        "space_name": "Executive Summit Boardroom",
                        "category": "conference_hall",
                        "description": "Ergonomic high-tech conference facility with 4K video conferencing walls and translation booths.",
                        "capacity": 45,
                        "size": "140 sq.m",
                        "price": 800.00,
                        "opening_hours": "07:00 - 22:00",
                        "amenities": json.dumps(["Interactive 4K Display", "Video Conference Rig", "Ergonomic Chairs", "Coffee & Tea Lounge"]),
                        "image_url": "https://images.unsplash.com/photo-1431540015161-0bf8663c16ba?auto=format&fit=crop&w=1200&q=80",
                        "model_url": GLB_ROOM_MODELS[4]
                    },
                    {
                        "space_name": "Azure Horizon Rooftop Lounge",
                        "category": "restaurant",
                        "description": "Al fresco gourmet dining and mixology lounge suspended above the city lights.",
                        "capacity": 120,
                        "size": "320 sq.m",
                        "price": 0.00,
                        "opening_hours": "17:00 - 01:00",
                        "amenities": json.dumps(["Open-Air Terrace", "Artisan Cocktail Bar", "Live Jazz", "Sommelier Wine Vault"]),
                        "image_url": "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1200&q=80",
                        "model_url": GLB_ROOM_MODELS[0]
                    }
                ]

                for sp_spec in spaces_specs:
                    space = HotelSpace(
                        hotel_id=hotel.hotel_id,
                        space_name=sp_spec["space_name"],
                        category=sp_spec["category"],
                        description=sp_spec["description"],
                        capacity=sp_spec["capacity"],
                        size=sp_spec["size"],
                        price=sp_spec["price"],
                        currency=hotel.currency,
                        opening_hours=sp_spec["opening_hours"],
                        amenities=sp_spec["amenities"],
                        image_url=sp_spec["image_url"],
                        model_url=sp_spec["model_url"]
                    )
                    db.session.add(space)

        db.session.commit()
        print(f"  ✓ {len(hotels_data)} hotels and spaces seeded successfully.")

        # 6. Sample Trip, Itinerary, Budget, Expenses & Booking for Demo User
        sample_hotel = Hotel.query.first()
        sample_room = Room.query.filter_by(hotel_id=sample_hotel.hotel_id).first()

        existing_trip = Trip.query.filter_by(user_id=demo_user.user_id, trip_name="Royal Hyderabad & Heritage Tour").first()
        if not existing_trip:
            trip_start = date.today() + timedelta(days=14)
            trip_end = trip_start + timedelta(days=5)

            trip = Trip(
                user_id=demo_user.user_id,
                trip_name="Royal Hyderabad & Heritage Tour",
                destination="Hyderabad",
                start_date=trip_start,
                end_date=trip_end,
                traveller_count=2,
                status="planned"
            )
            db.session.add(trip)
            db.session.flush()

            # Add activities
            activities = [
                ("Private Palace Tour & Nizam History", trip_start, "10:00", "13:00", "Taj Falaknuma Palace", 17.3314, 78.4678, "Exclusive palace historian guide"),
                ("Authentic Dum Biryani Tasting", trip_start, "13:30", "15:00", "Paradise Heritage", 17.4411, 78.4870, "Culinary tasting menu"),
                ("Charminar & Laad Bazaar Pearl Shopping", trip_start + timedelta(days=1), "10:30", "14:00", "Charminar, Old City", 17.3616, 78.4747, "Explore traditional lacquer bangles and pearls"),
                ("Golconda Fort Sound & Light Spectacle", trip_start + timedelta(days=2), "17:30", "20:00", "Golconda Fort", 17.3833, 78.4011, "Historic evening fortress show")
            ]
            for act_name, a_date, s_time, e_time, loc, lat, lng, notes in activities:
                activity = TripActivity(
                    trip_id=trip.trip_id,
                    activity_name=act_name,
                    activity_date=a_date,
                    start_time=s_time,
                    end_time=e_time,
                    location=loc,
                    latitude=lat,
                    longitude=lng,
                    notes=notes
                )
                db.session.add(activity)

            # Add Trip Budget
            budget = Budget(
                trip_id=trip.trip_id,
                accommodation_budget=2100.00,
                transport_budget=450.00,
                food_budget=600.00,
                activities_budget=350.00,
                shopping_budget=500.00,
                other_budget=200.00,
                currency="USD"
            )
            budget.calculate_total()
            db.session.add(budget)

            # Add Sample Expenses
            expenses = [
                ("Accommodation", 1050.00, trip_start - timedelta(days=5), "Hotel deposit payment for Palace Suite"),
                ("Transportation", 120.00, trip_start - timedelta(days=3), "Chauffeured airport transfer reservation"),
                ("Activities", 80.00, trip_start - timedelta(days=1), "Heritage monuments priority passes")
            ]
            for cat, amt, exp_d, desc in expenses:
                expense = Expense(
                    trip_id=trip.trip_id,
                    user_id=demo_user.user_id,
                    category=cat,
                    amount=amt,
                    currency="USD",
                    expense_date=exp_d,
                    description=desc
                )
                db.session.add(expense)

            # Add Confirmed Booking
            nights = (trip_end - trip_start).days
            price_night = float(sample_room.price_per_night)
            total_amt = round(price_night * nights * 1.12, 2)
            booking = Booking(
                user_id=demo_user.user_id,
                hotel_id=sample_hotel.hotel_id,
                room_id=sample_room.room_id,
                trip_id=trip.trip_id,
                check_in=trip_start,
                check_out=trip_end,
                guest_count=2,
                number_of_nights=nights,
                price_per_night=price_night,
                total_amount=total_amt,
                currency="USD",
                booking_status="confirmed"
            )
            db.session.add(booking)

            db.session.commit()
            print("  ✓ Sample trip, itinerary activities, budget, expenses and confirmed booking created.")
        else:
            print("  ℹ Sample trip already exists.")

        print("✨ Database seed completed successfully!")

if __name__ == '__main__':
    seed_database()
