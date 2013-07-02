require './lib/redis_set_record.rb'

class BanList < RedisSetRecord

  def member_type
    Person
  end

  def valid_member?(member)
    super && 
    ((member.kind_of?(String) && member.match(/^Person:/)) || member.kind_of?(Person))
  end

  def banned?(person)
    members.each do |banned|
      return true if person=~banned
    end
    false
  end

  def self.rebuild()

    BanList.new().save if BanList.ids.size==0      
    bl = BanList.first

    jerks = YAML.load(File.open("conf/jerks.yaml"))
    jerks.each do |jerk|
      unless Person.exists?(:email => jerk[:email] )
        p = Person.new()
        p.set(jerk)
        p.save
        bl.add(p.id)
        bl.save
      end
    end

  end


end