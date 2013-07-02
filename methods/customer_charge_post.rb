post '/api/v1/customer/charge' do
  protected!
  content_type :json
  response = { request_url: request.path_info, request_method: request.request_method }
  required_params = [:id, :charge_method]
  optional_params = [:stripe_token_id, :number, :exp_month, :exp_year, :cvc]
  success, response[:status_message], cparams = validate(params, required_params, optional_params)
  return [400, response.to_json] unless success

  response[:card_updated] = false

  charge_methods = [ 'stripe' ]

  if !charge_methods.include?(cparams[:charge_method])
    response[:status_message] = "Charge method not recognized"
    return [400, response.to_json] 
  end
  
  if !Customer.exists?(:uuid => cparams[:id])
    response[:status_message] = "Unknown ID"
    return [404, response.to_json] 
  end

  customer = Customer.new(:uuid => cparams[:id])
  if !customer.load
    response[:status_message] = "Unable to complete request"
    return [500, response.to_json]     
  end
  
  if cparams[:charge_method] == 'stripe'
    
    if cparams.include?(:stripe_token_id) 

      customer.stripe_token_id = cparams[:stripe_token_id]  

    else

      success, token = customer.obtain_stripe_token(cparams)
      if !success
        response[:status_message] = token
        return [500, response.to_json]     
      end
      customer.stripe_token_id = token.id

    end  
      
    if customer.stripe_customer_id
      
      success, stripe_customer_id = customer.update_stripe_customer 
      if !success
        response[:status_message] = stripe_customer_id
        return [500, response.to_json]     
      end
      
    else
      
      success, stripe_customer_id = customer.create_stripe_customer
      if !success
        response[:status_message] = stripe_customer_id
        return [500, response.to_json]     
      end
      
    end  
    
    updates = {
      :charge_method => 'stripe',
      :stripe_customer_id => stripe_customer_id
    }  
    customer.set(updates)

    if !customer.save
      response[:status_message] = "Unable to complete request"
      return [500, response.to_json]     
    end
          
  end
  
  response[:card_updated] = true
  response[:status_message] = "Card successfully updated" 
  [200, response.to_json]
end
