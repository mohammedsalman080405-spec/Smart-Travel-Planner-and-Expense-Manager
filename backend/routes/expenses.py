from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime
from models.expense import Expense
from models.trip import Trip
from services.expense_service import ExpenseService
from extensions import db

expenses_bp = Blueprint('expenses', __name__, url_prefix='/api/expenses')

@expenses_bp.route('/<int:trip_id>', methods=['GET'])
@jwt_required()
def get_trip_expenses(trip_id):
    user_id = int(get_jwt_identity())
    trip = Trip.query.filter_by(trip_id=trip_id, user_id=user_id).first()
    if not trip:
        return jsonify({'error': 'Trip not found or unauthorized'}), 404

    expenses = ExpenseService.get_trip_expenses(trip_id)
    return jsonify(expenses), 200

@expenses_bp.route('', methods=['POST'])
@jwt_required()
def add_expense():
    user_id = int(get_jwt_identity())
    data = request.get_json() or {}

    trip_id = data.get('trip_id')
    category = data.get('category', 'Other')
    amount = data.get('amount')
    expense_date = data.get('expense_date', datetime.utcnow().strftime('%Y-%m-%d'))
    description = data.get('description', '')
    currency = data.get('currency', 'USD')

    if not trip_id or amount is None:
        return jsonify({'error': 'trip_id and amount are required'}), 400

    trip = Trip.query.filter_by(trip_id=trip_id, user_id=user_id).first()
    if not trip:
        return jsonify({'error': 'Trip not found or unauthorized'}), 404

    expense = ExpenseService.add_expense(
        user_id=user_id,
        trip_id=trip_id,
        category=category,
        amount=float(amount),
        expense_date_str=expense_date,
        description=description,
        currency=currency
    )

    return jsonify({'message': 'Expense recorded successfully', 'expense': expense.to_dict()}), 201

@expenses_bp.route('/<int:expense_id>', methods=['PUT'])
@jwt_required()
def update_expense(expense_id):
    user_id = int(get_jwt_identity())
    expense = Expense.query.filter_by(expense_id=expense_id, user_id=user_id).first()
    if not expense:
        return jsonify({'error': 'Expense not found or unauthorized'}), 404

    data = request.get_json() or {}
    if 'category' in data:
        expense.category = data['category']
    if 'amount' in data:
        expense.amount = float(data['amount'])
    if 'expense_date' in data:
        expense.expense_date = datetime.strptime(data['expense_date'], '%Y-%m-%d').date()
    if 'description' in data:
        expense.description = data['description']

    db.session.commit()
    return jsonify({'message': 'Expense updated successfully', 'expense': expense.to_dict()}), 200

@expenses_bp.route('/<int:expense_id>', methods=['DELETE'])
@jwt_required()
def delete_expense(expense_id):
    user_id = int(get_jwt_identity())
    expense = Expense.query.filter_by(expense_id=expense_id, user_id=user_id).first()
    if not expense:
        return jsonify({'error': 'Expense not found or unauthorized'}), 404

    db.session.delete(expense)
    db.session.commit()
    return jsonify({'message': 'Expense deleted successfully'}), 200
