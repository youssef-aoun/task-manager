class Api::V1::UsersController < ApplicationController
  def profile
    render json: @current_user, only: [:id, :name, :email]
  end
end
