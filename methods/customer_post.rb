post '/api/v1/customer' do
  protected!
  content_type :json
  response = { request_url: request.path_info, request_method: request.request_method }
  required_params = [:email]
  success, response[:status_message], cparams = validate(params, required_params)
  return [400, response.to_json] unless success    

  customer = Customer.new()
  customer.email = cparams[:email]

  if !customer.save
    response[:status_message] = "Unable to complete request"
    return [500, response.to_json]     
  end 

  response[:id] = customer.uuid
  response[:status_message] = "New customer successfully generated" 
  [200, response.to_json]
end