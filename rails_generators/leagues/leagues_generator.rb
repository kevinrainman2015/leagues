class LeaguesGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.file File.join(File.dirname(__FILE__),'..','db','migrate','initialise_leagues.rb'), File.join('db','migrate')
    end
  end
end