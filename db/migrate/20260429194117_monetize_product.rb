class MonetizeProduct < ActiveRecord::Migration[7.1]
  def change
    change_table :products do |t|
      t.monetize :price
      t.monetize :estimated_price
      t.datetime :current_price_updated_at
    end
  end
end
