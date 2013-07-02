
get '/events/calendar' do
  @events = Event.all.select{ |e| (e.ends_at + 24*60*60) > Time.now.to_i}

  haml :calendar, :layout => :events  
end

get '/events/new_event' do
  haml :new_event, :layout => :events  
end

post '/events/new_event' do
  
  required_params = Event.property_names
  required_params.delete(:attendee_list_id)
  required_params.delete(:organizer_id)
  required_params << :first_name
  required_params << :last_name
  required_params << :email
  required_params << :member_number
  required_params << :time

  success, status, cparams = validate(params, required_params)
  redirect '/events/new_event_error?error=incomplete' unless success

  redirect '/events/new_event_error?error=member_not_found' unless 
    Person.exists?(:member_number => cparams[:member_number])

  @organizer = Person.new()
  @organizer.set(cparams.slice(*Person.property_names))

  redirect '/events/new_event_error?error=member_information_error' unless
    @organizer === Person.new(:member_number => cparams[:member_number]).load 

  @leader_list = LeaderList.first
  @member_list = MemberList.first

  redirect '/events/new_event_error?error=not_permitted' unless 
     (cparams[:type]=='Public' && !@leader_list.includes?(@organizer)) ||
     (cparams[:type]=='Private' && !@member_list.includes?(@organizer))

  @event = Event.new()
  @event.set(cparams)
  begin
    @event.date = Time.strptime("#{cparams[:time]} #{cparams[:date]}", "%l:%M%p %m/%d/%Y").to_i.to_s
  rescue
    redirect '/events/new_event_error?error=bad_time'
  end
 
  @event.organizer_id = Person.new(:member_number => cparams[:member_number]).id
  
  Event.all.each do |scheduled_event|
    redirect '/events/new_event_error?error=conflict' if scheduled_event.overlaps?(@event)
  end

  attendee_list = AttendeeList.new().save
  @event.attendee_list_id = attendee_list.id
  @event.save
  
  haml :registration, :layout => :events  
end

get '/events/new_event_error' do
  case params[:error]
  when 'incomplete'
    @error = "We're sorry but some of the form fields were missing or incomplete."
  when 'member_not_found'
    @error = "We don't seem to have you on record as a member."
  when 'member_information_error'
    @error = "We're sorry but some of your member information was not accurate."
  when 'not_permitted'
    @error = "We're sorry but you are not permitted to create that type of event."    
  when 'bad_time'
    @error = "We're sorry but the time you entered is invalid."    
  when 'conflict'
    @error = "We're sorry but that time is already reserved."    
  else
    @error = "We're sorry but an error has occured."    
  end
  haml :new_event_error, :layout => :events
end
