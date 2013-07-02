require 'rspec'
require './lib/redis_record.rb'
require 'pp'

class Item < RedisRecord

  def self.property_names
    [ 
      :prop_a, 
      :prop_b, 
      :prop_c,
      :sub_item_id 
    ]
  end

  def self.children
    [ 
      :sub_item_id
    ]
  end

  def initialize_attributes
    @ivs += Item.property_names
    @keys += [
      :prop_b
    ]        
  end

end

class SubItem < RedisRecord

  def self.property_names
    [ 
      :prop_a, 
      :prop_b, 
      :prop_c,
      :sub_item_id 
    ]
  end

  def initialize_attributes
    @ivs += SubItem.property_names
  end

end


describe "Records in Redis" do

  before :all do
    Item.flushdb
  end

  it "properties can be accessed" do
    o = Item.new
    o.prop_b = 'value_b'
    o.prop_b.should == 'value_b'
  end
  
  it "can be created" do
    o = Item.new
    o.should be_a(Item)
  end
    
  it "can be saved" do
    o = Item.new
    o.save.should be_a(Item)
  end

  it "can be loaded by id" do
    o = Item.new
    o.prop_a = 'value_a'
    o.save
    lo = Item.new(:id => o.id)
    lo.load.should == lo
    lo.prop_a.should == 'value_a'
  end

  it "can be loaded by key" do
    o = Item.new
    o.prop_a = 'value_a'
    o.prop_b = 'value_b'
    o.save
    lo = Item.new(:prop_b => 'value_b')
    lo.load.should == lo
    lo.prop_a.should == 'value_a'
  end

  it "can be searched by fields" do
    o = Item.new
    o.prop_a = 'some_value_a'
    o.prop_b = 'some_value_b'
    o.save
    los = Item.where(:prop_b => 'some_value_b')
    los.size.should == 1
    los.first.prop_a.should == 'some_value_a'
    o.delete
  end

  it "can be listed by id" do
    o = Item.new
    o.save
    o2 = Item.new
    o2.save
    Item.ids.should include o.id
    Item.ids.should include o2.id
  end

  it "can be returned in an array" do
    o = Item.new
    o.save
    o2 = Item.new
    o2.save
    items = Item.all
    items.each do |i|
      i.should be_a_kind_of Item
    end 
  end

  it "are compared on id" do
    o = Item.new.save
    o2 = Item.new(:id => o.id)
    o.should == o2
  end

  it "are exactly compared on all properties" do
    o = Item.new
    o.prop_a = 'value_a'
    o.prop_b = 'value_b'
    o.prop_c = 'value_c'
    o.save
    o2 = Item.new(:id => o.id).load
    o.should === o2
    o.prop_c = 'value_d'
    o.should_not === o2
  end

  it "can be deleted by the class" do
    o = Item.new.save
    Item.delete(:id => o.id).should == true
    Item.exists?(:id => o.id).should == false
  end

  it "can be deleted" do
    o = Item.new.save
    o.delete
    Item.exists?(:id => o.id).should == false
  end

  it "allows access to children" do
    so = SubItem.new.save
    o = Item.new(sub_item_id: so.id).save
    o.sub_item.should == so
  end

  it "also deletes children" do
    so = SubItem.new.save
    pp so
    o = Item.new(sub_item_id: so.id).save
    pp o 
    o.delete
    Item.exists?(:id => o.id).should == false
    SubItem.exists?(:id => so.id).should == false
  end

  it "cannot be loaded by key after deletion" do
    o = Item.new
    o.prop_a = 'unique_value_a'
    o.prop_b = 'unique_value_b'
    o.save
    o.delete
    lo = Item.new(:prop_b => 'unique_value_b')
    lo.id.should_not == o.id
  end


end
