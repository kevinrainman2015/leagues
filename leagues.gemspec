require 'rubygems'

Gem::Specification.new do |gem|
  gem.name = "leagues"
  gem.version = '1'
  gem.homepage = "http://github.com/Picklive/leagues"
  gem.license = "MIT"
  gem.summary = %Q{League system}
  gem.description = %Q{League system}
  gem.email = "timr@picklive.com"
  gem.authors = ["Tim Ruffles"]

  ['rspec-rails','1.3.3',
   'activerecord','2.3.11',
   'sqlite3-ruby','1.3.2',
   'timecop','0.3.4',
   'activesupport', '2.3.11'].each_slice(2) do |which, req|
     gem.add_dependency which, req
  end
  gem.files = %w{{lib,rails,spec}/**/* Gemfile* install.rb Rakefile README.* uninstall.rb}.map {|glob| Dir.glob(glob) }.flatten
  gem.require_path = 'lib'
end