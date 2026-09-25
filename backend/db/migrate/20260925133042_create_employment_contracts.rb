class CreateEmploymentContracts < ActiveRecord::Migration[8.1]
  def change
    create_table :employment_contracts do |t|
      t.references :employee, null: false, foreign_key: true
      t.string :country_code, limit: 2, null: false
      t.references :compensation_plan, null: false, foreign_key: true
      # No pay_frequency column: amounts are monthly system-wide (principle 6), so
      # a one-value column would only restate that. No default either - the model
      # copies the currency from the country (§3).
      t.string :currency, limit: 3, null: false
      t.date :start_date, null: false
      t.date :end_date

      t.index :country_code
      # §7: one active contract per employee. Named by hand, because the generated
      # name would collide with the index t.references already created.
      t.index :employee_id,
        unique: true,
        where: "end_date IS NULL",
        name: "index_employment_contracts_on_open_ended_employee"

      t.check_constraint "end_date IS NULL OR end_date > start_date",
        name: "employment_contracts_end_after_start"
    end

    # countries is keyed by its ISO code rather than an id, so this foreign key
    # needs both an explicit column and an explicit primary key.
    add_foreign_key :employment_contracts, :countries, column: :country_code, primary_key: :code
  end
end
