module Haml

module Helpers

  def erb_partial(template, *args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    options.merge!(:layout => false)
    erb(:"_#{template}", options)
  end
  
  def haml_partial(template, *args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    options.merge!(:layout => false)
    haml(:"_#{template}", options)
  end
  
  def protected!
    if !authorized?
      response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
      throw(:halt, [401, {'status_message' => 'Not authorized'}.to_json])
    end
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && 
    @auth.basic? && 
    @auth.credentials &&
    @auth.credentials[0]!='' &&
    @auth.credentials[1]!='' &&
    Person.exists?(:uuid => @auth.credentials[0]) &&    
    Person.exists?(:api_key => @auth.credentials[1]) &&
    Person.new(:uuid => @auth.credentials[0]).load.api_key == @auth.credentials[1]
  end
    
  def validate(params, required_params=[], optional_params=[], cleared_params=[])
    params.symbolize_keys!
    required_params.each do |rp|
      return [false, "#{rp} not provided"] unless params.include?(rp)
    end
    clean_params = {}
    ((required_params | optional_params) & params.keys).each do |p|    
      return [false, "String format required for #{p}"] unless params[p].kind_of? String
      clean_params[p] = cleared_params.include?(p)?params[p]:Sanitize.clean(params[p])
    end    
    return [true, "Clean", clean_params]
  end  

  def display_price(cents)
    if cents>=0
      sprintf("$%.2f",cents/100.0)
    else
      sprintf("-$%.2f",-cents/100.0)    
    end        
  end

  def display_time(s)
    m, seconds = s.to_i.divmod(60)      
    h, minutes = m.divmod(60)
    days, hours = h.divmod(24)
    time = ""
    time+= "1 day" if days==1
    time+= "#{days} days" if days>1
    time+= ", " if days>0    
    time+= "1 hour" if hours==1
    time+= "#{hours} hours" if hours>1
    time+= ", " if hours>0 || days>0    
    time+= "1 minute " if minutes==1
    time+= "#{minutes} minutes " if minutes>1
  end
  
  def realize(id)
    model_name = id.scan(/^(.*?):id:/).first.first
    model = Object.const_get(model_name)
    model.new(id: id).load
  end

  def model_link(id)
    reference = realize(id)
    if reference
      "<a href=\"/admin/inspect/#{id.to_s.gsub(/:id:/,'/')}\">#{reference.identifier}</a>"
    else
      "Unknown #{id}"
    end     
  end

end
end
