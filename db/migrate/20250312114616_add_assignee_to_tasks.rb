class AddAssigneeToTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :assignee_id, :integer
  end
end
