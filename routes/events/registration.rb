
get %r{/events/registration/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})} do
  @event = Event.new(:id => "Event:id:#{params[:captures].first}").load
  redirect_to '/events/calendar' unless @event

  haml :registration, :layout => :events  
end

post '/events/registration' do
  redirect '/events/registration_error?error=incomplete' unless params.include?('first_name') &&
                                                                params['first_name']!="" &&
                                                                params.include?('last_name') &&
                                                                params['last_name']!="" &&
                                                                params.include?('email') &&
                                                                params['email']!=""


  @event = Event.new(:id => "Event:id:#{params['id']}").load
  redirect '/events/calendar' unless @event

  if Person.exists?(:email => params['email'])
    @person = Person.new(:email => params['email']).load
  else
    @person = Person.new()
    @person.first_name = params['first_name']
    @person.last_name = params['last_name']
    @person.email = params['email']
  end

  @ban_list = BanList.first
  redirect '/events/registration_denied' if @ban_list.banned?(@person)

  redirect '/events/registration_error?error=full' if @event.full?

  redirect '/events/registration_error?error=duplicate' if @event.attendee_list.includes?(@person)

  @person.save

  @confirmation = RegistrationConfirmation.new()
  @confirmation.person_id = @person.id
  @confirmation.event_id = @event.id
  @confirmation.save
  @confirmation.send_email
    
  haml :registration_email, :layout => :events  
end

get %r{/events/registration_confirmation/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})} do

  @confirmation = RegistrationConfirmation.new(:id => "RegistrationConfirmation:id:#{params[:captures].first}").load
  redirect_to '/events/registration_error?error=invalid_confirmation' unless @confirmation

  @confirmation.event.attendee_list.add(@confirmation.person).save
  @confirmation.delete

    
  haml :registration_complete, :layout => :events  
end

get '/events/registration_denied' do
  haml :registration_denied, :layout => :events
end

get '/events/registration_error' do
  case params[:error]
  when 'full'
    @error = "We're sorry but this event is already full."
  when 'duplicate'
    @error = "You are already registered!"
  when 'incomplete'
    @error = "We're sorry but we need your full name and your email."
  when 'invalid_confirmation'
    @error = "We're sorry but that is an invalid confirmation link."
  else
    @error = "We're sorry but an error has occured."    
  end
  haml :registration_error, :layout => :events
end


