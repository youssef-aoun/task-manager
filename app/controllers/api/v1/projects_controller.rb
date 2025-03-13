class Api::V1::ProjectsController < Api::V1::BaseController
  include Apipie::DSL
  before_action :set_project, only: [:show, :update, :destroy]


  api :GET, '/projects', 'Get all projects'
  desc "Returns a list of projects the user owns or has joined."
  error 200, "Success"
  error 400, "Error"
  header :Authorization, "Authorization token", required: true
  param :type, String, desc: "Filter by type: 'owned' (projects owned by user) or 'joined' (projects user has joined)"
  example '
[
  {
    "id": 1,
    "name": "My Project",
    "description": "An awesome project",
    "owner_id": 5
  }

  {
    "id": 2,
    "name": "My SecondProject",
    "description": "Not so awesome project",
    "owner_id": 5
  }
]
'
  def index
    projects = case params[:type]
               when 'owned'
                 @current_user.projects
               when 'joined'
                 @current_user.joined_projects.distinct
               else
                 Project.where(id: @current_user.projects.select(:id))
                        .or(Project.where(id: @current_user.joined_projects.select(:id)))
                        .distinct
               end

    render json: projects, status: :ok
  end




  api :GET, '/projects/:id', 'Get project details'
  desc "Returns project the user owns or has joined."
  error 200, "Success"
  error 400, "Error"
  error 404, "Not Found"
  header :Authorization, "Authorization token", required: true
  param :id, Integer, desc: "Project id", required: true
  example '
  {
    "id": 1,
    "name": "My Project",
    "description": "An awesome project",
    "owner_id": 5
  }
  '
  def show
    render json: @project
  end

  api :POST, '/projects', 'Create a new project'
  desc "Creates a new project under the authenticated user."
  header :Authorization, "Authorization token", required: true
  param :name, String, desc: "Project name", required: true
  error 201, "Created project"
  error 400, "Bad Request"
  error 401, "Unauthorized"

  example '
  {
    "id": 2,
    "name": "New Project",
    "description": "A brand new project",
    "owner_id": 5
  }
  '
  def create
    project = @current_user.projects.build(project_params)
    if project.save
      render json: project, status: :created
    else
      render json: { errors: project.errors.full_messages }, status: :unprocessable_entity
    end
  end

  api :PUT, '/projects/:id', 'Update a project'
  desc "Updates a project's details. Only the project owner can perform this action."
  header :Authorization, "Authorization token", required: true
  param :id, Integer, required: true, desc: "Project ID"
  param :name, String, desc: "New project name", required: true
  error 200, "Updated project details"
  error 401, "Unauthorized - Missing or invalid token"
  error 403, "Forbidden - Only the project owner can update"
  error 404, "Not Found - Project does not exist"
  example '
    # Request body:
    {
      "project": {
        "name": "New Project Alpha"
      }
    }

    # Response:
    {
      "id": 1,
      "name": "New Project Alpha",
      "description": "Updated project description",
      "owner_id": 5
    }
  '
  def update
    return render json: { error: "Only the project owner can update" }, status: :forbidden unless @project.owner == @current_user

    if @project.update(project_params)
      render json: @project
    else
      render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
    end
  end

  api :DELETE, '/projects/:id', 'Delete a project'
  desc "Deletes a project. Only the project owner can perform this action."
  header :Authorization, "Authorization token", required: true
  param :id, Integer, required: true, desc: "Project ID"
  error 204, "Project deleted successfully (No Content)"
  error 401, "Unauthorized - Missing or invalid token"
  error 403, "Forbidden - Only the project owner can delete"
  error 404, "Not Found - Project does not exist"
  example '
    # Request:
    DELETE /projects/1
    Authorization: Bearer YOUR_ACCESS_TOKEN

    # Response (204 No Content):
    (No body returned)
  '
  def destroy
    return render json: { error: "Only the project owner can delete" }, status: :forbidden unless @project.owner == @current_user

    if @project.destroy
      head :no_content
    else
      render json: { error: "Failed to delete project" }, status: :unprocessable_entity
    end
  end


  private

  def set_project
    @project = Project.find_by!(id: params[:id])
    unless @project.owner == @current_user || @current_user.joined_projects.exists?(@project.id)
      return render json: { error: "Project not found or access denied" }, status: :not_found
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Project not found" }, status: :not_found
  end


  def project_params
    params.require(:project).permit(:name)
  end
end