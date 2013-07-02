delete '/api/v1/customer/:id' do
  protected!
  content_type :json
  response = { request_url: request.path_info, request_method: request.request_method }
  required_params = [:id]
  success, response[:status_message], cparams = validate(params, required_params)
  return [400, response.to_json] unless success    
  
  response[:deleted] = false

  if !Customer.exists?(:uuid => cparams[:id] )
    response[:status_message] = "Unknown ID"
    return [404, response.to_json] 
  end

  if !Customer.delete(:uuid => cparams[:id] )
    response[:status_message] = "Unable to complete request"
    return [500, response.to_json]     
  end 
  
  response[:deleted] = true
  response[:status_message] = "ID successfully removed" 
  [200, response.to_json]
end