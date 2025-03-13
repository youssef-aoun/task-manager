require 'rails_helper'

RSpec.describe "Authentication API", type: :request do
  let(:user) { create(:user, email: "test@example.com", password: "password123") }
  let(:headers) { { "Authorization" => "Bearer #{user_token}" } }
  let(:user_token) do
    post "/api/v1/auth/login", params: { email: user.email, password: "password123" }
    JSON.parse(response.body)["token"]
  end

  describe "POST /auth/register" do
    it "registers a new user and returns a token" do
      expect {
        post "/api/v1/auth/register", params: {
          user: { name: "John Doe", email: "newuser@example.com", password: "password123", password_confirmation: "password123", gender: "male" }
        }
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["token"]).to be_present
      expect(json["user"]["email"]).to eq("newuser@example.com")
    end

    it "fails when passwords do not match" do
      post "/api/v1/auth/register", params: {
        user: { name: "John Doe", email: "newuser@example.com", password: "password123", password_confirmation: "wrongpassword", gender: "male" }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to include("Password confirmation doesn't match Password")
    end

    it "fails when email is already taken" do
      create(:user, email: "existing@example.com")
      post "/api/v1/auth/register", params: {
        user: { name: "Jane Doe", email: "existing@example.com", password: "password123", password_confirmation: "password123", gender: "female" }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to include("Email has already been taken")
    end
  end

  describe "POST /auth/login" do
    it "logs in a user and returns a token" do
      post "/api/v1/auth/login", params: { email: user.email, password: "password123" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["token"]).to be_present
      expect(json["user"]["email"]).to eq(user.email)
    end

    it "fails to log in with incorrect password" do
      post "/api/v1/auth/login", params: { email: user.email, password: "wrongpassword" }

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("Invalid email or password")
    end

    it "fails to log in with non-existent email" do
      post "/api/v1/auth/login", params: { email: "nonexistent@example.com", password: "password123" }

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("Invalid email or password")
    end
  end

  describe "DELETE /auth/logout" do
    it "logs out the user" do
      delete "/api/v1/auth/logout", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["message"]).to eq("Successfully logged out. Please discard your token.")
    end

    it "fails to log out without a token" do
      delete "/api/v1/auth/logout"

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("Missing or invalid token")
    end
  end
end
