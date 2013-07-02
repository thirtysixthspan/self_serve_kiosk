
get '/admin/inspect/:model' do
  protected!

  model_name = params[:model]

  return "" unless $models.include?(model_name)

  @model = Object.const_get(model_name)
  @instances = @model.all

  haml :'admin/inspect', :layout => :'admin/layout'
end

