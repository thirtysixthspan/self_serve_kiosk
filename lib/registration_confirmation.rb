require './lib/redis_record.rb'
require './lib/person.rb'
require './lib/event.rb'
require 'sass'
require 'haml'

class RegistrationConfirmation < RedisRecord

  def self.property_names
    [
      :person_id,
      :event_id
    ]
  end

  def initialize_attributes
    @ivs += RegistrationConfirmation.property_names
  end

  def person
    Person.new(:id => person_id).load
  end

  def event
    Event.new(:id => event_id).load
  end

  def send_email
    @person = person
    @event = event
    @confirmation = self
    Pony.mail({
      :to => @person.email,
      :from => "registration@self_service_kiosk.com",
      :subject => "Registration confirmation required to attend #{@event.title}",
      :html_body => Haml::Engine.new(IO.read('./views/registration_confirmation_email.haml')).render(self)
    }) 
  end

end

