# desc "Explaining what the task does"
# task :leagues do
#   # Task goes here
# end
namespace :leagues do
  task :judge_all do
    League.find_each(&:judge)
  end
  task :install do
    Dir.glob(File.join(File.dirname(__FILE__), "..", "db", "migrate", "*")).each do |file|
      require file
    end
  end
end