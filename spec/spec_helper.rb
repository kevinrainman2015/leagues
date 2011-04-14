require 'rubygems'
require 'bundler'
Bundler.setup
require 'active_record'
require 'timecop'

root = File.dirname(__FILE__)
ActiveRecord::Base.establish_connection(YAML.load_file(File.join(root,'database.yml'))['sqlite3'])
require File.join(root, '..','lib','db','migrate','initialise_leagues.rb')
InitialiseLeagues.up

ActiveRecord::Schema.define do
  create_table :users do |t|
    t.string :name
  end
end

TEST_PROMOTIONS = 1
TEST_GROUP_MAX  = 4

require 'logger'
ActiveRecord::Base.logger = Logger.new(STDERR)

require File.join(root, '..', 'lib','leagues')

class User < ActiveRecord::Base
  include Entrant
  has_many :entries, :as => :entrant
end

require 'factory'