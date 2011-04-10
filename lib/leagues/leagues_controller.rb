module Leagues
  module LeaguesController
    def index
      @top = Leagues.tier(0).first
      @leagues = Leagues.all
    end
    def show

    end
  end
end