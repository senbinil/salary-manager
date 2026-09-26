# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_26_131830) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"

  create_table "account_login_change_keys", force: :cascade do |t|
    t.datetime "deadline", null: false
    t.string "key", null: false
    t.string "login", null: false
  end

  create_table "account_password_reset_keys", force: :cascade do |t|
    t.datetime "deadline", null: false
    t.datetime "email_last_sent", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "key", null: false
  end

  create_table "account_remember_keys", force: :cascade do |t|
    t.datetime "deadline", null: false
    t.string "key", null: false
  end

  create_table "account_verification_keys", force: :cascade do |t|
    t.datetime "email_last_sent", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "key", null: false
    t.datetime "requested_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "accounts", force: :cascade do |t|
    t.citext "email", null: false
    t.string "password_hash"
    t.integer "role", default: 0, null: false
    t.integer "status", default: 1, null: false
    t.index ["email"], name: "index_accounts_on_email", unique: true, where: "(status = ANY (ARRAY[1, 2]))"
    t.check_constraint "email ~ '^[^,;@ \r\n]+@[^,@; \r\n]+.[^,@; \r\n]+$'::citext", name: "valid_email"
  end

  create_table "compensation_plans", force: :cascade do |t|
    t.string "name", null: false
    t.index ["name"], name: "index_compensation_plans_on_name", unique: true
  end

  create_table "countries", primary_key: "code", id: { type: :string, limit: 2 }, force: :cascade do |t|
    t.string "currency", limit: 3, null: false
    t.string "name", null: false
    t.index ["name"], name: "index_countries_on_name", unique: true
  end

  create_table "departments", force: :cascade do |t|
    t.string "name", null: false
    t.index ["name"], name: "index_departments_on_name", unique: true
  end

  create_table "designations", force: :cascade do |t|
    t.string "name", null: false
    t.index ["name"], name: "index_designations_on_name", unique: true
  end

  create_table "employee_compensation_components", force: :cascade do |t|
    t.decimal "amount", precision: 16, scale: 4, null: false
    t.datetime "created_at", null: false
    t.bigint "employee_compensation_id", null: false
    t.bigint "salary_component_id", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_compensation_id", "salary_component_id"], name: "index_employee_comp_components_on_compensation_and_salary", unique: true
    t.index ["employee_compensation_id"], name: "idx_on_employee_compensation_id_8bf1e0a910"
    t.index ["salary_component_id"], name: "index_employee_compensation_components_on_salary_component_id"
  end

  create_table "employee_compensations", force: :cascade do |t|
    t.bigint "compensation_plan_id", null: false
    t.datetime "created_at", null: false
    t.bigint "employment_contract_id", null: false
    t.datetime "updated_at", null: false
    t.index ["compensation_plan_id"], name: "index_employee_compensations_on_compensation_plan_id"
    t.index ["employment_contract_id"], name: "index_employee_compensations_on_employment_contract_id", unique: true
  end

  create_table "employees", force: :cascade do |t|
    t.bigint "department_id", null: false
    t.bigint "designation_id", null: false
    t.string "name", null: false
    t.bigint "user_id"
    t.index ["department_id"], name: "index_employees_on_department_id"
    t.index ["designation_id"], name: "index_employees_on_designation_id"
    t.index ["user_id"], name: "index_employees_on_user_id", unique: true
  end

  create_table "employment_contracts", force: :cascade do |t|
    t.string "country_code", limit: 2, null: false
    t.string "currency", limit: 3, null: false
    t.bigint "employee_id", null: false
    t.date "end_date"
    t.date "start_date", null: false
    t.index ["country_code"], name: "index_employment_contracts_on_country_code"
    t.index ["employee_id"], name: "index_employment_contracts_on_employee_id"
    t.index ["employee_id"], name: "index_employment_contracts_on_open_ended_employee", unique: true, where: "(end_date IS NULL)"
    t.check_constraint "end_date IS NULL OR end_date > start_date", name: "employment_contracts_end_after_start"
  end

  create_table "salary_components", force: :cascade do |t|
    t.integer "category", null: false
    t.string "name", null: false
    t.index ["name"], name: "index_salary_components_on_name", unique: true
  end

  add_foreign_key "account_login_change_keys", "accounts", column: "id"
  add_foreign_key "account_password_reset_keys", "accounts", column: "id"
  add_foreign_key "account_remember_keys", "accounts", column: "id"
  add_foreign_key "account_verification_keys", "accounts", column: "id"
  add_foreign_key "employee_compensation_components", "employee_compensations"
  add_foreign_key "employee_compensation_components", "salary_components"
  add_foreign_key "employee_compensations", "compensation_plans"
  add_foreign_key "employee_compensations", "employment_contracts"
  add_foreign_key "employees", "accounts", column: "user_id"
  add_foreign_key "employees", "departments"
  add_foreign_key "employees", "designations"
  add_foreign_key "employment_contracts", "countries", column: "country_code", primary_key: "code"
  add_foreign_key "employment_contracts", "employees"
end
