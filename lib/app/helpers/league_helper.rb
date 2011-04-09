module LeagueHelper
  def format_tier_delta delta
    delta == 0 ? '' : "<span class='up'>#{delta == 1 ? '-1' : '+1'}</span>"
  end
end