class Api::V1::ProjectMembershipsController < Api::V1::BaseController
  before_action :set_project

  def index
    return render json: { error: "Not authorized" }, status: :forbidden unless @project.owner == @current_user || @project.members.include?(@current_user)

    render json: @project.members, status: :ok
  end


  def create
    return render json: { error: "Only the project owner can invite users" }, status: :forbidden unless @project.owner == @current_user

    user = User.find_by(email: params[:email])
    return render json: { error: "User not found" }, status: :not_found unless user

    return render json: { error: "You cannot add yourself to your own project" }, status: :unprocessable_entity if user == @current_user

    return render json: { error: "User is already a member of this project" }, status: :unprocessable_entity if @project.members.include?(user)

    @project.members << user
    render json: { message: "User added successfully", project: @project }, status: :ok
  end



  def destroy
    return render json: { error: "Only the project owner can remove users" }, status: :forbidden unless @project.owner == @current_user

    user = User.find_by(id: params[:id])  # 👈 Fix: use params[:id]
    return render json: { error: "User not found" }, status: :not_found unless user
    return render json: { error: "User is not a member" }, status: :unprocessable_entity unless @project.members.include?(user)

    @project.members.delete(user)
    @project.tasks.where(assignee_id: user.id).update_all(assignee_id: nil)

    render json: { message: "User removed successfully", project: @project }, status: :ok
  end

  def leave
    return render json: { error: "You are not a member of this project" }, status: :forbidden unless @project.members.include?(@current_user)

    @project.members.delete(@current_user)
    @project.tasks.where(assignee_id: @current_user.id).update_all(assignee_id: nil)

    render json: { message: "You have successfully left the project", project: @project }, status: :ok
  end



  private

  def set_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Project not found" }, status: :not_found
  end
end
