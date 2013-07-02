require './lib/redis_record.rb'

class Person < RedisRecord

  def self.property_names
    [ 
      :first_name, 
      :last_name, 
      :email,
      :member_number,
      :api_key,
      :admin
    ]
  end

  def initialize_attributes
    @ivs += Person.property_names 
    @keys += [
      :email,
      :member_number,
      :api_key
    ]        
  end

  def identifier
    "#{self.first_name} #{self.last_name} (#{self.email})"
  end

  def full_name
    "#{self.first_name} #{self.last_name}"
  end

  def =~(target) 
    (!target.email || self.email.downcase[target.email.downcase]) &&
    (!target.first_name || self.first_name.downcase[target.first_name.downcase]) &&
    (!target.last_name || self.last_name.downcase[target.last_name.downcase])
  end

end

