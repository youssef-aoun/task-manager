class TasksController < ApplicationController
  before_action :set_user
  before_action :set_task, only: [:show, :update, :destroy]

  def index
    tasks = @user.tasks
    tasks = tasks.where(status: params[:status]) if params[:status].present?
    render json: tasks
  end


  def show
    render json: @task
  end

  def create
    task = @user.tasks.build(task_params)
    if task.save
      render json: task, status: :created
    else
      render json: { errors: task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @task.update(task_params)
      render json: @task
    else
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @task.destroy
    head :no_content
  end

  private

  def set_user
    @user = User.find_by(id: params[:user_id])
    return render json: { errors: "User not found" }, status: :not_found unless @user
  end

  def set_task
    return if @user.nil?  # Ensure @user exists before querying tasks

    @task = @user.tasks.find_by(id: params[:id])
    return render json: { errors: "Task not found" }, status: :not_found unless @task
  end

  def task_params
    params.require(:task).permit(:title, :status)
  end
end
