class CreateSalaryComponents < ActiveRecord::Migration[8.1]
  def change
    create_table :salary_components do |t|
      t.string :name, null: false
      t.integer :category, null: false

      t.index :name, unique: true
    end
  end
end
