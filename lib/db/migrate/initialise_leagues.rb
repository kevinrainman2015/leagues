class InitialiseLeagues < ActiveRecord::Migration
  def self.up
    create_table :leagues, :force => true do |t|
      t.string :name
      t.integer :promotions
      t.integer :group_max
      t.timestamp :ended_on
      t.integer :record_for
      t.string :tier_system
      t.timestamps
    end
    create_table :groups, :force => true do |t|
      t.integer :tier
      t.integer :league_id
      t.integer :record_for
      t.timestamp :ended_on
      t.timestamps
    end
    create_table :participants, :force => true do |t|
      t.integer :points
      t.timestamp :ended_on
      t.integer :record_for
      t.timestamps
    end
  end
  def self.down
    drop_table :leagues
    drop_table :groups
    drop_table :participants
  end
end