# desc "Explaining what the task does"
# task :leagues do
#   # Task goes here
# end
namespace :leagues do
  task :judge_all do
    League.find_each(&:judge)
  end
  task :install do
    ActiveRecord::Migrator.migrate (File.join(File.dirname(__FILE__), '..','db','migrate','initialise_leagues.rb' )
  end
end