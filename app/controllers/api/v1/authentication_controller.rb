class Api::V1::AuthenticationController < Api::V1::BaseController
  skip_before_action :authenticate_request, only: [:login, :logout, :register]
  def login
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])
      token = JsonWebToken.encode(user_id: user.id)
      render json: { token: token, user: user.slice(:id, :name, :email) }
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  def logout
    render json: { message: "Successfully logged out. Please discard your token." }, status: :ok
  end

  def register
    user = User.new(user_params)
    if user.save
      token = JsonWebToken.encode(user_id: user.id)
      render json: { token: token, user: user.slice(:id, :name, :email) }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :gender, :password, :password_confirmation)
  end
end
