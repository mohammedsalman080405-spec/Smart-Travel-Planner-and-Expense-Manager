"""
Seed enrichment script to populate authentic verified luxury hotels
for Dubai, Hyderabad, Paris, Tokyo, and Singapore.
"""
from app import create_app
from extensions import db
from models.destination import Destination
from models.hotel import Hotel
from models.hotel_facility import HotelFacility
from models.hotel_image import HotelImage
from models.room import Room
from models.room_image import RoomImage
from models.hotel_space import HotelSpace

app = create_app()

ADDITIONAL_HOTELS = [
    # ------------------ DUBAI HOTELS ------------------
    {
        "city_key": "Dubai",
        "hotel_name": "Armani Hotel Dubai",
        "description": "Located within the iconic Burj Khalifa, designed personally by Giorgio Armani with discreet luxury and Japanese tatami-inspired aesthetic.",
        "address": "Burj Khalifa, 1 Mohammed bin Rashid Blvd, Downtown Dubai, UAE",
        "city": "Dubai",
        "country": "United Arab Emirates",
        "latitude": 25.197200,
        "longitude": 55.274400,
        "star_rating": 5.0,
        "review_rating": 4.8,
        "review_count": 2850,
        "starting_price": 950.00,
        "exterior_image_url": "https://images.unsplash.com/photo-1578683010236-d716f9a3f461?auto=format&fit=crop&w=1200&q=80",
        "facilities": ["Private Butler Service", "Armani/SPA", "Infinity Pool", "Fine Italian Dining", "Valet Parking"]
    },
    {
        "city_key": "Dubai",
        "hotel_name": "Jumeirah Al Naseem",
        "description": "Contemporary luxury resort set against peaceful ocean gardens overlooking the Burj Al Arab, featuring private beach access and lagoon pools.",
        "address": "Jumeirah Road, Umm Suqeim 3, Dubai, UAE",
        "city": "Dubai",
        "country": "United Arab Emirates",
        "latitude": 25.133600,
        "longitude": 55.185600,
        "star_rating": 5.0,
        "review_rating": 4.9,
        "review_count": 3410,
        "starting_price": 780.00,
        "exterior_image_url": "https://images.unsplash.com/photo-1540541338287-41700207dee6?auto=format&fit=crop&w=1200&q=80",
        "facilities": ["Private Beach", "Turtle Lagoon", "Michelin Dining", "Wellness Spa", "Kids Club"]
    },
    {
        "city_key": "Dubai",
        "hotel_name": "One&Only The Palm",
        "description": "Secluded beachfront enclave with Moorish and Andalusian palace architecture, private cabanas, and private yacht marina on Palm Jumeirah.",
        "address": "West Crescent, Palm Jumeirah, Dubai, UAE",
        "city": "Dubai",
        "country": "United Arab Emirates",
        "latitude": 25.101100,
        "longitude": 55.138500,
        "star_rating": 5.0,
        "review_rating": 4.9,
        "review_count": 1920,
        "starting_price": 1100.00,
        "exterior_image_url": "https://images.unsplash.com/photo-1582719508461-905c673771fd?auto=format&fit=crop&w=1200&q=80",
        "facilities": ["Guerlain Spa", "Private Marina", "Yannick Alléno Cuisine", "Private Beachfront Villas", "24/7 Butler"]
    },
    {
        "city_key": "Dubai",
        "hotel_name": "The Lana, Dorchester Collection",
        "description": "A striking architectural masterwork on the canal waters of Business Bay with dramatic rooftop pool and bespoke British hospitality.",
        "address": "Marasi Drive, Business Bay, Dubai, UAE",
        "city": "Dubai",
        "country": "United Arab Emirates",
        "latitude": 25.188400,
        "longitude": 55.284200,
        "star_rating": 5.0,
        "review_rating": 4.9,
        "review_count": 870,
        "starting_price": 880.00,
        "exterior_image_url": "https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1200&q=80",
        "facilities": ["Dior Spa", "Rooftop Sky Pool", "Michelin Chefs", "Private Rolls-Royce Fleet", "Canal Views"]
    },
    {
        "city_key": "Dubai",
        "hotel_name": "Bulgari Resort Dubai",
        "description": "An exclusive urban oasis carved like a seahorse on Jumeira Bay Island, blending Italian jewelcraft with Middle Eastern coastal charm.",
        "address": "Jumeira Bay Island, Jumeira 2, Dubai, UAE",
        "city": "Dubai",
        "country": "United Arab Emirates",
        "latitude": 25.216300,
        "longitude": 55.234600,
        "star_rating": 5.0,
        "review_rating": 4.9,
        "review_count": 1420,
        "starting_price": 1250.00,
        "exterior_image_url": "https://images.unsplash.com/photo-1571896349842-33c89424de2d?auto=format&fit=crop&w=1200&q=80",
        "facilities": ["Bulgari Yacht Club", "Private Marina", "Il Ristorante Niko Romito", "Private Beach Cove", "Luxury Spa"]
    },
    {
        "city_key": "Dubai",
        "hotel_name": "Address Sky View",
        "description": "Twin towers connected by a spectacular glass Sky Bridge with infinity pool overlooking Burj Khalifa and downtown Dubai.",
        "address": "Emaar Square Area, Downtown Dubai, UAE",
        "city": "Dubai",
        "country": "United Arab Emirates",
        "latitude": 25.201600,
        "longitude": 55.267800,
        "star_rating": 4.9,
        "review_rating": 4.8,
        "review_count": 3100,
        "starting_price": 650.00,
        "exterior_image_url": "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?auto=format&fit=crop&w=1200&q=80",
        "facilities": ["Sky Bridge Infinity Pool", "Glass Sky Walk", "Fine Dining", "Direct Mall Access", "Executive Club"]
    },
    {
        "city_key": "Dubai",
        "hotel_name": "Mandarin Oriental Jumeira",
        "description": "A chic urban resort along the golden sands of Jumeirah, with luminous canopy of bronze trees in the lobby and sublime sea-facing balconies.",
        "address": "1 Jumeirah Beach Road, Jumeirah 1, Dubai, UAE",
        "city": "Dubai",
        "country": "United Arab Emirates",
        "latitude": 25.228500,
        "longitude": 55.251400,
        "star_rating": 5.0,
        "review_rating": 4.8,
        "review_count": 2180,
        "starting_price": 890.00,
        "exterior_image_url": "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?auto=format&fit=crop&w=1200&q=80",
        "facilities": ["Subs Japanese Steakhouse", "Full Sea Views", "Spa at Mandarin Oriental", "Cabana Club", "Heated Pools"]
    },
    {
        "city_key": "Dubai",
        "hotel_name": "Atlantis, The Palm",
        "description": "The original legendary ocean-themed resort on Palm Jumeirah, featuring Aquaventure Waterpark, underwater suites, and Lost Chambers aquarium.",
        "address": "Crescent Road, Palm Jumeirah, Dubai, UAE",
        "city": "Dubai",
        "country": "United Arab Emirates",
        "latitude": 25.130400,
        "longitude": 55.117100,
        "star_rating": 4.9,
        "review_rating": 4.8,
        "review_count": 6800,
        "starting_price": 720.00,
        "exterior_image_url": "https://images.unsplash.com/photo-1512453979798-5ea266f8880c?auto=format&fit=crop&w=1200&q=80",
        "facilities": ["Aquaventure Access", "Lost Chambers Aquarium", "Nobu Restaurant", "Private Beach", "Helipad"]
    },

    # ------------------ HYDERABAD HOTELS ------------------
    {
        "city_key": "Hyderabad",
        "hotel_name": "Taj Krishna Hyderabad",
        "description": "Prestigious landmark hotel nestled amidst 9 acres of manicured gardens in Banjara Hills, celebrating Nizam culinary traditions.",
        "address": "Road No. 1, Banjara Hills, Hyderabad, Telangana 500034",
        "city": "Hyderabad",
        "country": "India",
        "latitude": 17.416800,
        "longitude": 78.450300,
        "star_rating": 4.9,
        "review_rating": 4.8,
        "review_count": 2340,
        "starting_price": 210.00,
        "exterior_image_url": "https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1200&q=80",
        "facilities": ["Jiva Spa", "Grand Ballroom", "Nizami Dining", "Outdoor Pool", "Concierge Service"]
    },
    {
        "city_key": "Hyderabad",
        "hotel_name": "Trident Hyderabad",
        "description": "Contemporary haven in the heart of HITEC City, offering spacious light-filled rooms, award-winning spa, and rooftop pool.",
        "address": "Hitec City, Near Cyber Towers, Madhapur, Hyderabad 500081",
        "city": "Hyderabad",
        "country": "India",
        "latitude": 17.447500,
        "longitude": 78.377600,
        "star_rating": 4.8,
        "review_rating": 4.7,
        "review_count": 1820,
        "starting_price": 185.00,
        "exterior_image_url": "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=1200&q=80",
        "facilities": ["Trident Spa", "Infinity Pool", "Kanai Pan-Asian Restaurant", "Business Center", "Fitness Center"]
    },
    {
        "city_key": "Hyderabad",
        "hotel_name": "Sheraton Hyderabad Hotel",
        "description": "Modern luxury in the Financial District of Gachibowli, featuring plush Sheraton Sleep Experience beds, heated pool, and bowling alley.",
        "address": "115/1 Nanakramguda, Financial District, Gachibowli, Hyderabad 500032",
        "city": "Hyderabad",
        "country": "India",
        "latitude": 17.418400,
        "longitude": 78.344800,
        "star_rating": 4.8,
        "review_rating": 4.7,
        "review_count": 1540,
        "starting_price": 165.00,
        "exterior_image_url": "https://images.unsplash.com/photo-1571896349842-33c89424de2d?auto=format&fit=crop&w=1200&q=80",
        "facilities": ["Sheraton Club Lounge", "Heated Pool", "Shine Spa", "The Link Cafe", "Airport Shuttle"]
    },
    {
        "city_key": "Hyderabad",
        "hotel_name": "The Westin Hyderabad Mindspace",
        "description": "Revitalizing wellness-focused hotel inside Raheja Mindspace IT park, featuring Heavenly Beds, Heavenly Spa, and scenic lake views.",
        "address": "Raheja IT Park, Hitec City, Madhapur, Hyderabad 500081",
        "city": "Hyderabad",
        "country": "India",
        "latitude": 17.441800,
        "longitude": 78.381500,
        "star_rating": 4.9,
        "review_rating": 4.8,
        "review_count": 2100,
        "starting_price": 220.00,
        "exterior_image_url": "https://images.unsplash.com/photo-1582719508461-905c673771fd?auto=format&fit=crop&w=1200&q=80",
        "facilities": ["Heavenly Spa by Westin", "Outdoor Heated Pool", "Prego Italian", "WestinWORKOUT Gym", "Executive Lounge"]
    },
    {
        "city_key": "Hyderabad",
        "hotel_name": "Novotel Hyderabad Convention Centre",
        "description": "Sprawling 15-acre resort oasis adjacent to HITEX exhibition grounds with palm-fringed swimming pool and international gastronomy.",
        "address": "Near Hitec City, P.O. Bag 1101, Kondapur, Hyderabad 500081",
        "city": "Hyderabad",
        "country": "India",
        "latitude": 17.472500,
        "longitude": 78.372800,
        "star_rating": 4.7,
        "review_rating": 4.6,
        "review_count": 2980,
        "starting_price": 155.00,
        "exterior_image_url": "https://images.unsplash.com/photo-1564501049412-61c2a3083791?auto=format&fit=crop&w=1200&q=80",
        "facilities": ["Resort Swimming Pool", "Grand Ballroom", "O2 Spa", "Convention Facilities", "Jogging Track"]
    },

    # ------------------ PARIS HOTELS ------------------
    {
        "city_key": "Paris",
        "hotel_name": "Le Meurice",
        "description": "Historic palace hotel opposite Tuileries Garden, renowned for Dali-inspired artistic whimsy and Alain Ducasse cuisine.",
        "address": "228 Rue de Rivoli, 75001 Paris, France",
        "city": "Paris",
        "country": "France",
        "latitude": 48.865300,
        "longitude": 2.328300,
        "star_rating": 5.0,
        "review_rating": 4.9,
        "review_count": 2150,
        "starting_price": 1350.00,
        "exterior_image_url": "https://images.unsplash.com/photo-1502602898657-3e91760cbb34?auto=format&fit=crop&w=1200&q=80",
        "facilities": ["Alain Ducasse Restaurant", "Valmont Spa", "Tuileries Views", "Dali Salon", "Private Concierge"]
    },
    {
        "city_key": "Paris",
        "hotel_name": "Four Seasons Hotel George V",
        "description": "Art Deco landmark off the Champs-Élysées, featuring monumental floral installations by Jeff Leatham and 5 Michelin stars under one roof.",
        "address": "31 Avenue George V, 75008 Paris, France",
        "city": "Paris",
        "country": "France",
        "latitude": 48.868800,
        "longitude": 2.300800,
        "star_rating": 5.0,
        "review_rating": 4.9,
        "review_count": 3400,
        "starting_price": 1550.00,
        "exterior_image_url": "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?auto=format&fit=crop&w=1200&q=80",
        "facilities": ["Le Cinq (3 Michelin Stars)", "Luxury Indoor Pool", "Haute Spa", "Eiffel Tower Suites", "Valet Limousine"]
    },
    {
        "city_key": "Paris",
        "hotel_name": "Shangri-La Paris",
        "description": "Former residence of Prince Roland Bonaparte overlooking the Seine with unrivaled front-row panoramas of the Eiffel Tower.",
        "address": "10 Avenue d'Iéna, 75116 Paris, France",
        "city": "Paris",
        "country": "France",
        "latitude": 48.863700,
        "longitude": 2.293300,
        "star_rating": 5.0,
        "review_rating": 4.9,
        "review_count": 1890,
        "starting_price": 1200.00,
        "exterior_image_url": "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=1200&q=80",
        "facilities": ["Direct Eiffel Tower Balconies", "Shang Palace", "CHI Spa", "Indoor Pool", "Historical Salons"]
    },
    {
        "city_key": "Paris",
        "hotel_name": "Hôtel de Crillon, A Rosewood Hotel",
        "description": "Historic neoclassical palace overlooking Place de la Concorde, masterfully reimagined with Karl Lagerfeld suites.",
        "address": "10 Place de la Concorde, 75008 Paris, France",
        "city": "Paris",
        "country": "France",
        "latitude": 48.867200,
        "longitude": 2.321800,
        "star_rating": 5.0,
        "review_rating": 4.9,
        "review_count": 1750,
        "starting_price": 1400.00,
        "exterior_image_url": "https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1200&q=80",
        "facilities": ["Sense Spa", "Subterranean Pool", "L'Écrin Gastronomy", "Butler Service", "Historic Courtyards"]
    },
    {
        "city_key": "Paris",
        "hotel_name": "Le Bristol Paris",
        "description": "The quintessential Parisian palace hotel on Rue du Faubourg Saint-Honoré, famous for French gardens and rooftop yacht-cabin pool.",
        "address": "112 Rue du Faubourg Saint-Honoré, 75008 Paris, France",
        "city": "Paris",
        "country": "France",
        "latitude": 48.871900,
        "longitude": 2.314600,
        "star_rating": 5.0,
        "review_rating": 4.9,
        "review_count": 2240,
        "starting_price": 1300.00,
        "exterior_image_url": "https://images.unsplash.com/photo-1582719508461-905c673771fd?auto=format&fit=crop&w=1200&q=80",
        "facilities": ["Epicure (3 Michelin Stars)", "Rooftop Indoor Pool", "Spa Le Bristol by La Prairie", "Private Garden", "Luxury Suites"]
    },
    {
        "city_key": "Paris",
        "hotel_name": "The Peninsula Paris",
        "description": "Belle Époque palace steps from the Arc de Triomphe, blending French heritage with cutting-edge Asian hotel technology.",
        "address": "19 Avenue Kléber, 75116 Paris, France",
        "city": "Paris",
        "country": "France",
        "latitude": 48.871200,
        "longitude": 2.293400,
        "star_rating": 5.0,
        "review_rating": 4.8,
        "review_count": 1620,
        "starting_price": 1250.00,
        "exterior_image_url": "https://images.unsplash.com/photo-1571896349842-33c89424de2d?auto=format&fit=crop&w=1200&q=80",
        "facilities": ["L'Oiseau Blanc Rooftop", "Peninsula Spa", "Indoor Pool", "Arc de Triomphe Views", "Fleet of Rolls-Royces"]
    },

    # ------------------ TOKYO HOTELS ------------------
    {
        "city_key": "Tokyo",
        "hotel_name": "The Ritz-Carlton, Tokyo",
        "description": "Occupying top floors of Tokyo Midtown in Roppongi, featuring panoramic vistas of Mount Fuji and Tokyo Tower with traditional tea house.",
        "address": "Tokyo Midtown, 9-7-1 Akasaka, Minato-ku, Tokyo 107-6245",
        "city": "Tokyo",
        "country": "Japan",
        "latitude": 35.665700,
        "longitude": 139.730800,
        "star_rating": 5.0,
        "review_rating": 4.8,
        "review_count": 2400,
        "starting_price": 980.00,
        "exterior_image_url": "https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=1200&q=80",
        "facilities": ["Club Lounge on 53F", "Skyline Lap Pool", "Michelin Dining", "Traditional Tea House", "ESPA Spa"]
    },
    {
        "city_key": "Tokyo",
        "hotel_name": "Palace Hotel Tokyo",
        "description": "Grand contemporary sanctuary overlooking the Imperial Palace gardens and moat, praised for serene Japanese aesthetics.",
        "address": "1-1-1 Marunouchi, Chiyoda-ku, Tokyo 100-0005",
        "city": "Tokyo",
        "country": "Japan",
        "latitude": 35.685000,
        "longitude": 139.761700,
        "star_rating": 5.0,
        "review_rating": 4.9,
        "review_count": 2890,
        "starting_price": 850.00,
        "exterior_image_url": "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=1200&q=80",
        "facilities": ["Imperial Palace Balconies", "evian SPA", "Wadakura Kaiseki", "Indoor Pool", "Marunouchi Location"]
    },
    {
        "city_key": "Tokyo",
        "hotel_name": "HOSHINOYA Tokyo",
        "description": "A vertical luxury ryokan in Otemachi where guests slip off shoes at the entrance onto soft tatami mats with top-floor hot-spring onsen.",
        "address": "1-9-1 Otemachi, Chiyoda-ku, Tokyo 100-0004",
        "city": "Tokyo",
        "country": "Japan",
        "latitude": 35.688100,
        "longitude": 139.766700,
        "star_rating": 5.0,
        "review_rating": 4.9,
        "review_count": 1310,
        "starting_price": 920.00,
        "exterior_image_url": "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?auto=format&fit=crop&w=1200&q=80",
        "facilities": ["Rooftop Natural Onsen", "Tatami Living Lounges", "Nippon Gastronomy", "Sake Tasting", "Tea Ceremony"]
    },
    {
        "city_key": "Tokyo",
        "hotel_name": "Mandarin Oriental, Tokyo",
        "description": "Perched in Nihonbashi with jaw-dropping views of Tokyo Skytree, offering Michelin-starred French and Cantonese dining.",
        "address": "2-1-1 Nihonbashi Muromachi, Chuo-ku, Tokyo 103-8328",
        "city": "Tokyo",
        "country": "Japan",
        "latitude": 35.687000,
        "longitude": 139.773200,
        "star_rating": 5.0,
        "review_rating": 4.8,
        "review_count": 2100,
        "starting_price": 890.00,
        "exterior_image_url": "https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1200&q=80",
        "facilities": ["Signature Spa Suites", "Pizza Bar on 38th", "Skytree Views", "Fitness Center", "Concierge Service"]
    },
    {
        "city_key": "Tokyo",
        "hotel_name": "Grand Hyatt Tokyo",
        "description": "Dynamic lifestyle hotel in Roppongi Hills, integrated with high-end boutiques, Mori Art Museum, and 10 world-class restaurants.",
        "address": "6-10-3 Roppongi, Minato-ku, Tokyo 106-0032",
        "city": "Tokyo",
        "country": "Japan",
        "latitude": 35.659600,
        "longitude": 139.729200,
        "star_rating": 4.8,
        "review_rating": 4.7,
        "review_count": 2750,
        "starting_price": 640.00,
        "exterior_image_url": "https://images.unsplash.com/photo-1582719508461-905c673771fd?auto=format&fit=crop&w=1200&q=80",
        "facilities": ["Nagomi Spa & Fitness", "Granite Lap Pool", "Roppongi Hills Access", "Oak Door Steakhouse", "Club Lounge"]
    },
    {
        "city_key": "Tokyo",
        "hotel_name": "Conrad Tokyo",
        "description": "Towering over Shiodome with panoramic views of Tokyo Bay and Hamarikyu Gardens, blending contemporary flair with Japanese art.",
        "address": "1-9-1 Higashi-Shinbashi, Minato-ku, Tokyo 105-7337",
        "city": "Tokyo",
        "country": "Japan",
        "latitude": 35.663700,
        "longitude": 139.760100,
        "star_rating": 4.9,
        "review_rating": 4.8,
        "review_count": 1980,
        "starting_price": 720.00,
        "exterior_image_url": "https://images.unsplash.com/photo-1571896349842-33c89424de2d?auto=format&fit=crop&w=1200&q=80",
        "facilities": ["Mizuki Spa", "Tokyo Bay Lap Pool", "Kazahana Japanese", "Executive Floor", "Bar & Lounge TwentyEight"]
    },

    # ------------------ SINGAPORE HOTELS ------------------
    {
        "city_key": "Singapore",
        "hotel_name": "The Fullerton Hotel Singapore",
        "description": "A magnificent neoclassical landmark at the mouth of the Singapore River, formerly the General Post Office, exuding heritage charm.",
        "address": "1 Fullerton Square, Singapore 049178",
        "city": "Singapore",
        "country": "Singapore",
        "latitude": 1.286300,
        "longitude": 103.853600,
        "star_rating": 5.0,
        "review_rating": 4.8,
        "review_count": 4200,
        "starting_price": 520.00,
        "exterior_image_url": "https://images.unsplash.com/photo-1525625293386-3f8f99389edd?auto=format&fit=crop&w=1200&q=80",
        "facilities": ["Infinity Pool over River", "The Fullerton Spa", "Post Bar", "Heritage Tours", "Straits Club Lounge"]
    },
    {
        "city_key": "Singapore",
        "hotel_name": "Capella Singapore",
        "description": "Set within 30 acres of rolling rainforest on Sentosa Island, seamlessly integrating colonial manors with curved modern suites.",
        "address": "1 The Knolls, Sentosa Island, Singapore 098297",
        "city": "Singapore",
        "country": "Singapore",
        "latitude": 1.249400,
        "longitude": 103.824700,
        "star_rating": 5.0,
        "review_rating": 4.9,
        "review_count": 2180,
        "starting_price": 880.00,
        "exterior_image_url": "https://images.unsplash.com/photo-1540541338287-41700207dee6?auto=format&fit=crop&w=1200&q=80",
        "facilities": ["Tiered Cascading Pools", "Auriga Spa", "Cassia Cantonese Dining", "Private Sea-view Villas", "Peacock Gardens"]
    },
    {
        "city_key": "Singapore",
        "hotel_name": "The Ritz-Carlton, Millenia Singapore",
        "description": "Renowned for museum-quality 4,200-piece art collection, geometric octagonal bathroom windows with Marina Bay views, and Ritz Lounge.",
        "address": "7 Raffles Avenue, Marina Bay, Singapore 039799",
        "city": "Singapore",
        "country": "Singapore",
        "latitude": 1.290600,
        "longitude": 103.859600,
        "star_rating": 5.0,
        "review_rating": 4.9,
        "review_count": 3900,
        "starting_price": 680.00,
        "exterior_image_url": "https://images.unsplash.com/photo-1506354666786-959d6d497f1a?auto=format&fit=crop&w=1200&q=80",
        "facilities": ["Marina Bay Views", "Summer Pavilion (Michelin Star)", "Ritz-Carlton Spa", "Outdoor Pool", "Club Lounge"]
    },
    {
        "city_key": "Singapore",
        "hotel_name": "Shangri-La Singapore",
        "description": "Nestled within 15 acres of exotic botanical gardens, with orchid greenhouses, free-form pool, and tranquil Valley Wing luxury.",
        "address": "22 Orange Grove Road, Singapore 258350",
        "city": "Singapore",
        "country": "Singapore",
        "latitude": 1.311500,
        "longitude": 103.826700,
        "star_rating": 5.0,
        "review_rating": 4.8,
        "review_count": 3100,
        "starting_price": 490.00,
        "exterior_image_url": "https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1200&q=80",
        "facilities": ["15 Acres Botanic Gardens", "Chi, The Spa", "Valley Wing Privileges", "Free-form Pool", "Origin Grill"]
    },
    {
        "city_key": "Singapore",
        "hotel_name": "Andaz Singapore",
        "description": "Designed by Ole Scheeren inside the organic honeycomb DUO towers in Bugis, with Mr. Stork 360-degree rooftop tepee bar.",
        "address": "5 Fraser Street, Singapore 189354",
        "city": "Singapore",
        "country": "Singapore",
        "latitude": 1.300200,
        "longitude": 103.857600,
        "star_rating": 4.8,
        "review_rating": 4.7,
        "review_count": 2650,
        "starting_price": 440.00,
        "exterior_image_url": "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=1200&q=80",
        "facilities": ["Mr. Stork Rooftop Bar", "Infinity Lap Pool on 25F", "Alley on 25 Dining", "Bugis Arts District", "Modern Rooms"]
    },
    {
        "city_key": "Singapore",
        "hotel_name": "The St. Regis Singapore",
        "description": "Situated at the tranquil end of Orchard Road, synonymous with legendary 24-hour St. Regis Butler Service and Remède Spa.",
        "address": "29 Tanglin Road, Singapore 247911",
        "city": "Singapore",
        "country": "Singapore",
        "latitude": 1.305600,
        "longitude": 103.826100,
        "star_rating": 5.0,
        "review_rating": 4.8,
        "review_count": 2450,
        "starting_price": 580.00,
        "exterior_image_url": "https://images.unsplash.com/photo-1582719508461-905c673771fd?auto=format&fit=crop&w=1200&q=80",
        "facilities": ["Signature Butler Service", "Remède Spa & Wet Lounge", "Yan Ting Cantonese", "Private Art Collection", "Orchard Access"]
    }
]

