class AddColumnsToCart < ActiveRecord::Migration[7.1]
  def change
    change_table :carts, bulk: true do |t|
      t.integer :status, default: 0, null: false
      t.datetime :last_interaction_at, default: -> { 'CURRENT_TIMESTAMP' }
    end

    change_column_default :carts, :total_price, from: nil, to: 0.0
  end
end
