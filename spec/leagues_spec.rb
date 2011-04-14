require File.join(File.dirname(__FILE__),'spec_helper')
describe "the league system" do
  let(:league) { Factory(:league) }
  let(:entries) { (1..24).map {|points|
    Entry.new :entrant => User.new, :points => points
  }}
  let(:league_with_group) do
    Factory(:league, :groups => [Factory(:group, :entries => [Factory(:entry)])])
  end

  describe "all versioned classes" do
    [:entry,:group,:league].each_cons(2) do |type,rel|
      before :each do
        @ins = Factory(type)
        @ins.finalise rel => Factory(rel)
      end
      it "old version access new version" do
        @ins.next_version.id.should_not be_nil
        @ins.next_version.id.should_not == @ins.id
      end
      it "new version access previous version" do
        @ins.next_version.previous_version.should == @ins
      end
    end
  end
  it "passes finalisation down the structure" do
    league_with_group.judge
    group = league_with_group.groups.first
    group.next_version.league.should == league_with_group.next_version
    group.next_version.league.should_not == league_with_group
  end
  describe "groups" do
    it "has appropriate next version vars" do
      group = Group.create :tier => 0, :league => league
      group.finalise :league => league_with_group
      group.league_id.should == league.id
    end
  end
  it "maintains association between initial versions" do
    first = league_with_group.groups.first
    league_with_group.judge
    League.find(league_with_group.id).groups.first.should == first
  end
  it "stores end date of finished leagues" do
    Timecop.freeze(Time.parse('01/01/2011')) do
      league.ended_at.should be_nil
      league.finalise
      league.ended_at.should == Time.parse('01/01/2011')
    end
  end
  it "cacluates demotions required to fill promotions" do
    league.demotions.should == 2 * TEST_PROMOTIONS
  end
  it "fills a league system with each tier having 2^n groups" do
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
    # one promotion per group
    # top group will therefore lose two players, and get two promotions
    judged = league.next_version
    by_delta = judged.tiers[0].map(&:entries).flatten(1).group_by(&:delta)
    by_delta[Entry::PROMOTION].length.should == 2
  end
  def entry points, name = 'default'
    Factory :entry, :points => points, :entrant => User.new(:name => name)
  end
  describe "group" do
    it "has accessor for demotions and promotions" do
      group = Factory :group, :tier => 0, :entries => [
        demote_one = entry(3, "demote me"),
        demote_two = entry(1, "demote me too"),
        entry(10),
        entry(5),
        entry(4),
      ]
      (group.demoting & [demote_one,demote_two]).length.should == 2
    end
  end
  describe "integration" do
    before :each do
      @league = League.create! :group_max => 5,
                               :promotions => 1,
                               :name => "Picklive Cup"
      @top_group = Group.create! :tier => 0, :league => @league, :entries => [
        entry(10),
        entry(5),
        entry(4),
        entry(3, "demote me"),
        entry(1, "demote me too")
      ]
      Group.create! :tier => 1, :league => @league, :entries => [
        entry(8, "promote me"),
        entry(4),
        entry(4),
        entry(2),
        entry(1)
      ]
      Group.create! :tier => 1, :league => @league, :entries => [
        entry(8, "promote me too"),
        entry(4),
        entry(4),
        entry(2),
        entry(1)
      ]
      @league.judge
      @league.reload
      @judged = @league.next_version
      @top = @judged.tier(0).first
      @bottom = @judged.tier(1).map {|gr| gr.entries }.flatten(1)
    end
    it "promotes applicable groups from both tiers" do
      ['promote me','promote me too'].all? do |name|
        @top.entries.any? {|entry| entry.entrant.name == name }
      end.should be_true
    end
    it "demotes enough entries from @top.tiers" do
      ['demote me','demote me too'].all? do |name|
        @bottom.any? {|entry| entry.entrant.name == name }
      end.should be_true
    end
    it "sets up promoted entries" do
      promoted = @top.entries.detect {|en| en.entrant.name == 'promote me'}
      promoted.delta.should == Entry::PROMOTION
      promoted.previous_version.group_id.should_not == promoted.group_id
    end
    it "sets up demoted entries" do
      demoted = @bottom.detect {|en| en.entrant.name == 'demote me'}
      demoted.delta.should == Entry::DEMOTION
      demoted.previous_version.group_id.should == @top_group.id
    end
    describe "finalisation" do
      it "sets pointers to previous version through whole structure" do
        [@judged.groups,
         @judged.groups.map(&:entries).flatten(1),
         [@judged]].flatten(1).each do |versioned|
          versioned.previous_version.should_not be_nil
        end
      end
      it "sets pointers to next version through whole structure" do
        [@league.groups,
         @league.groups.map(&:entries).flatten(1),
         [@league]].flatten(1).each do |versioned|
           versioned.next_version.should_not be_nil
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
end