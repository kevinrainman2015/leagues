module Picklive::Leagues
  module Timeful
    belongs_to :current_version, :foreign_key => :record_for, :class => self
    @timeful_dependents = []
    def end
      historic = attributes
      attributes.delete(:id)
      record = self.class.create historic.merge(:ended_on => Time.now, :current_version => self)
      timeful_dependents {|sym| self.send(sym).send(&:end) }
      notify(:ended)
    end
    module ClassMethods
      attr_reader :timeful_dependents
      def timeful_dependents *dependents
        @timeful_dependents.concat(dependents)
      end
    end
  end
  
  class League < ActiveRecord::Base
    has_many :groups
    attr_reader :promotions, :group_max, :groups
    include Timeful
    timeful_dependents :groups
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
      tier.take_while(to_assign.empty? == false) {|group| group.participants << to_assign.unshift }
      if participants.empty?
        tiers
      else
        fill(participants,tiers,tier_n + 1)
      end
    end
    def judge
      groups.for_judging do |pair|
        higher, lower = pair
        demoting = higher.collect(&:for_demotion)
        promoting = lower.collect(&:for_promotion)
        demoting.each do |participant|
          participant.demote(lower)
        end
        promoting.each do |participant|
          participant.promote(higher)
        end
      end
      groups.each(&:end)
    end
    def tiers
      @tiers ||= []
    end
    def demotions_from(tier)
      tier_groups(tier - 1) * promotions
    end
  end
  
  class Group < ActiveRecord::Base
    has_many :participants
    belongs_to :league
    include Timeful
    timeful_dependents :participants
    def initialize(tier_n,league)
      tier = tier_n
      league = league
    end
    def for_demotion
      participants.for_demotion(league.demotions_from(tier))
    end
    def for_promotion
      tier == 0 ? [] : participants.for_promotion(league.promotions)
    end
  end
  
  class Participant < ActiveRecord::Base
    belongs_to :group
    belongs_to :entrant, :polymorphic => true
    include Timeful
    def demote(to)
      notify(:demoted,group,to)
      group = to
      save
    end
    def promote(to)
      notify(:promoted,group,to)
      group = to
      save
    end
  end
end