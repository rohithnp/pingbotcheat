class CreateChallenges < ActiveRecord::Migration
  def change
    create_table :challenges do |t|
      t.integer :from_id
      t.integer :to_id
      t.integer :status

      t.timestamps null: false
    end
  end
end
