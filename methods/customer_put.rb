put '/api/v1/customer/:id' do
  protected!
  content_type :json
  response = { request_url: request.path_info, request_method: request.request_method }
  required_params = [:id]
  optional_params = Customer.property_names
  success, response[:status_message], cparams = validate(params, required_params, optional_params)
  return [400, response.to_json] unless success    
  
  if cparams.size <= 1
    response[:status_message] = "Missing parameters"
    return [400, response.to_json]     
  end

  if Customer.exists?(:uuid => cparams[:id])
    customer = Customer.new(:uuid => cparams[:id])
  else
    customer = Customer.new()
    customer.uuid = cparams[:id]
    customer.save
  end

  if !customer.load
    response[:status_message] = "Unable to complete request"
    return [500, response.to_json]
  end

  cparams.delete(:id)
  if !customer.set(cparams)
    response[:status_message] = "No properties set"
    return [400, response.to_json]     
  end

  if !customer.save
    response[:status_message] = "Unable to complete request"
    return [500, response.to_json]     
  end
  
  response[:customer] = customer.properties
  response[:customer][:id] = customer.uuid
  
  response[:status_message] = "Customer data successfully updated" 
  [200, response.to_json]
end