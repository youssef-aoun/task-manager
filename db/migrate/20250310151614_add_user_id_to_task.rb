class AddUserIdToTask < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :user_id, :integer
  end
end
