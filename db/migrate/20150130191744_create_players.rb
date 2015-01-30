class CreatePlayers < ActiveRecord::Migration
  def change
    create_table :players do |t|
      t.string :name
      t.integer :rank
      t.integer :status
      t.datetime :last_challenge_issued
      t.integer :last_rank

      t.timestamps null: false
    end
  end
end
