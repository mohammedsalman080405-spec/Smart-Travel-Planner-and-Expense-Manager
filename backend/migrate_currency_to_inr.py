"""Convert legacy seed/sample records to INR using the ECB snapshot in currency.py.

Safe to rerun: converted rows carry INR currency codes, and the few demo hotels
that were previously mislabeled INR are converted only while their source-sized
rates remain below ₹10,000.
"""
from decimal import Decimal

from app import create_app
from extensions import db
from models import Booking, Budget, Expense, Hotel, HotelSpace, Room
from currency import amount_in_inr


def migrate():
    app = create_app()
    with app.app_context():
        changed = 0
        for model, amount_fields in (
            (Hotel, ('starting_price',)),
            (Room, ('price_per_night',)),
            (HotelSpace, ('price',)),
            (Booking, ('price_per_night', 'total_amount')),
            (Budget, (
                'accommodation_budget', 'transport_budget', 'food_budget',
                'activities_budget', 'shopping_budget', 'other_budget', 'total_budget',
            )),
            (Expense, ('amount',)),
        ):
            for row in model.query.filter(db.func.upper(model.currency) == 'USD').all():
                for field in amount_fields:
                    value = getattr(row, field)
                    if value is not None:
                        setattr(row, field, amount_in_inr(value, 'USD'))
                row.currency = 'INR'
                changed += 1

        # A subset of older demo hotel rows had the INR code applied without
        # converting the original USD-sized seed rate.
        for hotel in Hotel.query.filter(
            Hotel.is_demo.is_(True),
            db.func.upper(Hotel.currency) == 'INR',
            Hotel.starting_price < Decimal('10000'),
        ).all():
            hotel.starting_price = amount_in_inr(hotel.starting_price, 'USD')
            changed += 1

        db.session.commit()
        return changed


if __name__ == '__main__':
    print(f'Converted {migrate()} legacy rows to INR.')
