require 'active_record'
require 'pp'

module Versioned
  def finalise for_next = {}
    next_version = self.class.create! \
      prep_next.merge(for_next)
    update_attributes :ended_at => Time.now, :next_version => next_version
    notify(:ended)
  end
  def prep_next
    Hash[next_version_attributes.map {|attr| [attr,self.send(attr)] }].merge :previous_version => self
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
  has_many :groups, :inverse_of => :league
  attr_accessible :name, :promotions, :group_max, :groups
  include Versioned
  named_scope :with_groups, {:include => :groups}
  def tier tier
    groups.select {|g| g.tier == tier }
  end
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
  def next_version_attributes
    [:promotions, :name, :group_max]
  end
  def distribute_entries(entries, groups)
    entries = entries.dup
    groups.cycle((entries.length / groups.length.to_f).ceil) do |group|
      yield entries.shift, group unless entries.empty?
    end
  end
  def judge
    # finalise the league, and then all groups
    finalise
    groups.each {|group| group.finalise :league => next_version }
    # load this version's groups, and demote/promote into next's
    tiers.each_cons(2) do |pair|
      higher, lower = pair
      demoting = higher.collect(&:demoting).flatten(1)
      promoting = lower.collect(&:promoting).flatten(1)
      distribute_entries(demoting,lower) do |entry, group|
        entry.demote(group.next_version)
      end
      distribute_entries(promoting,higher) do |entry, group|
        entry.promote(group.next_version)
      end
    end
    # all non demoted/promoted groups will remain
    groups.each do |group|
      group.entries.each do |entry|
        entry.remain(group.next_version) if entry.next_version.nil?
      end
    end
  end
  def tiers
    organise_to_tiers(groups.for_judging :order => 'tier ASC')
  end
  def organise_to_tiers(groups,tier_n = 0, tiers = [])
    tiers[tier_n] = groups.slice!(0,tier_groups(tier_n))
    groups.empty? ? tiers : organise_to_tiers(groups,tier_n + 1, tiers)
  end
  def demotions
    2 * promotions
  end
  def tier_groups(level)
    2**level
  end
end

class Group < ActiveRecord::Base
  has_many :entries, :inverse_of => :group
  belongs_to :league, :inverse_of => :groups
  include Versioned
  named_scope :for_judging, :include => [:entries, :league]
  attr_accessible :tier, :league, :entries
  delegate :demoting, :promoting, :to => :entries
  delegate :demotions, :promotions, :to => :league
  def next_version_attributes
    [:tier]
  end
end

class Entry < ActiveRecord::Base
  PROMOTION = -1
  DEMOTION = 1
  UNCHANGED = 0
  belongs_to :group, :inverse_of => :entries
  belongs_to :entrant, :polymorphic => true
  named_scope :by_points, :order => 'points DESC'
  named_scope :not_ended, :conditions => {:ended_at => nil}
  attr_accessible :points, :group, :entrant, :delta
  include Versioned
  class << self
    def demoting
      by_points[-first.group.demotions..-1]
    end
    def promoting
      by_points[0...first.group.promotions]
    end
  end
  def next_version_attributes
    [:entrant]
  end
  # entries moving up/down accross tiers
  def demote(to)
    finalise :group => to, :delta => DEMOTION, :points => 0
    notify(:demoted)
  end
  def promote(to)
    finalise :group => to, :delta => PROMOTION, :points => 0
    notify(:promoted)
  end
  def remain(to)
    finalise :group => to, :delta => UNCHANGED, :points => 0
    notify(:remained)
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

class League
  def to_s
    puts"\n"
    puts "League #{id}"
    tiers.each_index do |index|
      groups = tiers[index]
      puts "at tier #{index}\n"
      puts "  #{groups.length} groups\n"
      groups.each do |group|
      puts "    - group_id #{group.id}"
      group.entries.each do |entry|
      puts "      - entry: points #{entry.points}, delta #{entry.delta}"
      end
      end
    end
    nil
  end
end
