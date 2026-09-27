class CreateExchangeRateSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :exchange_rate_snapshots do |t|
      t.date :period_month, null: false
      t.string :base_currency, limit: 3, null: false
      t.string :quote_currency, limit: 3, null: false
      t.decimal :rate, precision: 24, scale: 12, null: false
      t.date :rate_date, null: false
      t.string :source, null: false
      t.jsonb :provider_attribution, null: false, default: []

      t.timestamps
    end

    add_index :exchange_rate_snapshots,
      %i[period_month base_currency quote_currency],
      unique: true,
      name: "idx_exchange_rate_snapshots_period_pair"
    add_index :exchange_rate_snapshots, :period_month

    add_check_constraint :exchange_rate_snapshots, "rate > 0", name: "exchange_rate_snapshots_positive_rate"
    add_check_constraint :exchange_rate_snapshots,
      "base_currency <> quote_currency",
      name: "exchange_rate_snapshots_distinct_currencies"
    add_check_constraint :exchange_rate_snapshots,
      "period_month = date_trunc('month', period_month)::date",
      name: "exchange_rate_snapshots_period_month_start"
    add_check_constraint :exchange_rate_snapshots,
      "rate_date >= period_month AND rate_date < (period_month + INTERVAL '1 month')",
      name: "exchange_rate_snapshots_rate_in_period"
  end
end
