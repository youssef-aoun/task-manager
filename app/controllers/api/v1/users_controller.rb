class Api::V1::UsersController < Api::V1::BaseController
  def profile
    render json: @current_user, only: [:name, :email]
  end
end
