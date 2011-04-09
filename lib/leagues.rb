require 'active_record'
module Picklive
  module Leagues

    # deltas for promotion/demotion
    PROMOTION = -1
    DEMOTION = 1

    module Versioned
      def finalise next_version_attr = {}
        next_version = self.class.create next_version_attributes.merge(next_version_attributes)
        update_attributes :ended_at => Time.now, :next_version => next_version
        notify(:ended)
      end
      def next_version_attributes
        Hash[self.class.attr_accessible.map {|attrib| [attrib,self.send(attrib)] }].merge :previous_version => self
      end
      def current?
        next_version.nil?
      end
      def oldest?
        previous_version.nil?
      end
      class << self
        def included(into)
          into.belongs_to :next_version, :foreign_key => :next_version_id, :class_name => into.to_s
          into.belongs_to :previous_version, :foreign_key => :previous_version_id, :class_name => into.to_s
          into.attr_accessible :next_version, :previous_version, :ended_at
          class << into
            def current_version
              find :conditions => {:ended_at => nil}
            end
          end
        end
      end
    end

    class League < ActiveRecord::Base

      has_many :groups
      attr_accessible :name, :promotions, :group_max, :tier_system
      include Versioned
      named_scope :tier, lambda {|tier| Group.all :tier => tier}
      def fill(entries,tiers = [],tier_n = 0)
        tier = tiers[tier_n] = []
        tier_groups(tier_n).times { tier << Group.create(:tier => tier_n, :league => self) }
        # for each slice of G entries, assign to consecutive groups, to 'sprinkle' the best players fairly
        to_assign = entries.slice!(0,tier.length * group_max)
        distribute_entries(to_assign,tier) do |entry, group|
          group.entries << entry
        end
        if entries.empty?
          tiers
        else
          fill(entries,tiers,tier_n + 1)
        end
      end
      def distribute_entries(entries, groups)
        entries = entries.dup
        groups.cycle((entries.length / groups.length.to_f).ceil) do |group|
          yield entries.shift, group unless entries.empty?
        end
      end
      def judge
        tiers.each_cons(2) do |pair|
          higher, lower = pair
          demoting = higher.collect(&:for_demotion).flatten(1)
          promoting = lower.collect(&:for_promotion).flatten(1)
          distribute_entries(demoting,lower) do |entry, group|
            entry.demote(group)
          end
          distribute_entries(promoting,higher) do |entry, group|
            entry.promote(group)
          end
        end
        groups.each(&:finalise)
      end
      def tiers
        organise_to_tiers(groups.for_judging :order => 'tier ASC')
      end
      def organise_to_tiers(groups,tier_n = 0, tiers = [])
        tiers[tier_n] = groups.slice!(0,tier_groups(tier_n))
        groups.empty? ? tiers : organise_to_tiers(groups,tier_n + 1, tiers)
      end
      def demotions_from(tier)
        tier_groups(tier + 1) * promotions
      end
      def tier_groups(level)
        2**level
      end
    end

    class Group < ActiveRecord::Base
      has_many :entries
      belongs_to :league
      include Versioned
      named_scope :for_judging, :include => [:entries, :league]
      attr_accessible :tier, :league
      def for_demotion
        entries.for_demotion(league.demotions(league.promotions))
      end
      def for_promotion
        tier == 0 ? [] : entries.for_promotion(league.promotions)
      end
    end

    class Entry < ActiveRecord::Base
      belongs_to :group
      belongs_to :entrant, :polymorphic => true
      named_scope :for_demotion, lambda {|num| {:order => 'points ASC', :limit => num }}
      named_scope :for_promotion, lambda {|num| {:order => 'points ASC', :limit => num }}
      named_scope :by_points, :order => 'points DESC'
      named_scope :not_ended, :conditions => {:ended_at => nil}
      attr_accessible :points, :group, :entrant
      include Versioned
      def demote(to)
        finalise :group => to, :delta => DEMOTION
        notify(:demoted)
      end
      def promote(to)
        finalise :group => to, :delta => PROMOTION
        notify(:promoted)
      end
    end

    # mixin for entrant classes
    module Entrant
      class << self
        def included(into)
          into.instance_eval do
            has_many :entries, :as => :entrant
            has_many :groups, :through => :entrant
            has_many :leagues, :through => :groups
          end
        end
      end
    end
  end
end