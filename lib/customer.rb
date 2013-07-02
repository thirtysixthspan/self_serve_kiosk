require './lib/redis_record.rb'

class Customer < RedisRecord

  def self.property_names
    [ 
      :cc_name, 
      :email,
      :member_id,
      :charge_method,
      :stripe_customer_id,
      :stripe_token_id
    ]
  end

  def initialize_attributes
    @ivs += Customer.property_names 
    @keys += [
      :email,
      :cc_name
    ]        
  end

  def identifier
    "#{self.cc_name} #{self.email}"
  end

  def record_stripe_charge(stripe_charge)
    stripe_charge.customer_id = id
    file_name = "#{CHARGE_PATH}/#{self.uuid}-#{stripe_charge.id}.stripe_charge"
    begin
      File.open(file_name, "w") { |f| YAML.dump(stripe_charge, f) }
      return true
    rescue Exception => e
      return [false, e.message]
    end
  end

  def charge_stripe(charge={})
    begin
      stripe_request = {
        :amount => charge[:amount],    
        :currency => 'usd',
        :customer => self.stripe_customer_id,
        :description => charge[:description]
      }
      stripe_charge = Stripe::Charge.create( stripe_request )
    rescue Exception => e
      LOG.warn "Stripe Exception #{e.message}"      
      return [false, e.message]
    end

    success, message = record_stripe_charge(stripe_charge)
    return [true, stripe_charge] if success 

    return [false, message]
  end

  def retrieve_stripe_charge(stripe_charge_id)
    begin
      stripe_charge = Stripe::Charge.retrieve( stripe_charge_id )
      return [true, stripe_charge] 
    rescue Exception => e
      LOG.warn "Stripe Exception #{e.message}"      
      return [false, e.message]
    end
  end

  def retrieve_stripe_charge_status(stripe_charge_id)
    success, charge = retrieve_stripe_charge(stripe_charge_id)
    return 'unknown' unless success
    charge.paid
  end

  def retrieve_charge_status(charge_id)
    return retrieve_stripe_charge_status(charge_id) if charge_method == 'stripe'
    [false, 'Charge method not found']
  end

  def charge_card(charge={})
    return charge_stripe(charge) if charge_method == 'stripe'
    [false, 'Charge method not found']
  end

  def create_stripe_customer()
    begin
      stripe_request = {
        :card => stripe_token_id,
        :description => cc_name,
        :email => email
      } 
      stripe_customer = Stripe::Customer.create(stripe_request)
      self.stripe_customer_id = stripe_customer.id
      self.save
      return [true, stripe_customer.id]
    rescue Exception => e
      LOG.warn "Stripe Exception #{e.message}"      
      return [false, e.message]
    end
    true
  end

  def obtain_stripe_token(card)
    begin
      stripe_request = {
        :card => {
          :number => card[:number],
          :exp_month => card[:exp_month],
          :exp_year => card[:exp_year]
        }
      } 
      stripe_request[:card][:exp_year] = (card[:exp_year].to_i + 2000).to_s if stripe_request[:card][:exp_year].to_i < 2000
      stripe_request[:card][:cvc] = card[:cvc] if card.include?(:cvc)
      stripe_request[:card][:name] = cc_name if cc_name
      stripe_request[:card][:number] = "4242424242424242" if STRIPE_MODE == 'test'

      stripe_token = Stripe::Token.create(stripe_request)
      self.stripe_token_id = stripe_token.id
      self.charge_method = 'stripe'
      self.save
      return [true, stripe_token]
    rescue Exception => e
      LOG.warn "Stripe Exception #{e.message}"
      return [false, e.message]
    end
    true
  end

  def update_stripe_customer
    begin
      stripe_customer = Stripe::Customer.retrieve(stripe_customer_id) 
      stripe_customer.card = stripe_token_id if stripe_token_id
      stripe_customer.description = cc_name if cc_name
      stripe_customer.email = email if email
      stripe_customer.save
      
      return [true, stripe_customer.id]
    rescue Exception => e
      LOG.warn "Stripe Exception #{e.message}"
      return [false, e.message]
    end
    true
  end

end






