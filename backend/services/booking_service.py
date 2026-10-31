from datetime import datetime, date
from models.booking import Booking
from models.room import Room
from extensions import db
from currency import amount_in_inr

class BookingService:
    @staticmethod
    def calculate_price(room: Room, check_in: date, check_out: date):
        nights = (check_out - check_in).days
        if nights <= 0:
            raise ValueError("Check-out date must be after check-in date.")

        price_per_night = float(amount_in_inr(room.price_per_night, room.currency))
        subtotal = round(price_per_night * nights, 2)
        taxes_and_fees = round(subtotal * 0.12, 2) # Standard 12% demo tax & service charge
        total_amount = round(subtotal + taxes_and_fees, 2)

        return {
            'number_of_nights': nights,
            'price_per_night': price_per_night,
            'subtotal': subtotal,
            'taxes_and_fees': taxes_and_fees,
            'total_amount': total_amount,
            'currency': 'INR'
        }

    @staticmethod
    def check_availability(room_id: int, check_in: date, check_out: date):
        # Find any overlapping confirmed booking
        overlapping = Booking.query.filter(
            Booking.room_id == room_id,
            Booking.booking_status == 'confirmed',
            Booking.check_in < check_out,
            Booking.check_out > check_in
        ).first()

        return overlapping is None

    @staticmethod
    def create_booking(user_id: int, hotel_id: int, room_id: int, check_in_str: str, check_out_str: str, guest_count: int = 1, trip_id: int = None):
        try:
            check_in = datetime.strptime(check_in_str, '%Y-%m-%d').date()
            check_out = datetime.strptime(check_out_str, '%Y-%m-%d').date()
        except ValueError:
            raise ValueError("Dates must be in YYYY-MM-DD format.")

        if check_in < date.today():
            raise ValueError("Check-in date cannot be in the past.")

        if check_out <= check_in:
            raise ValueError("Check-out date must be after check-in date.")

        room = Room.query.get(room_id)
        if not room:
            raise ValueError("Room not found.")

        if room.hotel_id != hotel_id:
            raise ValueError("Room does not belong to the selected hotel.")

        if guest_count > room.maximum_occupancy:
            raise ValueError(f"Guest count exceeds maximum occupancy of {room.maximum_occupancy} guests.")

        # Check overlapping bookings
        if not BookingService.check_availability(room_id, check_in, check_out):
            raise ValueError("Selected room is not available for these dates. Please choose different dates or another room.")

        price_info = BookingService.calculate_price(room, check_in, check_out)

        booking = Booking(
            user_id=user_id,
            hotel_id=hotel_id,
            room_id=room_id,
            trip_id=trip_id,
            check_in=check_in,
            check_out=check_out,
            guest_count=guest_count,
            number_of_nights=price_info['number_of_nights'],
            price_per_night=price_info['price_per_night'],
            total_amount=price_info['total_amount'],
            currency=price_info['currency'],
            booking_status='confirmed'
        )

        db.session.add(booking)
        db.session.commit()
        return booking
