class League
  attr_reader :promotions, :period, :tiers, :group_max, :group_min, :groups
  # the number of groups on tier N; override
  def tier_groups(n)
  end
  def fill
    filler(participants,[],0)
  end
  def filler(participants,tiers,tier_n)
    tier = tiers[tier_n] = []
    tier_groups(tier_n).times { tier << Group.create(tier_n,self) }
    # for each slice of G particanpts, assign to groups
    to_assign = participants.slice!(tier.length * group_max)
    groups.take_while(to_assign.empty? == false) {|group| group << to_assign.unshift }
    if participants.empty?
      tiers
    else
      fill(participants,tiers,tier_n + 1)
    end
  end
  def tiers
    @tiers ||= []
  end
end
class Tier < Array
  attr_reader :league
  def groups_with_spaces
    groups.collect {|gr| gr.length < league.group_max }
  end
  def spaces
    
  end
end
class Group < Array
  attr_accessor :id, :tier, :league
  def create(tier_n,league)
    Group.new(tier_n,league)
  end
  def initialize(tier_n,league)
    tier = tier_n
    league = league
  end
  def for_demotion
  end
  def for_promotion
  end
  def sort(a,b)
    a.points <=> b.points
  end
end
class Particpant
  attr_accessor :id, :points
end


    
  
  
  groups_required = (participants / group_max.to_f).ceil
  while(groups_required) do
    groups_added = tier(tier_n++)
    new_groups = []
    groups_added.times { new_groups << Group.new(self,tier_n) }
    groups.concat(new_groups)
    groups_required -= groups_added
  end
# add results as points
# each period, choose relegate T-1.groups * promotions from T, and accept that many promotions from each group

class FA < League
  def tier(n)
    n**2
  end
end


