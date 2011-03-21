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
  end
end

require File.join(root, '..', 'lib','leagues')