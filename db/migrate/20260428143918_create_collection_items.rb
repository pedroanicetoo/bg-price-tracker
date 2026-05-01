class CreateCollectionItems < ActiveRecord::Migration[7.1]
  def change
    create_table :collection_items do |t|
      t.references :user,    null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.datetime   :added_at, null: false, default: -> { "NOW()" }
      t.text       :notes

      t.timestamps
    end

    add_index :collection_items, %i[user_id product_id], unique: true
  end
end
