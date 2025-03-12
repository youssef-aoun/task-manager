class Api::V1::BaseController < ApplicationController
  before_action :authenticate_request  # ✅ Enforces authentication on API controllers

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid

  private

  def authenticate_request
    header = request.headers['Authorization']
    token = header.split(' ').last if header

    decoded = JsonWebToken.decode(token)
    @current_user = User.find_by(id: decoded[:user_id]) if decoded

    render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user
  end

  def record_not_found(exception)
    model_name = exception.model || "Record"
    render json: { error: "#{model_name} not found" }, status: :not_found
  end

  def record_invalid(exception)
    render json: { errors: exception.record.errors.full_messages}, :status => :unprocessable_entity
  end
end