GLB_ROOM_MODELS = [
    "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/SheenChair/glTF-Binary/SheenChair.glb",
    "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/AntiqueCamera/glTF-Binary/AntiqueCamera.glb",
    "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/Lantern/glTF-Binary/Lantern.glb"
]

def run():
    with app.app_context():
        print("🌱 Seeding authentic luxury hotels for Dubai, Hyderabad, Paris, Tokyo, Singapore...")
        dest_map = {d.name: d for d in Destination.query.all()}
        
        added = 0
        for info in ADDITIONAL_HOTELS:
            existing = Hotel.query.filter_by(hotel_name=info["hotel_name"]).first()
            if existing:
                continue
            
            dest = dest_map.get(info["city_key"])
            hotel = Hotel(
                destination_id=dest.destination_id if dest else None,
                hotel_name=info["hotel_name"],
                description=info["description"],
                address=info["address"],
                city=info["city"],
                country=info["country"],
                latitude=info["latitude"],
                longitude=info["longitude"],
                star_rating=info["star_rating"],
                review_rating=info["review_rating"],
                review_count=info["review_count"],
                starting_price=info["starting_price"],
                currency="USD",
                exterior_image_url=info["exterior_image_url"],
                exterior_model_url=GLB_ROOM_MODELS[0],
                is_demo=True,
                data_source="database"
            )
            db.session.add(hotel)
            db.session.flush()

            # Add facilities
            for f_name in info["facilities"]:
                fac = HotelFacility(hotel_id=hotel.hotel_id, facility_name=f_name)
                db.session.add(fac)

            # Add default luxury room
            room = Room(
                hotel_id=hotel.hotel_id,
                room_name="Grand Presidential Luxury Suite",
                room_type="Presidential Suite",
                description=f"Expansive master suite at {info['hotel_name']} featuring floor-to-ceiling panoramic views, marble ensuite bath, bespoke artisan furnishings, and high-tech climate controls.",
                price_per_night=info["starting_price"] * 1.35,
                currency="USD",
                maximum_occupancy=3,
                bed_type="King Bed",
                room_size="85 sq.m",
                image_url=info["exterior_image_url"],
                model_url=GLB_ROOM_MODELS[added % len(GLB_ROOM_MODELS)],
                availability_status="available"
            )
            db.session.add(room)
            db.session.flush()

            r_img = RoomImage(
                room_id=room.room_id,
                image_url=info["exterior_image_url"],
                caption="Grand Presidential Suite Living Area",
                display_order=1
            )
            db.session.add(r_img)

            # Add hotel spaces
            space1 = HotelSpace(
                hotel_id=hotel.hotel_id,
                space_name="Royal Grand Ballroom & Banquet",
                category="banquet_hall",
                description="Opulent pillarless ballroom adorned with crystal chandeliers and state-of-the-art acoustic engineering.",
                model_url=GLB_ROOM_MODELS[1],
                image_url=info["exterior_image_url"],
                capacity=350,
                price=1200.0,
                currency="USD"
            )
            space2 = HotelSpace(
                hotel_id=hotel.hotel_id,
                space_name="The Sanctuary Spa & Hydrotherapy Lounge",
                category="spa",
                description="Tranquil wellness sanctuary with thermal vitality pools, eucalyptus steam chambers, and private treatment cabanas.",
                model_url=GLB_ROOM_MODELS[2],
                image_url=info["exterior_image_url"],
                capacity=40,
                price=180.0,
                currency="USD"
            )
            db.session.add(space1)
            db.session.add(space2)

            added += 1

        db.session.commit()
        print(f"✓ Added {added} authentic luxury hotels with rooms, spaces, and coordinates!")

if __name__ == "__main__":
    run()
