
describe "the league system" do
  
  class FA < League
    def tier(n)
      n**2
    end
  end
  
  
end