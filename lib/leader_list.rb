require './lib/redis_set_record.rb'

class LeaderList < RedisSetRecord

  def member_type
    Person
  end

  def valid_leader?(leader)
    super && 
    ((leader.kind_of?(String) && leader.match(/^Person:/)) || leader.kind_of?(Person))
  end

  def self.rebuild()

    LeaderList.new().save if LeaderList.ids.size==0      
    ll = LeaderList.first

    leaders = YAML.load(File.open("conf/leader_list.yaml"))
    leaders.each do |leader_email|
      if Person.exists?(:email => leader_email)
      	p = Person.new(:email => leader_email)
        ll.add(p.id)
        ll.save
      end 
         
    end

  end

end