from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.budget import Budget
from models.trip import Trip
from services.budget_service import BudgetService
from extensions import db

budgets_bp = Blueprint('budgets', __name__, url_prefix='/api/budgets')

@budgets_bp.route('/<int:trip_id>', methods=['GET'])
@jwt_required()
def get_budget(trip_id):
    user_id = int(get_jwt_identity())
    trip = Trip.query.filter_by(trip_id=trip_id, user_id=user_id).first()
    if not trip:
        return jsonify({'error': 'Trip not found or unauthorized'}), 404

    summary = BudgetService.get_trip_financial_summary(trip_id)
    return jsonify(summary), 200

@budgets_bp.route('/<int:trip_id>', methods=['PUT', 'POST'])
@jwt_required()
def update_budget(trip_id):
    user_id = int(get_jwt_identity())
    trip = Trip.query.filter_by(trip_id=trip_id, user_id=user_id).first()
    if not trip:
        return jsonify({'error': 'Trip not found or unauthorized'}), 404

    data = request.get_json() or {}
    budget = BudgetService.get_or_create_budget(trip_id)

    if 'accommodation_budget' in data:
        budget.accommodation_budget = float(data['accommodation_budget'])
    if 'transport_budget' in data:
        budget.transport_budget = float(data['transport_budget'])
    if 'food_budget' in data:
        budget.food_budget = float(data['food_budget'])
    if 'activities_budget' in data:
        budget.activities_budget = float(data['activities_budget'])
    if 'shopping_budget' in data:
        budget.shopping_budget = float(data['shopping_budget'])
    if 'other_budget' in data:
        budget.other_budget = float(data['other_budget'])
    if 'currency' in data:
        budget.currency = data['currency']

    budget.calculate_total()
    db.session.commit()

    summary = BudgetService.get_trip_financial_summary(trip_id)
    return jsonify({'message': 'Budget updated successfully', 'summary': summary}), 200
