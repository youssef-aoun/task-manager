class Api::V1::TasksController < Api::V1::BaseController
  include Apipie::DSL
  before_action :set_project
  before_action :set_task, only: [:show, :update, :destroy]


  def index
    tasks = @project.owner == @current_user ? @project.tasks : @project.tasks.where(assignee: @current_user)

    tasks = tasks.where(assignee_id: params[:user_id]) if params[:user_id].present?

    tasks = tasks.where(status: params[:status]) if params[:status].present?

    paginated_tasks = tasks.page(params[:page]).per(params[:per_page] || 3)

    render json: {
      tasks: paginated_tasks,
      meta: {
        current_page: paginated_tasks.current_page,
        total_pages: paginated_tasks.total_pages,
        total_count: paginated_tasks.total_count
      }
    }
  end




  def show
    render json: @task
  end

  def create
    return render json: { error: "Only the project owner can create tasks" }, status: :forbidden unless @project.owner == @current_user

    task = @project.tasks.build(task_params)
    task.user_id = @current_user.id

    if valid_assignee?(task.assignee_id) && task.save
      render json: task, status: :created
    else
      render json: { errors: task.errors.full_messages }, status: :unprocessable_entity
    end
  end


  def update
    return render json: { error: "You are not authorized to update this task" }, status: :forbidden unless @task.assignee == @current_user || @project.owner == @current_user

    if valid_assignee?(task_params[:assignee_id]) && @task.update(task_params)
      render json: @task
    else
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    return render json: { error: "Only the project owner can delete tasks" }, status: :forbidden unless @project.owner == @current_user

    @task.destroy
    head :no_content
  end

  private

  def set_task
    @task = @project.tasks.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Task not found" }, status: :not_found
  end

  def set_project
    @project = Project.find_by(id: params[:project_id], owner: @current_user) || @current_user.joined_projects.find_by(id: params[:project_id])
    return render json: { error: "Project not found or you are not a member" }, status: :not_found unless @project
  end


  def task_params
    params.require(:task).permit(:title, :status, :assignee_id)
  end

  def valid_assignee?(assignee_id)
    assignee_id.nil? || @project.owner.id == assignee_id || @project.members.exists?(id: assignee_id)
  end

end
