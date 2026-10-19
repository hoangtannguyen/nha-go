class CreateSubscribers < ActiveRecord::Migration[8.1]
  def change
    create_table :subscribers do |t|
      t.string :email, null: false
      t.string :name
      t.string :phone
      t.string :unsubscribe_token, null: false
      t.boolean :active, null: false, default: true
      t.datetime :subscribed_at, null: false
      t.datetime :unsubscribed_at
      t.datetime :last_emailed_at
      t.integer :emails_sent_count, null: false, default: 0

      t.timestamps
    end

    add_index :subscribers, :email, unique: true
    add_index :subscribers, :unsubscribe_token, unique: true
    add_index :subscribers, :active
  end
end
