require './lib/redis_set_record.rb'

class AttendeeList < RedisSetRecord

  def member_type
    Person
  end

  def valid_member?(member)
    super && 
    ((member.kind_of?(String) && member.match(/^Person:/)) || member.kind_of?(Person))
  end

end