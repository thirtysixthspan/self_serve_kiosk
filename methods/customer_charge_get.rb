get '/api/v1/customer/charge' do
  protected!
  content_type :json
  response = { request_url: request.path_info, request_method: request.request_method }
  required_params = [:id, :amount, :description]
  success, response[:status_message], cparams = validate(params, required_params)
  return [400, response.to_json] unless success    

  response[:charged] = false

  if !Customer.exists?(:uuid => cparams[:id])
    response[:status_message] = "Unknown ID"
    return [404, response.to_json] 
  end

  customer = Customer.new(:uuid => cparams[:id])
  if !customer.load
    response[:status_message] = "Unable to complete request"
    return [500, response.to_json]     
  end
  
  if !customer.charge_method
    response[:status_message] = "No charge method available"
    return [400, response.to_json]     
  end
   
  success, charge = customer.charge_card({:amount => cparams[:amount], :description => cparams[:description]})
  if !success
    response[:status_message] = "Unable to complete request: #{charge}"
    return [500, response.to_json]     
  end
  
  response[:charge_id] = charge.id
  response[:charged] = true  
  response[:status_message] = "Charge successfully generated" 
  [200, response.to_json]
end
