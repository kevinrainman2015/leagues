
describe "the league system" do
  
  include Picklive::Leagues
  class FA < League
    table_name :leagues
    def tier(n)
      n**2
    end
  end
  class User < ActiveRecord::Base
  end
  
  
  
end