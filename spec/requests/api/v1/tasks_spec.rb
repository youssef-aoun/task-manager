require 'rails_helper'

RSpec.describe "Tasks API", type: :request do
  let(:user) { create(:user) }
  let(:auth_headers) { { "Authorization" => "Bearer #{JsonWebToken.encode(user_id: user.id)}" } }
  let(:project) { create(:project, owner: user) }
  let(:assignee) { create(:user) }
  let!(:task) { create(:task, project: project, assignee: assignee) }

  before do
    project.members << assignee
  end

  describe "GET /api/v1/projects/:project_id/tasks" do
    it "returns paginated tasks for the project" do
      create_list(:task, 5, project: project, assignee: assignee)

      get "/api/v1/projects/#{project.id}/tasks", headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json["tasks"].length).to be <= 3
      expect(json["meta"]["total_count"]).to eq(6)
    end
  end

  describe "POST /api/v1/projects/:project_id/tasks" do
    it "allows only the project owner to create a task" do
      post "/api/v1/projects/#{project.id}/tasks",
           params: { task: { title: "Valid Task Name", status: "pending", assignee_id: assignee.id } },
           headers: auth_headers

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["title"]).to eq("Valid Task Name")
    end

    it "prevents non-owners from creating tasks" do
      non_owner_headers = { "Authorization" => "Bearer #{JsonWebToken.encode(user_id: assignee.id)}" }

      post "/api/v1/projects/#{project.id}/tasks",
           params: { task: { title: "Invalid Task", status: "pending", assignee_id: assignee.id } },
           headers: non_owner_headers

      expect(response).to have_http_status(:forbidden)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("Only the project owner can create tasks")
    end
  end

  describe "GET /api/v1/projects/:project_id/tasks/:id" do
    it "returns a specific task" do
      get "/api/v1/projects/#{project.id}/tasks/#{task.id}", headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["title"]).to eq(task.title)
    end
  end

  describe "PUT /api/v1/projects/:project_id/tasks/:id" do
    it "prevents unauthorized users from updating tasks" do
      unauthorized_user = create(:user)
      project.members << unauthorized_user

      unauthorized_headers = { "Authorization" => "Bearer #{JsonWebToken.encode(user_id: unauthorized_user.id)}" }

      put "/api/v1/projects/#{project.id}/tasks/#{task.id}",
          params: { task: { status: "completed" } },
          headers: unauthorized_headers

      expect(response).to have_http_status(:forbidden)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("You are not authorized to update this task")
    end
  end


  describe "DELETE /api/v1/projects/:project_id/tasks/:id" do
    it "allows only the project owner to delete tasks" do
      delete "/api/v1/projects/#{project.id}/tasks/#{task.id}", headers: auth_headers

      expect(response).to have_http_status(:no_content)
      expect(Task.exists?(task.id)).to be_falsey
    end

    it "prevents non-owners from deleting tasks" do
      non_owner_headers = { "Authorization" => "Bearer #{JsonWebToken.encode(user_id: assignee.id)}" }

      delete "/api/v1/projects/#{project.id}/tasks/#{task.id}", headers: non_owner_headers

      expect(response).to have_http_status(:forbidden)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("Only the project owner can delete tasks")
    end
  end
end
