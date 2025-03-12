class Api::V1::UsersController < Api::V1::BaseController

  before_action :set_user, only: [:show, :update]

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


  def show
    render json: @user
  end

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




  def destroy_me
    @current_user.destroy!
    head :no_content
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
