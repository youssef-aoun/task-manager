class Api::V1::TasksController < Api::V1::BaseController
  before_action :set_task, only: [:show, :update, :destroy]


  def index
    tasks = @current_user.tasks
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
    task = @current_user.tasks.build(task_params)
    task.save!
    render json: task, status: :created
  end

  def update
    @task.update!(task_params)
    render json: @task
  end

  def destroy
    @task.destroy
    head :no_content
  end

  private

  def set_task
    @task = @current_user.tasks.find(params[:id])
  end


  def task_params
    params.require(:task).permit(:title, :status)
  end
end
