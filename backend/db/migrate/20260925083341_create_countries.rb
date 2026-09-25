class CreateCountries < ActiveRecord::Migration[8.1]
  def change
    # ISO 3166-1 alpha-2 is the natural key, so the table has no surrogate id.
    create_table :countries, id: false do |t|
      t.string :code, limit: 2, null: false, primary_key: true
      t.string :name, null: false
      t.string :currency, limit: 3, null: false

      t.index :name, unique: true
    end
  end
end
