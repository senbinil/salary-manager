class CreateCompensationPlanComponents < ActiveRecord::Migration[8.1]
  def change
    create_table :compensation_plan_components do |t|
      t.references :compensation_plan, null: false, foreign_key: true
      t.references :salary_component, null: false, foreign_key: true
      t.decimal :amount, precision: 16, scale: 4, null: false

      # D0.5: one amount per word per plan. A second row for the same pair would
      # make a plan's total depend on which row a reader happened to count. Named
      # by hand: the generated name for these two columns runs past Postgres's
      # 63-byte limit and comes out as an unreadable hash suffix.
      t.index %i[compensation_plan_id salary_component_id],
        unique: true,
        name: "index_compensation_plan_components_on_plan_and_component"
    end
  end
end
