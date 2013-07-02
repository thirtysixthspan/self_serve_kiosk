require 'redis'
require 'json'
require 'uuidtools'

class RedisSetRecord

  @@host = "127.0.0.1"
  @@port = 6379

  def self.property_names
    [ 
      :class,
      :member_type,
      :size,
      :member_ids
    ]
  end

  def self.actions
    []
  end

  def self.connected?
    defined? @@redis
  end

  def self.connect
    @@redis = Redis.new(:host => @@host, :port => @@port) unless connected?
  end

  def self.ids
    connect
    @@redis.smembers self.to_s
  end

  def self.all
    connect
    ids.map { |id| self.new(:id => id).load }
  end

  def self.first
    connect
    self.new(:id => ids.first).load
  end

  def identifier
    @id
  end

  def properties
    data = {}
    self.class.property_names.each do |name|
      data[name] = property(name)
    end
    data
  end

  def property(key)
    send(key)
  end

  def id
    @id
  end

  def size
    @members.size
  end

  def member_ids
    @members
  end

  def members
    @members.map { |member_id| Kernel.const_get(member_id[/^.*?(?=:)/]).new(:id => member_id).load }
  end

  def includes?(target)
    members.each do |member|
      return true if member==target
    end 
    false 
  end

  def valid_set?
    @id && @id != ""
  end

  def valid_member?(member)
    member &&
    ((member.kind_of?(String) && member!="") || member.respond_to?(:id))
  end

  def add_id_to_set
    @@redis.sadd self.class, id
  end

  def remove_id_from_set
    @@redis.srem self.class, id
  end

  def save
    return nil unless valid_set?
    RedisSetRecord.connect
    members = @@redis.smembers(@id)
    (members - @members).each { |member| response = @@redis.srem @id, member}
    (@members - members).each { |member| response = @@redis.sadd @id, member}
    add_id_to_set
    self
  end
  
  def load
    return nil unless valid_set?
    RedisSetRecord.connect
    @members = @@redis.smembers(@id)
    self
  end

  def add(member)
    return nil unless valid_member?(member)
    @members << member if member.kind_of? String
    @members << member.id if member.respond_to? :id    
    self
  end

  def remove(member)
    return nil unless valid_member?(member)
    @members.delete(member) if member.kind_of? String
    @members.delete(member.id) if member.respond_to? :id
    self
  end

  def delete
    return nil unless valid_set?
    RedisSetRecord.connect
    @@redis.del @id

    remove_id_from_set

    self
  end
  
  def initialize(data = {})
    @id = data[:id] || "#{self.class}:id:#{UUIDTools::UUID.random_create.to_s}"
    @members = []
    data[:members].each { |member| add(member)} if data.include?(:members)
  end
  
end
