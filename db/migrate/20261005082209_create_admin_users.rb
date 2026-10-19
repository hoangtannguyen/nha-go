class CreateAdminUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :admin_users do |t|
      t.string :email, null: false
      t.string :name, null: false
      t.string :password_digest, null: false
      t.boolean :active, null: false, default: true
      t.datetime :last_login_at

      t.timestamps
    end

    add_index :admin_users, :email, unique: true
  end
end
