require 'rspec'
require './lib/redis_record.rb'
require './lib/redis_set_record.rb'

class Member < RedisRecord

  def initialize_attributes
    @ivs += [ 
      :prop_a, 
      :prop_b, 
      :prop_c 
    ]
    @keys += [
      :prop_b
    ]        
  end

end

class TestSet < RedisSetRecord

end

describe "Set Records in Redis" do
  
  before :all do
    @m1 = Member.new().save
    @m2 = Member.new().save
    @m3 = Member.new().save
    @m4 = Member.new().save

    @s = TestSet.new
    @s.add(@m1)
    @s.save
  end

  it "can be created" do
    s = TestSet.new
    s.should be_a(TestSet)
  end
    
  it "can be saved" do
    s = TestSet.new
    s.save.should == s
  end

  it "can be deleted" do
    s = TestSet.new
    s.save
    s.delete.should == s
  end

  it "can be loaded" do
    s = TestSet.new(:id => @s.id).load
    s.member_ids.should include(@m1.id)
  end

  it "can have Members added" do
    s = TestSet.new()
    s.add(@m1)
    s.add(@m2)
    s.add(@m3)
    s.save
    ns = TestSet.new(:id => s.id)
    ns.load
    ns.member_ids.should include(@m1.id)
    ns.member_ids.should include(@m2.id)
    ns.member_ids.should include(@m3.id)
  end

  it "can have Members removed" do
    s = TestSet.new()
    s.add(@m1)
    s.add(@m2)
    s.add(@m3)
    s.save
    s.remove(@m2)
    s.save
    ns = TestSet.new(:id => s.id)
    ns.load
    ns.member_ids.should include(@m1.id)
    ns.member_ids.should_not include(@m2.id)
    ns.member_ids.should include(@m3.id)
  end

  it "can have Members both added and removed" do
    s = TestSet.new()
    s.add(@m1)
    s.add(@m2)
    s.add(@m3)
    s.save
    s.remove(@m2)
    s.add(@m4)
    s.save
    ns = TestSet.new(:id => s.id)
    ns.load
    ns.member_ids.should include(@m1.id)
    ns.member_ids.should_not include(@m2.id)
    ns.member_ids.should include(@m3.id)
    ns.member_ids.should include(@m4.id)
  end

  it "will instantiate members without properties" do
    s = TestSet.new()
    s.add(@m1)
    s.add(@m2)
    s.save
    (s.members.first==@m1).should == true
    (s.members.first===@m1).should == true
    (s.members.last==@m2).should == true
    (s.members.last===@m2).should == true
  end

  it "will instantiate members with properties" do
    s = TestSet.new()
    @m1.prop_a = "test 1"
    @m1.save
    @m2.prop_a = "test 2"
    @m2.save
    s.add(@m1)
    s.add(@m2)
    s.save
    (s.members.first==@m1).should == true
    (s.members.first===@m1).should == true
    (s.members.last==@m2).should == true
    (s.members.last===@m2).should == true
  end


end