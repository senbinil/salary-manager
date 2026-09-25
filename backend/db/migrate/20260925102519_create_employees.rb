class CreateEmployees < ActiveRecord::Migration[8.1]
  def change
    create_table :employees do |t|
      # Optional and unique: an employee may have no account at all, and an
      # account backs at most one employee. Postgres allows many NULLs under a
      # unique index, so the nullable case still works.
      t.references :user, foreign_key: { to_table: :accounts }, index: { unique: true }
      t.string :name, null: false
      t.references :department, null: false, foreign_key: true
      t.references :designation, null: false, foreign_key: true
    end
  end
end
