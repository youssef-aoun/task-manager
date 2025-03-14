require 'rails_helper'

RSpec.describe "Project Memberships API", type: :request do
  let(:owner) { create(:user) }
  let(:member) { create(:user) }
  let(:non_member) { create(:user) }
  let(:project) { create(:project, owner: owner) }

  before do
    project.members << member # Add a user as a project member
  end

  let(:owner_headers) { { "Authorization" => "Bearer #{JsonWebToken.encode(user_id: owner.id)}", "Content-Type" => "application/json" } }
  let(:member_headers) { { "Authorization" => "Bearer #{JsonWebToken.encode(user_id: member.id)}" } }
  let(:non_member_headers) { { "Authorization" => "Bearer #{JsonWebToken.encode(user_id: non_member.id)}" } }

  # ✅ **List Project Members**
  describe "GET /api/v1/projects/:project_id/members" do
    it "allows the project owner to view members" do
      get "/api/v1/projects/#{project.id}/members", headers: owner_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1) # Only 1 member added
    end

    it "allows project members to view the list" do
      get "/api/v1/projects/#{project.id}/members", headers: member_headers

      expect(response).to have_http_status(:ok)
    end

    it "prevents non-members from viewing members" do
      get "/api/v1/projects/#{project.id}/members", headers: non_member_headers

      expect(response).to have_http_status(:forbidden)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("Not authorized")
    end
  end

  # ✅ **Add a Member**
  describe "POST /api/v1/projects/:project_id/members" do
    let(:new_user) { create(:user) }

    it "allows the owner to invite a user" do
      post "/api/v1/projects/#{project.id}/members",
           params: { email: new_user.email }.to_json,  # Convert params to JSON
           headers: owner_headers.merge("CONTENT_TYPE" => "application/json")  # Set correct header

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["message"]).to eq("User added successfully")
    end

    it "prevents members from inviting other users" do
      post "/api/v1/projects/#{project.id}/members",
           params: { email: new_user.email }, headers: member_headers

      expect(response).to have_http_status(:forbidden)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("Only the project owner can invite users")
    end

    it "prevents adding the owner to their own project" do
      post "/api/v1/projects/#{project.id}/members",
           params: { email: owner.email }.to_json,  # Convert params to JSON
           headers: owner_headers.merge("CONTENT_TYPE" => "application/json")  # Explicit JSON header

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("You cannot add yourself to your own project")
    end

    it "prevents adding an already existing member" do
      post "/api/v1/projects/#{project.id}/members",
           params: { email: member.email }.to_json,  # Convert params to JSON
           headers: owner_headers.merge("CONTENT_TYPE" => "application/json")  # Explicit JSON header

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("User is already a member of this project")
    end

  end

  # ✅ **Remove a Member or Leave**
  describe "DELETE /api/v1/projects/:project_id/members/:id" do
    it "allows the owner to remove a member" do
      delete "/api/v1/projects/#{project.id}/members/#{member.id}", headers: owner_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["message"]).to include("was removed from the project")
    end

    it "allows a member to leave a project" do
      delete "/api/v1/projects/#{project.id}/members", headers: member_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["message"]).to include("left the project")
    end

    it "prevents a random user from removing a member" do
      delete "/api/v1/projects/#{project.id}/members/#{member.id}", headers: non_member_headers

      expect(response).to have_http_status(:forbidden)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("Only the project owner can remove users")
    end

    it "prevents removing a user who is not a member" do
      another_user = create(:user)
      delete "/api/v1/projects/#{project.id}/members/#{another_user.id}", headers: owner_headers

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("User is not a member")
    end
  end
end
