require 'active_record'
module Picklive
  module Leagues
    module Timeful
      def end
        historic = {
          :name => name,
          :promotions => promotions,
          :group_max => group_max,
          :tier_system => tier_system
        }
        record = self.class.create(historic)
        record.ended_at = Time.now
        record.current_version = self
        record.save
        self.class._timeful_dependents {|sym| self.send(sym).send(&:end) }
        notify(:ended)
      end
      class << self
        def included(into)
          into.belongs_to :current_version, :foreign_key => :current_version_id, :class_name => into.to_s
          into.extend ClassMethods
        end
      end
      module ClassMethods
        def _timeful_dependents
          @timeful_dependents ||= []
        end
        def timeful_dependents *dependents
          _timeful_dependents.concat(dependents)
        end
      end
    end
  
    class League < ActiveRecord::Base
      
      has_many :groups
      attr_accessible :name, :promotions, :group_max, :tier_system
      include Timeful
      timeful_dependents :groups
      
      def fill(entries)
        filler(entries,[],0)
      end
      def filler(entries,tiers,tier_n)
        tier = tiers[tier_n] = []
        tier_groups(tier_n).times { tier << Group.create(:tier => tier_n, :league => self) }
        # for each slice of G entries, assign to groups
        to_assign = entries.slice!(0,tier.length * group_max)
        tier.cycle((to_assign.length / tier.length.to_f).ceil) do |group| 
          group.entries << to_assign.shift unless to_assign.empty?
        end
        if entries.empty?
          tiers
        else
          filler(entries,tiers,tier_n + 1)
        end
      end
      def judge
        tiers.each_slice(2) do |pair|
          higher, lower = pair
          demoting = higher.for_demotion
          promoting = lower.for_promotion
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
        organise_to_tiers(groups.with_entries :order_by => 'tier ASC')
      end
      def organise_to_tiers(groups,tier_n = 0, tiers = [])
        tiers[tier_n] = groups.slice!(0,tier_groups(tier_n))
        groups.empty? ? tiers : organise_to_tiers(groups,tier_n + 1, tiers)
      end
      def demotions_from(tier)
        tier_groups(tier - 1) * promotions
      end
      def tier_groups(level)
        self.send tier_system.tableize.singularize, level
      end
      @tier_systems = []
      class << self
        attr_accessor :tier_systems
        def tier_system name, &definition
          define_method name, definition
          tier_systems << name.to_s
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
      named_scope :with_entries, :include => :entries
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