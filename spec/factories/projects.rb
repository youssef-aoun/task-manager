FactoryBot.define do
  factory :project do
    name { "Test Project" }
    association :owner, factory: :user # ✅ Use `owner`, not `user`
  end
end
