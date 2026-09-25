class AddRoleToAccounts < ActiveRecord::Migration[8.1]
  def change
    # Least privilege is 0, so a row that lands there by accident gets the fewest
    # powers. This default is what a self-signup actually gets: Rodauth creates
    # accounts through Sequel and never sees the model's enum default, and the
    # public create-account route goes through it.
    add_column :accounts, :role, :integer, null: false, default: 0
  end
end
