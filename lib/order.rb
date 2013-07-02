require 'descriptive_statistics'
require 'redis'
require 'json'
require 'yaml'
require 'uuidtools'
require 'gibberish'
require './lib/redis_record.rb'
require './lib/invoice_order_list.rb'

class Order < RedisRecord

  def self.property_names
    [ 
      :items,
      :sha512,
      :completed,
      :customer_id,
      :passphrase,
      :timestamp 
    ]
  end

  def self.not_invoiced
    order_ids = Order.ids
    InvoiceOrderList.all.each do |list|
      list.member_ids.each do |order_id|
        order_ids.delete(order_id)
      end
    end
    order_ids.map {|id| Order.new(id: id).load}
  end

  def identifier
    self.items
  end

  def initialize_attributes
    @ivs += Order.property_names 
  end
  
  def add_signature(signature)
    unset(:sha512)
    self.passphrase = signature
    self.sha512 = Gibberish::SHA512(properties.sort.to_json)
    unset(:passphrase)
    self
  end
  
  def verify_signature(signature)
    self.passphrase = signature
    test_sha512 = @data[:sha512]
    unset(:sha512)
    self.sha512 = Gibberish::SHA512(properties.sort.to_json)    
    unset(:passphrase)
    self.sha512 == test_sha512
  end

  def set_from_json(json_string)
    data = JSON.parse(json_string)
    if data
      data.symbolize_keys!
      data[:items].each { |h| h.symbolize_keys! }
      set(data)
    end
  end

  def write
    File.open("#{ORDER_PATH}/#{uuid}.order","w") { |f| YAML.dump(properties,f) }
  end
  
  def total
    return 0 if self.items.size == 0
    self.items.map{ |p| p[:price].to_i * p[:quantity].to_i  }.sum
  end

  def add(item)
    self.items.push(item)
  end

  def initialize(params={})
    super
    self.items = []
  end
    
end
