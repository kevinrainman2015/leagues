require File.join(File.dirname(__FILE__),'spec_helper')
include Picklive::Leagues
describe "the league system" do
  
  let(:league) { League.create :name => 'a league', :promotions => 4, :group_max => 2, :tier_system => 'powers_of_two'}
  let(:entries) { [1,2, 3,4,5,6, 7,8].reverse.map {|points|
    Entry.new :points => points, :entrant_class => 'meh', :entrant_id => 1
  }}

  it "creates historic copies of finished leagues" do
    league.end
    League.last.current_version.should == league
  end
  it "stores end date of finished leagues" do
    Timecop.freeze(Time.parse('01/01/2011')) do
      league.end
      League.last.ended_at.should == Time.parse('01/01/2011')
    end
  end
  it "cacluates demotions required to fill promotions" do
    league.demotions_from(0).should == 2 * 4
    league.demotions_from(1).should == 4 * 4
  end
  it "fills a league system" do
    league.fill(entries)
    league.tiers[0].length.should == 2**0
    league.tiers[1].length.should == 2**1
    league.tiers[2].length.should == 2**2
  end
  it "tiers groups" do
    tiered = league.organise_to_tiers([1,2,3,4,5,6])
    tiered[0].length.should == 1
    tiered[0][0].should == 1
    tiered[2].length.should == 3
  end
  it "demotes enough players to fulfil all promotions" do
    league.fill(entries)
    league.judge
    Entry.by_points.not_ended.first.group.tier.should == 0
    Entry.by_points.not_ended.last.group.tier.should == 2
  end
  
  class League
    def to_s
      puts "\n"
      tiers.each_index do |index|
        groups = tiers[index]
        puts "at tier #{index}\n"
        puts "  #{groups.length} groups\n"
        groups.each do |group|
        puts "    - group_id #{group.id}"
        group.entries.each do |entry|  
        puts "      - entry: points #{entry.points}"
        end
        end
      end
      nil
    end
  end
end