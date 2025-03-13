require 'rails_helper'

RSpec.describe "Projects API", type: :request do
  let(:user) { create(:user) }
  let(:auth_headers) { { "Authorization" => "Bearer #{JsonWebToken.encode(user_id: user.id)}" } }
  let(:project) { create(:project, owner: user) } # ✅ Use `owner` since that's the correct association


  describe "GET /api/v1/projects" do
    it "returns a list of user's projects" do
      create_list(:project, 3, owner: user)


      get "/api/v1/projects", headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(3)
    end
  end

  describe "POST /api/v1/projects" do
    it "creates a new project" do
      post "/api/v1/projects", params: { project: { name: "New Project" } }, headers: auth_headers

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["name"]).to eq("New Project")
    end
  end

  describe "GET /api/v1/projects/:id" do
    it "returns a specific project" do
      get "/api/v1/projects/#{project.id}", headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["name"]).to eq(project.name)
    end
  end

  describe "PUT /api/v1/projects/:id" do
    it "updates a project" do
      put "/api/v1/projects/#{project.id}", params: { project: { name: "Updated Name" } }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["name"]).to eq("Updated Name")
    end
  end

  describe "DELETE /api/v1/projects/:id" do
    it "deletes a project" do
      delete "/api/v1/projects/#{project.id}", headers: auth_headers

      expect(response).to have_http_status(:no_content)
      expect(Project.exists?(project.id)).to be_falsey
    end
  end
end
