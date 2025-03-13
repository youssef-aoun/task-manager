# app/api/base_api.rb
class BaseAPI < Grape::API
  prefix 'api'  # API base path: /api
  format :json  # Response format

  mount API::V1::ProjectsAPI
  mount API::V1::TasksAPI
  mount API::V1::UsersAPI

  add_swagger_documentation(
    api_version: 'v1',
    hide_documentation_path: false,
    mount_path: '/swagger_doc',
    hide_format: true
  )
end
