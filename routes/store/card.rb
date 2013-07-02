def authenticate_post(params,passphrase)
  if !verify_signature(params, passphrase)      
   throw(:halt, [401, {'status_message' => 'Not authorized'}.to_json]) 
  end
end

get '/store/request_card_swipe' do
  content_type :json
  response = { request_url: request.path_info, request_method: request.request_method }

  response[:card_token] = CreditCard.generate_card_token
  response[:status_message] = 'swipe request accepted'
  return [200, response.to_json]      
end

post '/store/card' do
  content_type :json
  response = { request_url: request.path_info, request_method: request.request_method }
  required_params = [:timestamp, :data, :sha512]
  optional_params = [:originator]
  cleared_params = [:data]
  success, response[:status_message], cparams = validate(params, required_params, optional_params, cleared_params)
  return [400, response.to_json] unless success    

  authenticate_post(cparams,AES_PASSPHRASE)

  cc = CreditCard.new({:encrypted => cparams[:data]}, DEC_SECRET)
  if !cc.decrypted?
    response[:status_message] = 'Error found in submitted data'
    return [400, response.to_json]      
  end

  unless cc.swipe_requested?
    response[:status_message] = 'no card swipe requested'
    return [400, response.to_json]      
  end

  cc.put_in_redis
  
  response[:status_message] = 'swipe accepted'
  return [200, response.to_json]      
end

get '/store/read_card_swipe' do
  content_type :json
  response = { request_url: request.path_info, request_method: request.request_method }
  required_params = [:card_token]
  success, response[:status_message], cparams = validate(params, required_params)
  return [400, response.to_json] unless success    

  cc = CreditCard.new({}, DEC_SECRET)

  unless cc.swipe_requested?
    response[:status_message] = 'no card swipe requested'
    return [400, response.to_json]      
  end

  cc.get_from_redis
  unless cc.card_token == cparams[:card_token]
    response[:status_message] = 'invalid card token'
    return [400, response.to_json] 
  end

  cc.decrypt
  unless cc.decrypted?
    response[:status_message] = 'no data available'
    return [200, response.to_json] 
  end

  if ((Time.now.year > (cc.exp_year.to_i + 2000)) ||  
      ((Time.now.year == (cc.exp_year.to_i + 2000)) && (Time.now.month >= cc.exp_month.to_i)))
    response[:status_message] = 'expired card'
    return [200, response.to_json] 
  end

  response[:name] = cc.name
  response[:last4] = cc.number[-4,4]

  if Customer.exists?(:cc_name => cc.name)
    customer = Customer.new(:cc_name => cc.name).load
    response[:email] = customer.email if customer.email
  end  

  response[:status_message] = 'card available'
  return [200, response.to_json]      
end 
