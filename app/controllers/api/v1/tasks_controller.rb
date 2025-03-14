class Api::V1::TasksController < Api::V1::BaseController
  include Apipie::DSL
  before_action :set_project
  before_action :set_task, only: [:show, :update, :destroy]

  api :GET, '/projects/:project_id/tasks', 'Get tasks for a project'
  desc "Fetches tasks for a project based on user role. Owners see all tasks, members see only assigned tasks."
  header :Authorization, "Authorization token", required: true
  param :project_id, Integer, required: true, desc: "ID of the project"
  param :user_id, Integer, desc: "Filter tasks assigned to a specific user (optional)"
  param :status, String, desc: "Filter tasks by status (optional)"
  param :page, Integer, desc: "Page number for pagination (optional, default: 1)"
  param :per_page, Integer, desc: "Number of tasks per page (optional, default: 3)"

  error 200, "Successful response"
  error 401, "Unauthorized - Missing or invalid token"
  error 403, "Forbidden - Only project members or the owner can access tasks"
  error 404, "Not Found - Project does not exist"

  example '
    # Request (Owner retrieving all tasks)
    GET /projects/1/tasks
    Authorization: Bearer YOUR_ACCESS_TOKEN

    # Response:
    {
    "tasks": [
        {
            "id": 79,
            "title": "Study Ruby",
            "status": "pending",
            "created_at": "2025-03-13T16:51:35.853Z",
            "updated_at": "2025-03-13T16:53:30.189Z",
            "user_id": 377,
            "project_id": 92,
            "assignee_id": 378
        },
        {
            "id": 83,
            "title": "Alternative Task",
            "status": "Completed",
            "created_at": "2025-03-13T16:52:28.492Z",
            "updated_at": "2025-03-13T16:55:02.611Z",
            "user_id": 377,
            "project_id": 92,
            "assignee_id": 378
        }
    ],
    "meta": {
        "current_page": 2,
        "total_pages": 2,
        "total_count": 5
    }
}

    # Request (Member retrieving only assigned tasks)
    GET /projects/1/tasks
    Authorization: Bearer MEMBER_ACCESS_TOKEN

    # Response:
    {
      "tasks": [
        {
          "id": 103,
          "title": "Update API Docs",
          "description": "Improve the API documentation",
          "status": "pending",
          "assignee_id": 12
        }
      ],
      "meta": {
        "current_page": 1,
        "total_pages": 1,
        "total_count": 1
      }
    }

    # Request (Non-member trying to access tasks)
    GET /projects/1/tasks
    Authorization: Bearer NON_MEMBER_ACCESS_TOKEN

    # Response (403 Forbidden):
    {
      "error": "You are not authorized to view tasks for this project"
    }
  '
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



  api :GET, '/projects/:project_id/tasks/:id', 'Get a specific task'
  desc "Fetches a single task for a project. Only the project owner or the assigned user can view the task."
  header :Authorization, "Authorization token", required: true
  param :project_id, Integer, required: true, desc: "ID of the project"
  param :id, Integer, required: true, desc: "ID of the task"
  error 200, "Successful response"
  error 401, "Unauthorized - Missing or invalid token"
  error 403, "Forbidden - Only project members (owner or assignee) can view this task"
  error 404, "Not Found - Task does not exist or the user is not authorized"
  example '
    # Request (Owner retrieving any task)
    GET /projects/92/tasks/80
    Authorization: Bearer OWNER_ACCESS_TOKEN

    # Response:
    {
      "id": 80,
      "title": "Study Rails",
      "status": "in progress",
      "created_at": "2025-03-13T16:51:47.433Z",
      "updated_at": "2025-03-13T16:51:47.433Z",
      "user_id": 377,
      "project_id": 92,
      "assignee_id": null
    }

    # Request (Assigned user retrieving their task)
    GET /projects/92/tasks/80
    Authorization: Bearer ASSIGNEE_ACCESS_TOKEN

    # Response:
    {
      "id": 80,
      "title": "Study Rails",
      "status": "in progress",
      "created_at": "2025-03-13T16:51:47.433Z",
      "updated_at": "2025-03-13T16:51:47.433Z",
      "user_id": 377,
      "project_id": 92,
      "assignee_id": 400
    }

    # Request (Unauthorized user trying to access task)
    GET /projects/92/tasks/80
    Authorization: Bearer RANDOM_USER_ACCESS_TOKEN

    # Response (403 Forbidden):
    {
      "error": "You are not authorized to view this task"
    }
  '

  def show
    render json: @task
  end

  api :POST, '/projects/:project_id/tasks', 'Create a new task in a project'
  desc "Allows the project owner to create a new task within a project."
  header :Authorization, "Authorization token", required: true
  param :project_id, Integer, required: true, desc: "ID of the project"
  param :task, Hash, required: true, desc: "Task details" do
    param :title, String, required: true, desc: "Title of the task"
    param :status, String, desc: "Task status (e.g., 'pending', 'in progress', 'completed')", default: "pending"
    param :assignee_id, Integer, desc: "ID of the user assigned to this task (optional)"
  end
  error 201, "Task successfully created"
  error 401, "Unauthorized - Missing or invalid token"
  error 403, "Forbidden - Only the project owner can create tasks"
  error 422, "Unprocessable Entity - Invalid task parameters"
  example '
    # Request (Project owner creating a task)
    POST /projects/92/tasks
    Authorization: Bearer OWNER_ACCESS_TOKEN
    {
      "task": {
        "title": "Implement Payment Gateway",
        "status": "in progress",
        "assignee_id": 400
      }
    }

    # Response:
    {
      "id": 120,
      "title": "Implement Payment Gateway",
      "status": "in progress",
      "created_at": "2025-03-14T10:30:47.433Z",
      "updated_at": "2025-03-14T10:30:47.433Z",
      "user_id": 377,
      "project_id": 92,
      "assignee_id": 400
    }

    # Request (Member trying to create a task)
    POST /projects/92/tasks
    Authorization: Bearer MEMBER_ACCESS_TOKEN
    {
      "task": {
        "title": "Unauthorized Task",
        "status": "pending"
      }
    }

    # Response (403 Forbidden):
    {
      "error": "Only the project owner can create tasks"
    }

    # Request (Invalid Assignee)
    POST /projects/92/tasks
    Authorization: Bearer OWNER_ACCESS_TOKEN
    {
      "task": {
        "title": "Task with Invalid Assignee",
        "status": "pending",
        "assignee_id": 99999
      }
    }

    # Response (422 Unprocessable Entity):
    {
      "errors": ["Assignee is not a valid project member"]
    }
  '

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



  api :PUT, '/projects/:project_id/tasks/:id', 'Update a task'
  desc "Allows the project owner to fully update a task, while the assignee can only update the status."
  header :Authorization, "Authorization token", required: true
  param :project_id, Integer, required: true, desc: "ID of the project"
  param :id, Integer, required: true, desc: "ID of the task"
  param :task, Hash, required: true, desc: "Task details to update" do
    param :title, String, desc: "Updated task title (Only project owner can update)"
    param :status, String, desc: "Updated task status (Owner and assignee can update)"
    param :assignee_id, Integer, desc: "ID of the new assigned user (Only project owner can update)"
  end
  error 200, "Task successfully updated"
  error 401, "Unauthorized - Missing or invalid token"
  error 403, "Forbidden - Only the project owner can update the task fully, assignee can only update the status"
  error 404, "Not Found - Task does not exist or the user is not authorized"
  error 422, "Unprocessable Entity - Invalid task parameters"
  example '
    # Request (Owner updating any field)
    PUT /projects/92/tasks/120
    Authorization: Bearer OWNER_ACCESS_TOKEN
    {
      "task": {
        "title": "Updated Task Title",
        "status": "completed",
        "assignee_id": 400
      }
    }

    # Response:
    {
      "id": 120,
      "title": "Updated Task Title",
      "status": "completed",
      "created_at": "2025-03-14T10:30:47.433Z",
      "updated_at": "2025-03-14T11:00:12.321Z",
      "user_id": 377,
      "project_id": 92,
      "assignee_id": 400
    }

    # Request (Assignee updating only status)
    PUT /projects/92/tasks/120
    Authorization: Bearer ASSIGNEE_ACCESS_TOKEN
    {
      "task": {
        "status": "in progress"
      }
    }

    # Response:
    {
      "id": 120,
      "title": "Updated Task Title",
      "status": "in progress",
      "created_at": "2025-03-14T10:30:47.433Z",
      "updated_at": "2025-03-14T11:05:22.567Z",
      "user_id": 377,
      "project_id": 92,
      "assignee_id": 400
    }

    # Request (Assignee trying to change the title or assignee_id)
    PUT /projects/92/tasks/120
    Authorization: Bearer ASSIGNEE_ACCESS_TOKEN
    {
      "task": {
        "title": "Hacked Task",
        "assignee_id": 500
      }
    }

    # Response (403 Forbidden):
    {
      "error": "You can only update the status of this task"
    }

    # Request (Unauthorized user trying to update a task)
    PUT /projects/92/tasks/120
    Authorization: Bearer RANDOM_USER_ACCESS_TOKEN
    {
      "task": {
        "title": "Unauthorized Update"
      }
    }

    # Response (403 Forbidden):
    {
      "error": "You are not authorized to update this task"
    }
  '

  def update
    return render json: { error: "You are not authorized to update this task" }, status: :forbidden unless @task.assignee == @current_user || @project.owner == @current_user

    # If the user is only an assignee, restrict updates to `status` only
    if @task.assignee == @current_user
      return render json: { error: "You can only update the status of this task" }, status: :forbidden if task_params.keys.any? { |key| key.to_s != "status" }
    end

    if valid_assignee?(task_params[:assignee_id]) && @task.update(task_params)
      render json: @task
    else
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end



  api :DELETE, '/projects/:project_id/tasks/:id', 'Delete a task'
  desc "Allows the project owner to delete a task from the project."
  header :Authorization, "Authorization token", required: true
  param :project_id, Integer, required: true, desc: "ID of the project"
  param :id, Integer, required: true, desc: "ID of the task"
  error 204, "Task successfully deleted (No Content)"
  error 401, "Unauthorized - Missing or invalid token"
  error 403, "Forbidden - Only the project owner can delete tasks"
  error 404, "Not Found - Task does not exist or user is not authorized"
  example '
    # Request (Owner deleting a task)
    DELETE /projects/92/tasks/120
    Authorization: Bearer OWNER_ACCESS_TOKEN

    # Response (204 No Content):
    (No body returned)

    # Request (Assignee trying to delete a task)
    DELETE /projects/92/tasks/120
    Authorization: Bearer ASSIGNEE_ACCESS_TOKEN

    # Response (403 Forbidden):
    {
      "error": "Only the project owner can delete tasks"
    }

    # Request (Unauthorized user trying to delete a task)
    DELETE /projects/92/tasks/120
    Authorization: Bearer RANDOM_USER_ACCESS_TOKEN

    # Response (403 Forbidden):
    {
      "error": "Only the project owner can delete tasks"
    }
  '

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
