
get '/admin' do
  protected!

  haml :'admin/panel', :layout => :'admin/layout'
end

