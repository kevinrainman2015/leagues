class InitialiseLeagues < ActiveRecord::Migration
  def self.up
    create_table :leagues, :force => true do |t|
      t.string :name, :null => false
      t.integer :promotions, :null => false
      t.integer :group_max, :null => false
      t.timestamp :ended_at
      t.integer :current_version_id
      t.string :tier_system, :null => false
      t.timestamps
    end
    create_table :groups, :force => true do |t|
      t.integer :tier, :null => false
      t.integer :league_id, :null => false
      t.integer :record_for
      t.timestamp :current_version_id
      t.timestamps
    end
    create_table :entries, :force => true do |t|
      t.integer :points, :null => false
      t.integer :group_id
      t.string :entrant_class, :null => false
      t.integer :entrant_id, :null => false
      t.timestamp :ended_on
      t.integer :current_version_id
      t.timestamps
    end
  end
  def self.down
    drop_table :leagues
    drop_table :groups
    drop_table :entries
  end
end