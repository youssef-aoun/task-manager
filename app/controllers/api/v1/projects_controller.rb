class Api::V1::ProjectsController < Api::V1::BaseController
  before_action :set_project, only: [:show, :update, :destroy]

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


  def show
    render json: @project
  end

  def create
    project = @current_user.projects.build(project_params)
    if project.save
      render json: project, status: :created
    else
      render json: { errors: project.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    return render json: { error: "Only the project owner can update" }, status: :forbidden unless @project.owner == @current_user

    if @project.update(project_params)
      render json: @project
    else
      render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    return render json: { error: "Only the project owner can delete" }, status: :forbidden unless @project.owner == @current_user

    @project.destroy
    head :no_content
  end

  private

  def set_project
    @project = Project.find_by(id: params[:id], user_id: @current_user.id) || @current_user.joined_projects.find_by(id: params[:id])
    return render json: { error: "Project not found or access denied" }, status: :not_found unless @project
  end

  def project_params
    params.require(:project).permit(:name)
  end
end
