class Api::V1::UsersController < Api::V1::BaseController
  include Apipie::DSL
  before_action :set_user, only: [:show, :update]


  api :GET, '/users', 'Get all users'
  desc "Returns a paginated list of users."
  error 200, "Successful response"
  error 400, "Bad Request"
  header :Authorization, "Authorization token", required: true
  example '
    {
      "users": [
        {
          "id": 1,
          "name": "my name",
          "email": "myemail@email.com"
        },
        {
          "id": 2,
          "name": "my nick name",
          "email": "mynickname@email.com"
        }
      ],
      "meta": {
        "current_page": 1,
        "total_pages": 3,
        "total_count": 8
      }
    }
  '

  def index
    users = User.page(params[:page]).per(params[:per_page] || 3)
    render json: {
      users: users,
      meta: {
        current_page: users.current_page,
        total_pages: users.total_pages,
        total_count: users.total_count
      }
    }
  end


  api :GET, '/users/:id', 'Get user details'
  desc "Fetches user's details."
  error 200, "Success"
  error 400, "Error"
  error 404, "Not Found"
  header :Authorization, "Authorization token", required: true
  param :id, Integer, desc: "user id", required: true
  example '
    {
      "id": 1,
      "name": "User name",
      "email": "user@email.com"
    }
  '
  def show
    render json: @user.slice(:id, :name, :email), status: :ok
  end


  api :PUT, '/users/:id', 'Update user profile'
  desc "Updates a user's profile information. Only the user themselves can update their profile."
  header :Authorization, "Authorization token", required: true
  param :id, Integer, required: true, desc: "User ID"
  param :name, String, desc: "New user name", required: false
  param :email, String, desc: "New email address (optional)", required: false
  error 200, "Successfully updated user details"
  error 401, "Unauthorized - Missing or invalid token"
  error 403, "Forbidden - Only the user themselves can update their profile"
  example '
    # Request body:
    {
      "user": {
        "name": "John Doe Updated",
        "email": "john.updated@email.com"
      }
    }

    # Response:
    {
      "id": 1,
      "name": "John Doe Updated",
      "email": "john.updated@email.com",
      "updated_at": "2025-03-14T10:25:00Z"
    }
  '

  def update
    unless @current_user
      return render json: { error: "Unauthorized" }, status: :unauthorized
    end

    if @current_user == @user || (@current_user.respond_to?(:admin?) && @current_user.admin?)
      @user.update!(user_params)
      render json: @user.slice(:id, :name, :email, :created_at, :updated_at)
    else
      render json: { error: "You are not authorized to update this user" }, status: :forbidden
    end
  end


  api :DELETE, '/users', 'Delete Profile'
  desc "Deletes the authenticated user's account. This action is irreversible."
  header :Authorization, "Authorization token", required: true
  error 204, "Account deleted successfully (No Content)"
  error 401, "Unauthorized - Missing or invalid token"
  example '
    # Request:
    DELETE /users
    Authorization: Bearer YOUR_ACCESS_TOKEN

    # Response (204 No Content):
    (No body returned)
  '

  def destroy
    if @current_user.destroy
      head :no_content
    else
      render json: { error: "Failed to delete account" }, status: :unprocessable_entity
    end
  end




  def profile
    render json: @current_user.slice(:id, :name, :email)
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

end
