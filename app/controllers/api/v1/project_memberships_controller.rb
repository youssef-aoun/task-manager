class Api::V1::ProjectMembershipsController < Api::V1::BaseController
  include Apipie::DSL
  before_action :set_project


  api :GET, '/projects/:project_id/members', 'List all project members'
  desc "Allows project owner and members to view the list of project members."
  header :Authorization, "Authorization token", required: true
  param :project_id, Integer, required: true, desc: "ID of the project"
  error 200, "List of project members"
  error 401, "Unauthorized - Missing or invalid token"
  error 403, "Forbidden - Only project owner and members can view this"
  error 404, "Not Found - Project does not exist or user is not authorized"
  example '
# Request (Owner or Member retrieving project members)
GET /projects/92/members
Authorization: Bearer OWNER_OR_MEMBER_ACCESS_TOKEN

# Response:
    [
      {
        "id": 377,
        "name": "Member 1",
        "email": "member1@example.com"
      },
      {
        "id": 378,
        "name": "Member 2",
        "email": "member2@example.com"
      }
    ]

    # Request (Unauthorized user trying to access members)
    GET /projects/92/members
    Authorization: Bearer RANDOM_USER_ACCESS_TOKEN

    # Response (403 Forbidden):
    {
      "error": "Not authorized"
    }
  '

  def index
    return render json: { error: "Not authorized" }, status: :forbidden unless @project.owner == @current_user || @project.members.include?(@current_user)

    render json: @project.members, status: :ok
  end



  api :POST, '/projects/:project_id/members', 'Add a member to a project'
  desc "Allows the project owner to invite a user to join the project."
  header :Authorization, "Authorization token", required: true
  param :project_id, Integer, required: true, desc: "ID of the project"
  param :email, String, required: true, desc: "Email of the user to be added"
  error 200, "User added successfully"
  error 401, "Unauthorized - Missing or invalid token"
  error 403, "Forbidden - Only the project owner can invite users"
  error 404, "Not Found - User with given email not found"
  error 422, "Unprocessable Entity - User is already a member or owner cannot add themselves"
  example '
    # Request (Owner inviting a user to the project)
    POST /projects/92/members
    Authorization: Bearer OWNER_ACCESS_TOKEN
    {
      "email": "newuser@example.com"
    }

    # Response (Success):
    {
      "message": "User added successfully",
      "project": {
        "id": 92,
        "name": "Project Alpha"
      }
    }

    # Request (Trying to invite a non-existent user)
    POST /projects/92/members
    Authorization: Bearer OWNER_ACCESS_TOKEN
    {
      "email": "fakeuser@example.com"
    }

    # Response (404 Not Found):
    {
      "error": "User not found"
    }

    # Request (Trying to invite an existing member)
    POST /projects/92/members
    Authorization: Bearer OWNER_ACCESS_TOKEN
    {
      "email": "existingmember@example.com"
    }

    # Response (422 Unprocessable Entity):
    {
      "error": "User is already a member of this project"
    }

    # Request (Project owner trying to add themselves)
    POST /projects/92/members
    Authorization: Bearer OWNER_ACCESS_TOKEN
    {
      "email": "owner@example.com"
    }

    # Response (422 Unprocessable Entity):
    {
      "error": "You cannot add yourself to your own project"
    }

    # Request (Non-owner trying to invite a user)
    POST /projects/92/members
    Authorization: Bearer MEMBER_ACCESS_TOKEN
    {
      "email": "anotheruser@example.com"
    }

    # Response (403 Forbidden):
    {
      "error": "Only the project owner can invite users"
    }
  '

  def create
    return render json: { error: "Only the project owner can invite users" }, status: :forbidden unless @project.owner == @current_user

    user = User.find_by(email: params[:email])
    return render json: { error: "User not found" }, status: :not_found unless user

    return render json: { error: "You cannot add yourself to your own project" }, status: :unprocessable_entity if user == @current_user

    return render json: { error: "User is already a member of this project" }, status: :unprocessable_entity if @project.members.include?(user)

    @project.members << user
    render json: { message: "User added successfully", project: @project }, status: :ok
  end


  api :DELETE, '/projects/:project_id/members/:id', 'Remove a member or leave a project'
  desc "Allows the project owner to remove a member, or a member to leave the project."
  header :Authorization, "Authorization token", required: true
  param :project_id, Integer, required: true, desc: "ID of the project"
  param :id, Integer, required: false, desc: "ID of the user to be removed (if empty, the authenticated user will leave the project)"
  error 200, "User successfully removed or left the project"
  error 401, "Unauthorized - Missing or invalid token"
  error 403, "Forbidden - Only the project owner can remove users"
  error 404, "Not Found - User or project does not exist"
  error 422, "Unprocessable Entity - User is not a member"
  example '
    # Request (User voluntarily leaving a project)
    DELETE /projects/92/members
    Authorization: Bearer MEMBER_ACCESS_TOKEN

    # Response:
    {
      "message": "User left the project successfully",
      "project": {
        "id": 92,
        "name": "Project Alpha"
      }
    }

    # Request (Project owner removing a user)
    DELETE /projects/92/members/378
    Authorization: Bearer OWNER_ACCESS_TOKEN

    # Response:
    {
      "message": "User was removed from the project successfully",
      "project": {
        "id": 92,
        "name": "Project Alpha"
      }
    }

    # Request (Unauthorized user trying to remove a member)
    DELETE /projects/92/members/378
    Authorization: Bearer RANDOM_USER_ACCESS_TOKEN

    # Response (403 Forbidden):
    {
      "error": "Only the project owner can remove users"
    }

    # Request (Removing a non-existent user)
    DELETE /projects/92/members/999
    Authorization: Bearer OWNER_ACCESS_TOKEN

    # Response (404 Not Found):
    {
      "error": "User not found"
    }

    # Request (Trying to remove a user who is not a project member)
    DELETE /projects/92/members/400
    Authorization: Bearer OWNER_ACCESS_TOKEN

    # Response (422 Unprocessable Entity):
    {
      "error": "User is not a member"
    }
  '

  def destroy
    user = params[:id] ? User.find_by(id: params[:id]) : @current_user

    return render json: { error: "User not found" }, status: :not_found unless user
    return render json: { error: "User is not a member" }, status: :unprocessable_entity unless @project.members.include?(user)

    if user == @current_user
      action = "left the project"
    else
      return render json: { error: "Only the project owner can remove users" }, status: :forbidden unless @project.owner == @current_user
      action = "was removed from the project"
    end

    @project.members.delete(user)
    @project.tasks.where(assignee_id: user.id).update_all(assignee_id: nil)

    render json: { message: "#{user.name} #{action} successfully", project: @project }, status: :ok
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Project not found" }, status: :not_found
  end
end
