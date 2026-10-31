"""Add persistent overall trip budgets to an existing MySQL database."""
from sqlalchemy import inspect, text

from app import app
from extensions import db


def migrate():
    with app.app_context():
        inspector = inspect(db.engine)
        columns = {column['name'] for column in inspector.get_columns('trips')}

        with db.engine.begin() as connection:
            if 'total_trip_budget' not in columns:
                connection.execute(text(
                    'ALTER TABLE trips ADD COLUMN total_trip_budget '
                    'DECIMAL(12, 2) NOT NULL DEFAULT 0.00'
                ))
            if 'currency' not in columns:
                connection.execute(text(
                    "ALTER TABLE trips ADD COLUMN currency VARCHAR(10) "
                    "NOT NULL DEFAULT 'INR'"
                ))
            connection.execute(text(
                'UPDATE trips AS t JOIN budgets AS b ON b.trip_id = t.trip_id '
                'SET t.total_trip_budget = b.total_budget, '
                "t.currency = COALESCE(b.currency, 'INR') "
                'WHERE t.total_trip_budget = 0'
            ))
        print('Trip budget migration completed.')


if __name__ == '__main__':
    migrate()
