require 'yaml'

require './lib/redis_set_record.rb'
require './lib/person.rb'

class MemberList < RedisSetRecord

  def member_type
    Person
  end

  def valid_member?(member)
    super && 
    ((member.kind_of?(String) && member.match(/^Person:/)) || member.kind_of?(Person))
  end

  def self.rebuild()

    MemberList.new().save if MemberList.ids.size==0      
    ml = MemberList.first

    members = YAML.load(File.open("conf/members.yaml"))
    members.each do |member|
      unless Person.exists?(:email => member[:email] )
        p = Person.new()
        p.first_name = member[:first_name]
        p.last_name = member[:last_name]
        p.email = member[:email]
        p.member_number = member[:member_number]
        p.save
        ml.add(p.id)
        ml.save
      end 
         
    end

  end

end


