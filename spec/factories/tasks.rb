FactoryBot.define do
  factory :task do
    title { "Test Task" }
    status { "pending" }
    project
    association :assignee, factory: :user
  end
end
