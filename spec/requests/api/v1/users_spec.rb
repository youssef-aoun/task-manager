require 'rails_helper'

RSpec.describe "Users API", type: :request do
  let!(:users) { create_list(:user, 3) }
  let(:user) { users.first }
  let(:auth_headers) { { "Authorization" => "Bearer #{user_token}" } }

  let(:user_token) do
    post "/api/v1/auth/login", params: { email: user.email, password: "password123" }
    JSON.parse(response.body)["token"]
  end

  before do
    user_token # Ensure user is logged in before each test
  end

  describe "GET /api/v1/users" do
    it "returns a paginated list of users" do
      get "/api/v1/users", headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["users"]).not_to be_empty
      expect(json["meta"]).to include("current_page", "total_pages", "total_count")
    end
  end

  describe "GET /api/v1/users/:id" do
    it "returns user details" do
      get "/api/v1/users/#{user.id}", headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["id"]).to eq(user.id)
      expect(json["email"]).to eq(user.email)
    end

    it "returns 404 if user not found" do
      get "/api/v1/users/99999", headers: auth_headers

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("User not found")
    end
  end

  describe "PATCH /api/v1/users/:id" do
    it "allows a user to update their own profile" do
      patch "/api/v1/users/#{user.id}", params: { user: { name: "Updated Name" } }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["name"]).to eq("Updated Name")
    end

    it "prevents a user from updating someone else's profile" do
      another_user = users.last
      patch "/api/v1/users/#{another_user.id}", params: { user: { name: "Hacked Name" } }, headers: auth_headers

      expect(response).to have_http_status(:forbidden)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("You are not authorized to update this user")
    end
  end

  describe "DELETE /api/v1/users" do
    it "deletes the current user" do
      delete "/api/v1/users", headers: auth_headers

      expect(response).to have_http_status(:no_content)
      expect(User.exists?(user.id)).to be_falsey
    end
  end

  describe "GET /api/v1/users/profile" do
    it "returns the current user's profile" do
      get "/api/v1/users/profile", headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["id"]).to eq(user.id)
      expect(json["email"]).to eq(user.email)
    end
  end
end
