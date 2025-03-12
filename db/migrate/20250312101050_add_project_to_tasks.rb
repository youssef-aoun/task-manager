class AddProjectToTasks < ActiveRecord::Migration[8.0]
  def up
    add_reference :tasks, :project, foreign_key: true, null: true

    default_project = Project.first || Project.create!(name: "Default Project", user_id: User.first.id)
    Task.where(project_id: nil).update_all(project_id: default_project.id)

    change_column_null :tasks, :project_id, false
  end

  def down
    remove_reference :tasks, :project
  end
end
