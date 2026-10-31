from routes.auth import auth_bp
from routes.destinations import destinations_bp
from routes.hotels import hotels_bp
from routes.rooms import rooms_bp
from routes.hotel_spaces import hotel_spaces_bp
from routes.bookings import bookings_bp
from routes.trips import trips_bp
from routes.budgets import budgets_bp
from routes.expenses import expenses_bp

def register_routes(app):
    app.register_blueprint(auth_bp)
    app.register_blueprint(destinations_bp)
    app.register_blueprint(hotels_bp)
    app.register_blueprint(rooms_bp)
    app.register_blueprint(hotel_spaces_bp)
    app.register_blueprint(bookings_bp)
    app.register_blueprint(trips_bp)
    app.register_blueprint(budgets_bp)
    app.register_blueprint(expenses_bp)
