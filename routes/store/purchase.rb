get '/store/welcome' do
  haml :welcome, :layout => :store  
end

get '/store/select_items' do
  @items_for_sale = ITEMS_FOR_SALE
  haml :select_items, :layout => :store  
end

post '/store/your_purchase' do
  @items_for_sale = ITEMS_FOR_SALE
  @this_order = Order.new()
  params.each do |name, quantity|
    if @items_for_sale.include?(name) && quantity.to_i > 0
      @this_order.add(:name => name,
                      :quantity => quantity,
                      :price => @items_for_sale[name][:price]) 
    end
  end
  redirect '/store/select_items' if @this_order.total==0  
  @this_order.add_signature(APP_SIGNATURE)
  
  haml :your_purchase, :layout => :store  
end

post '/store/payment' do
  redirect '/store/welcome' unless params.include? 'order_string'
  @this_order = Order.new()
  @this_order.set_from_json(params['order_string'])
  redirect '/store/welcome' unless @this_order.verify_signature(APP_SIGNATURE)
  
  haml :payment, :layout => :store  
end

post '/store/thank_you' do
  # required_params = [:email, :name, :card_token]
  # success, response[:status_message], cparams = validate(params, required_params)
  # redirect '/store/welcome' unless success

  redirect '/store/welcome' unless params.include? 'order_string'
  redirect '/store/welcome' unless params.include? 'name'
  redirect '/store/welcome' unless params.include? 'card_token'

  @order = Order.new()
  @order.set_from_json(params['order_string'])
  redirect '/store/welcome' unless @order.verify_signature(APP_SIGNATURE)

  cc = CreditCard.new({}, DEC_SECRET)

  redirect '/500' unless cc.swipe_requested?
  cc.get_from_redis
  redirect '/500' unless cc.card_token == params['card_token']
  cc.decrypt
  redirect '/500' unless cc.decrypted? &&
                         cc.name == params['name']

  if Customer.exists?(:cc_name => cc.name)
    customer = Customer.new(:cc_name => cc.name).load
  else
    customer = Customer.new()
    customer.cc_name = cc.name
    customer.email = params['email'] if params.include?('email')    
  end  

  unless customer.stripe_customer_id

    card_data = {
      :exp_year => cc.exp_year,
      :exp_month => cc.exp_month,
      :name => cc.name,
      :number => cc.number
    }

    success, message = customer.obtain_stripe_token(card_data)
    redirect '/store/payment_problem' unless success

    success, message = customer.create_stripe_customer()
    redirect '/store/payment_problem' unless success
  end

  if Person.exists?(:email => params['email'])
    person = Person.new(:email => params['email']).load
    customer.member_id = person.id if MemberList.first.includes?(person)
  end

  customer.save

  @order.customer_id = customer.id
  @order.completed = true
  @order.timestamp = Time.now.to_i
  @order.save
  @order.write  

  haml :thank_you, :layout => :store  
end


get '/store/payment_problem' do
  haml :payment_problem, :layout => :store  
end

