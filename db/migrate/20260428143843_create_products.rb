class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.string  :canonical_name, null: false
      t.string  :publisher
      t.string  :edition
      t.string  :language, default: "pt-BR"
      t.string  :category, null: false
      t.string  :slug, null: false
      t.string  :aliases, array: true, default: []

      t.timestamps
    end

    add_index :products, :slug, unique: true
    add_index :products, :canonical_name
    add_index :products, :category
  end
end
