class ReplaceCompensationPlanComponentsWithEmployeeCompensation < ActiveRecord::Migration[8.1]
  def change
    remove_reference :employment_contracts, :compensation_plan, null: false, foreign_key: true

    create_table :employee_compensations do |t|
      t.references :employment_contract, null: false, foreign_key: true, index: { unique: true }
      t.references :compensation_plan, null: false, foreign_key: true

      t.timestamps
    end

    create_table :employee_compensation_components do |t|
      t.references :employee_compensation, null: false, foreign_key: true
      t.references :salary_component, null: false, foreign_key: true
      t.decimal :amount, precision: 16, scale: 4, null: false

      t.timestamps

      t.index %i[employee_compensation_id salary_component_id],
        unique: true,
        name: "index_employee_comp_components_on_compensation_and_salary"
    end

    drop_table :compensation_plan_components do |t|
      t.references :compensation_plan, null: false, foreign_key: true
      t.references :salary_component, null: false, foreign_key: true
      t.decimal :amount, precision: 16, scale: 4, null: false

      t.index %i[compensation_plan_id salary_component_id],
        unique: true,
        name: "index_compensation_plan_components_on_plan_and_component"
    end
  end
end
