class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string   :phone,                  null: true
      t.string   :consent_status,         null: false, default: "pending"
      t.datetime :consent_at
      t.string   :consent_ip
      t.string   :privacy_policy_version, default: "1.0"
      t.datetime :anonymized_at

      t.timestamps
    end

    add_index :users, :phone, unique: true, where: "phone IS NOT NULL"
    add_index :users, :consent_status
  end
end
