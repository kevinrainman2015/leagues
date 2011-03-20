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
    def fill(entries)
      filler(entries,[],0)
    end
    def filler(entries,tiers,tier_n)
      tier = tiers[tier_n] = []
      tier_groups(tier_n).times { tier << Group.create(tier_n,self) }
      # for each slice of G entries, assign to groups
      to_assign = entries.slice!(tier.length * group_max)
      tier.take_while(to_assign.empty? == false) {|group| group.entries << to_assign.unshift }
      if entries.empty?
        tiers
      else
        filler(entries,tiers,tier_n + 1)
      end
    end
    def judge
      groups.for_judging do |pair|
        higher, lower = pair
        demoting = higher.collect(&:for_demotion)
        promoting = lower.collect(&:for_promotion)
        demoting.each do |entry|
          entry.demote(lower)
        end
        promoting.each do |entry|
          entry.promote(higher)
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
    def tier_groups(n)
      self.send tier_system.tablize, n
    end
    @tier_systems = []
    class << self
      attr_accessor :tier_systems
      def tier_system :name, &:def
        define_method name, def
        tier_systems << name
      end
      def tier_systems_for_display
        tier_systems.map(&:to_s).map(&:humanize)
      end
    end
    tier_system :powers_of_two do |n|
      2**n
    end
  end
  
  class Group < ActiveRecord::Base
    has_many :entries
    belongs_to :league
    include Timeful
    timeful_dependents :entries
    def initialize(tier_n,league)
      tier = tier_n
      league = league
    end
    def for_demotion
      entries.for_demotion(league.demotions_from(tier))
    end
    def for_promotion
      tier == 0 ? [] : entries.for_promotion(league.promotions)
    end
  end
  
  class Entry < ActiveRecord::Base
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