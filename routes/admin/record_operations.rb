
get '/admin/inspect/:model/:id' do
  protected!

  model_name = params[:model]
  model_id = params[:id]

  return "" unless $models.include?(model_name) && model_id

  @model = Object.const_get(model_name)
  @instance = @model.new(id: "#{model_name}:id:#{model_id}").load
  return "" unless @instance

  @properties = @instance.properties
  @actions = @model.actions

  haml :'admin/inspect_record', :layout => :'admin/layout'
end

post '/admin/update/:model/:id' do
  protected!

  model_name = params[:model]
  model_id = params[:id]
  properties = params[model_name]
  properties.select!{ |k,v| v!=''}

  return "" unless $models.include?(model_name) && model_id

  @model = Object.const_get(model_name)
  @instance = @model.new(id: "#{model_name}:id:#{model_id}").load
  return "" unless @instance

  @instance.set(properties)
  @instance.save

  redirect "/admin/inspect/#{@model}/#{model_id}"
end

get '/admin/edit/:model/:id' do
  protected!

  model_name = params[:model]
  model_id = params[:id]

  return "" unless $models.include?(model_name) && model_id

  @model = Object.const_get(model_name)
  @instance = @model.new(id: "#{model_name}:id:#{model_id}").load
  return "" unless @instance

  @properties = @instance.properties
  @actions = @model.actions

  haml :'admin/edit_record', :layout => :'admin/layout'
end

get '/admin/create/:model' do
  protected!

  model_name = params[:model]

  return "" unless $models.include?(model_name)

  @model = Object.const_get(model_name)
  @instance = @model.new().save
  return "" unless @instance

  @properties = @instance.properties
  @actions = @model.actions

  haml :'admin/edit_record', :layout => :'admin/layout'
end

get '/admin/show/:model/:id' do
  protected!

  action = :show
  model_name = params[:model]
  model_id = params[:id]
  return "" unless $models.include?(model_name) && model_id

  @model = Object.const_get(model_name)

  @instance = @model.new(id: "#{model_name}:id:#{model_id}").load
  return "" unless @instance

  return @instance.show
end

get '/admin/:action/:model/all' do
  protected!

  action = params[:action].to_sym
  model_name = params[:model]
  return "" unless $models.include?(model_name)

  @model = Object.const_get(model_name)
  return "" unless @model.actions.include?(action)

  @model.all.each do |instance|
    instance.send(action)
  end

  redirect "/admin"
end

get '/admin/:action/:model/:id' do
  protected!

  action = params[:action].to_sym
  model_name = params[:model]
  model_id = params[:id]
  return "" unless $models.include?(model_name) && model_id

  @model = Object.const_get(model_name)
  return "" unless @model.actions.include?(action)

  @instance = @model.new(id: "#{model_name}:id:#{model_id}").load
  return "" unless @instance

  success = @instance.send(action)
  if success
    redirect "/admin/inspect/#{@model}"
  else
    raise 'error 500 page exception'
  end  
end
