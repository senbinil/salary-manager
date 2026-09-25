class CreateDepartments < ActiveRecord::Migration[8.1]
  def change
    create_table :departments do |t|
      t.string :name, null: false

      t.index :name, unique: true
    end
  end
end
