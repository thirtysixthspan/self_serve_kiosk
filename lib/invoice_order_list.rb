require 'yaml'

require './lib/redis_set_record.rb'
require './lib/order.rb'

class InvoiceOrderList < RedisSetRecord

  def member_type
    Order
  end

  def valid_member?(member)
    super && 
    ((member.kind_of?(String) && member.match(/^Order:/)) || member.kind_of?(Order))
  end

end


