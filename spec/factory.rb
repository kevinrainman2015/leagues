require 'factory_girl'

Factory.sequence(:group_name) {|n| "League#{n}"}

Factory.define :league do |f|
  f.name Factory.next(:group_name)
  f.promotions TEST_PROMOTIONS
  f.group_max  TEST_GROUP_MAX
end
Factory.define :group do |f|
  f.tier 0
  f.league Factory(:league)
end
Factory.define :entry do |f|
  f.entrant User.new
  f.group Factory(:group)
end
