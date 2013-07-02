get '/api/v1/customer/list' do
  protected!
  content_type :json
  response = { request_url: request.path_info, request_method: request.request_method }

  response[:ids] = Customer.uuids()

  response[:status_message] = "IDs successfully retrieved" 
  [200, response.to_json]
end
