class Api::V1::ProjectMembershipsController < Api::V1::BaseController
  before_action :set_project

  def create
    return render json: { error: "Only the project owner can invite users" }, status: :forbidden unless @project.owner == @current_user

    user = User.find_by(id: params[:user_id])
    return render json: { error: "User not found" }, status: :not_found unless user

    if @project.members.include?(user)
      render json: { error: "User is already a member" }, status: :unprocessable_entity
    else
      @project.members << user
      render json: { message: "User added successfully", project: @project }, status: :ok
    end

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


  private

  def set_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Project not found" }, status: :not_found
  end
end
