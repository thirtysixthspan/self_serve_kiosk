require 'redis'
require 'json'
require 'uuidtools'
require 'active_support/core_ext/hash'

class RedisRecord

  @@host = "127.0.0.1"
  @@port = 6379

  def self.property_names
    []
  end

  def self.children
    []
  end

  def self.actions
    [:edit, :delete]
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

  def self.uuids
    ids.map { |id| id.gsub(/^.*:/,'') }
  end

  def self.all
    connect
    ids.map { |id| self.new(:id => id).load }
  end

  def self.where(conditions)
    self.all.select do |r|
      conditions.map{ |k,v| r.property(k) == v }.inject(:&)
    end  
  end

  def self.reset
    self.all.each { |r| r.delete }
  end

  def self.flushdb
    connect
    @@redis.flushdb
  end

  def self.id_from_key(key,value)
    RedisRecord.connect
    @@redis.get "#{self.to_s}:#{key}:#{value}"
  end

  def self.id_exists?(value)
    ids.include? value
  end

  def self.uuid_exists?(value)
    uuids.include? value
  end

  def self.exists?(data = {})
    connect
    return true if data[:id] && id_exists?(data[:id])
    return true if data[:uuid] && uuid_exists?(data[:uuid])
    data.each do |k,v|
      return true if id_from_key(k,v) 
    end
    false
  end

  def self.delete(data = {})
    connect
    if data[:id] && exists?(:id => data[:id])
        return self.new(:id => data[:id]).load.delete
    end    
    if data[:uuid] && exists?(:uuid => data[:uuid])
        return self.new(:uuid => data[:uuid]).load.delete
    end    
    data.each do |k,v|
      id = id_from_key(k,v)
      return self.new(:id => id).load.delete if id
    end
    false
  end

  def identifier
    self.id
  end

  def ==(target) 
    target.id == self.id
  end

  def ===(target) 
    comparable_properties = (@ivs-[:id]-[:keys])
    return true if comparable_properties.size == 0
    comparable_properties.map { |iv| self.properties[iv] == target.properties[iv]}.inject(:&)
  end

  def redis_id
    @data[:id]
  end

  def uuid
    @data[:id].gsub(/^.*:/,'')
  end

  def uuid=(value)
    @data[:id] = "#{self.class}:id:#{value}"
  end
 
  def valid?
    @data.include?(:id) && @data[:id] != ""
  end

  def delete_keys
    @data[:keys].each { |key| @@redis.del key }
    @data[:keys] = []
  end

  def regenerate_keys
    @keys.each do |k|
      next unless @data.include?(k)
      key_string = "#{self.class}:#{k}:#{@data[k]}"
      response = @@redis.set key_string, redis_id
      return false unless response == "OK"
      @data[:keys] << key_string      
    end
  end

  def properties
    @data.except(:id, :keys)
  end

  def property(key)
    @data.except(:id, :keys)[key]
  end

  def to_json
    properties.to_json
  end

  def save_to_redis
    @@redis.set redis_id, @data.to_json    
  end

  def add_id_to_set
    @@redis.sadd self.class, redis_id
  end

  def remove_id_from_set
    @@redis.srem self.class, redis_id
  end

  def save
    return nil unless valid?
    RedisRecord.connect
    delete_keys
    regenerate_keys
    response = save_to_redis
    return nil unless response == "OK"
    add_id_to_set
    self
  end
  
  def set(data)
    count = 0
    data.each do |k,v|
      if @ivs.include?(k.to_sym)
        @data[k.to_sym]=v 
        count+=1
      end
    end
    count > 0
  end

  def unset(keys)
    @data.except!(keys)
  end

  def load
    return false unless valid?
    RedisRecord.connect
    json_data = @@redis.get(redis_id)
    if json_data
      data = JSON.parse(json_data, :symbolize_names=>true)  
      set(data)
      self
    else
      nil
    end
  end

  def realize(id)
    model_name = id.scan(/^(.*?):id:/).first.first
    model = Object.const_get(model_name)
    model.new(id: id).load
  end

  def delete_children
    self.class.children.each do |child|
      child_id = property(child)
      realize(child_id).delete if child_id
    end
  end  

  def delete
    return false unless valid?

    delete_children

    RedisRecord.connect
    @@redis.del redis_id

    delete_keys

    remove_id_from_set
    true
  end
  
  def initialize_attributes
  end

  def setup_attributes
    initialize_attributes
    @ivs.each do |iv|
      define_singleton_method "#{iv}", lambda { @data[iv] }
      define_singleton_method "#{iv}=", lambda { |v| @data[iv] = v }
    end
    true
  end

  def id_from_key(key,value)
    RedisRecord.connect
    @@redis.get "#{self.class}:#{key}:#{value}"
  end

  def initialize(data = {})
    @keys = []
    @ivs = [
      :id, 
      :keys
    ]
    @data = { 
      :id => "#{self.class}:id:#{UUIDTools::UUID.random_create.to_s}",
      :keys => []
    }
    setup_attributes
    set(data)
    @data[:id] = "#{self.class}:id:#{data[:uuid]}" if data.include?(:uuid)
    @keys.select{ |k| data.include?(k) }.each do |k|
      id = id_from_key(k,data[k])
      @data[:id] = id if id
    end     
  end
  
  def method_missing(meth, *args, &block)
    model_id = "#{meth.to_s}_id".to_sym
    if self.class.property_names.include?(model_id)
      model = Object.const_get(meth.to_s.gsub!(/(^|_)(\w)/) { |l| l.gsub(/_/,'').upcase })
      if model
        model.new(id: property(model_id)).load
      end
    else
      super
    end
  end  

end
