class Task < ApplicationRecord
  validates :title, presence: true, length: { minimum: 6, maximum: 100 }
  validates :status, presence: true, length: { maximum: 20 }

  belongs_to :assignee, class_name: 'User', optional: true
  belongs_to :project

  scope :by_status, ->(status) { where(status: status) }
  scope :with_user, -> { includes(:user) }
  scope :pending, -> { where(status: "pending") }

  # Using custom queries & Raw SQL in Rails:
  # You can search for task by writing part of it's title like follows:
  # Task.where("title ILIKE ?", "%Deploy%")


  # You can also search for pending tasks without having to write full query by just writing Task.pending
  # All of this thanks to the above scope created.
  # Advanced query: Task.where("title ILIKE ? AND status = ?", "%Deploy%", "pending")



  # To avoid N+1 queries, we can use includes, preload, or eager_load
  # Practicing includes:

  # associations(dev)> tasks = Task.all
  #   Task Load (0.7ms)  SELECT "tasks".* FROM "tasks" /* loading for pp */ LIMIT 11 /*application='Associations'*/
  # =>
  # [#<Task:0x0000023a20199c48
  # ...
  # associations(dev)* tasks.each do |task|
  # associations(dev)*   puts task.user.name
  # associations(dev)> end
  #   Task Load (0.5ms)  SELECT "tasks".* FROM "tasks" /*application='Associations'*/
  #   User Load (0.4ms)  SELECT "users".* FROM "users" WHERE "users"."id" = 1 LIMIT 1 /*application='Associations'*/
  # Youssef
  #   User Load (0.2ms)  SELECT "users".* FROM "users" WHERE "users"."id" = 1 LIMIT 1 /*application='Associations'*/
  # Youssef
  #   User Load (0.2ms)  SELECT "users".* FROM "users" WHERE "users"."id" = 1 LIMIT 1 /*application='Associations'*/
  # Youssef
  #   User Load (0.2ms)  SELECT "users".* FROM "users" WHERE "users"."id" = 1 LIMIT 1 /*application='Associations'*/
  # Youssef
  #   User Load (0.2ms)  SELECT "users".* FROM "users" WHERE "users"."id" = 1 LIMIT 1 /*application='Associations'*/
  # Youssef
  #   User Load (0.2ms)  SELECT "users".* FROM "users" WHERE "users"."id" = 1 LIMIT 1 /*application='Associations'*/
  # Youssef
  # =>
  # [#<Task:0x0000023a2019fc88
  #   id: 3,
  #   title: "Finish Rails Project",
  #   status: "in progress",
  #   created_at: "2025-03-10 15:26:04.980609000 +0000",
  #   updated_at: "2025-03-10 15:26:04.980609000 +0000",
  #   user_id: 1>,
  #  #<Task:0x0000023a2019fb48
  #   id: 4,
  #   title: "Fix authentication bug",
  #   status: "pending",
  #   created_at: "2025-03-10 15:31:06.637421000 +0000",
  #   updated_at: "2025-03-10 15:31:06.637421000 +0000",
  #   user_id: 1>,
  #  #<Task:0x0000023a2019fa08
  #   id: 5,
  #   title: "Update API documentation",
  #   status: "completed",
  #   created_at: "2025-03-10 15:31:06.641842000 +0000",
  #   updated_at: "2025-03-10 15:31:06.641842000 +0000",
  #   user_id: 1>,
  #  #<Task:0x0000023a2019f8c8
  #   id: 6,
  #   title: "Refactor Task model",
  #   status: "in progress",
  #   created_at: "2025-03-10 15:31:06.645458000 +0000",
  #   updated_at: "2025-03-10 15:31:06.645458000 +0000",
  #   user_id: 1>,
  #  #<Task:0x0000023a2019f788
  #   id: 7,
  #   title: "Deploy to production",
  #   status: "pending",
  #   created_at: "2025-03-10 15:31:06.648888000 +0000",
  #   updated_at: "2025-03-10 15:31:06.648888000 +0000",
  #   user_id: 1>,
  #  #<Task:0x0000023a2019f648
  #   id: 8,
  #   title: "Write unit tests",
  #   status: "completed",
  #   created_at: "2025-03-10 15:31:06.652743000 +0000",
  #   updated_at: "2025-03-10 15:31:06.652743000 +0000",
  #   user_id: 1>]




  # The above way, for each task, Rails runs a separate query for user
  # If you have 100 tasks, you will execute 101 queries (1 for tasks + 100 for users!). ❌ SLOW!


  # Whereas if we use includes
  # tasks = Task.includes(:user)
  # tasks.each do |task|
  #   puts task.user.name
  # end


  # SELECT * FROM tasks;
  # SELECT * FROM users WHERE id IN (1, 2, 3);
  # Only 2 queries instead.
end
