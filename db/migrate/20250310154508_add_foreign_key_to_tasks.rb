class AddForeignKeyToTasks < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :tasks, :users if foreign_key_exists?(:tasks, :users)
    add_foreign_key :tasks, :users, on_delete: :cascade
  end
end
