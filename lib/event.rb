require './lib/redis_record.rb'
require './lib/attendee_list.rb'

class Event < RedisRecord

  def self.property_names
    [
      :date, 
      :duration,
      :title,
      :url,
      :description,
      :organizer_id,
      :attendee_list_id,
      :location,
      :type
    ]
  end

  def identifier
    self.title
  end

  def initialize_attributes
    @ivs += Event.property_names
    @keys += [
      :title
    ]
    @max_attendees = {"Conference Room" => 10, "Lounge" => 25}
  end

  def organizer
    Person.new(:id => organizer_id).load
  end

  def attendee_list
    AttendeeList.new(:id => attendee_list_id).load
  end

  def id_hash
    id.gsub(/^.*:/,'')
  end

  def number_registered
    attendee_list.size
  end

  def full?
    number_registered >= @max_attendees[location]
  end

  def starts_at
    date.to_i
  end

  def ends_at
    starts_at + duration.to_i
  end

  def overlaps?(event)
    location == event.location &&
    ((starts_at >= event.starts_at && starts_at<event.ends_at) ||
    (ends_at > event.starts_at && ends_at<=event.ends_at))
  end

end

