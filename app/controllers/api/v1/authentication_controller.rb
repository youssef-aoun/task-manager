class Api::V1::AuthenticationController < Api::V1::BaseController
  include Apipie::DSL
  skip_before_action :authenticate_request, only: [:login, :logout, :register]


  api :POST, '/auth/login', 'Logging in a user'
  desc "Logging in a user and generating a JWT token"
  param :email, String, desc: "User's email", required: true
  param :password, String, desc: "User's password", required: true
  error 201, "User logged in"
  error 401, "Unauthorized"

  example '
    # Successful login request body:
    {
      "email": "user@email.com"
      "password": "password"
    }

    # Successful Response:
    {
      "token": "Some token",
      "user": {
          "id": 378,
          "name": "user",
          "email": "user@email.com"
      }
    }

    # Failed login request body:
    {
      "email": "randomemail@email.com"
      "password": "randompassword"
    }

    # Failed Response:
    {
      "error": "Invalid email or password"
    }
  '
  def login
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      token = JsonWebToken.encode(user_id: user.id)
      render json: { token: token, user: user.slice(:id, :name, :email) }, status: :ok
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  api :DELETE, '/auth/logout', 'Log out the current user'
  desc "Logs out the authenticated user by instructing them to discard their token."
  header :Authorization, "Authorization token", required: true
  error 200, "User successfully logged out"
  error 401, "Unauthorized - Missing or invalid token"
  example '
    # Request:
    DELETE /auth/logout
    Authorization: Bearer YOUR_ACCESS_TOKEN

    # Response:
    {
      "message": "Successfully logged out. Please discard your token."
    }

    # Failed Response (Missing token):
    {
      "error": "Missing or invalid token"
    }
  '
  def logout
    if request.headers['Authorization'].blank?
      return render json: { error: "Missing or invalid token" }, status: :unauthorized
    end

    render json: { message: "Successfully logged out. Please discard your token." }, status: :ok
  end




  api :POST, '/auth/register', 'Registering a user'
  desc "Registering a user"
  param :user, Hash, desc: "User parameters", required: true do
    param :name, String, desc: "User's full name", required: true
    param :email, String, desc: "User's email", required: true
    param :password, String, desc: "User's password (minimum 6 characters)", required: true
    param :password_confirmation, String, desc: "Password confirmation", required: true
  end
  error 201, "User Successfully Created"
  error 422, "Validation Failed"

  example '
    # Successful registration request body:
    {
      "user": {
        "name": "user",
        "email": "user@email.com",
        "password": "password",
        "password_confirmation": "password"
      }
    }


    # Successful Response:
    {
      "token": "Some token",
      "user": {
          "id": 378,
          "name": "user",
          "email": "user@email.com"
      }
    }

  '
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
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
