
get '/admin/invoicing/build' do
  protected!

  Invoice.build

  redirect "/admin/inspect/Invoice"
  
end
