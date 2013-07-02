require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../auth_helper'

require 'capybara/rspec'

Capybara.app = Sinatra::Application

feature "Record operations in admin interface" do
  include AuthHelper

  def create_person
    @person = Person.new()
    @person.set(
      :first_name=>'John',
      :last_name=>'Doe',
      :email=>'john.doe@gmail.com'
    ) 
    @person.save
  end

  def delete_person
    @person.delete
  end

  before :each do
    basic_auth
  end

  scenario "edit" do
    create_person
    visit "/admin/edit/Person/#{@person.uuid}"

    fill_in 'Person[member_number]', :with => '12345678'

    click_on "Update"

    page.should have_content('12345678')

    person = Person.new(id: @person.id).load
    person.should be_a Person
    person.member_number.should == '12345678'
    delete_person
  end

  scenario "delete" do
    create_person
    visit "/admin/inspect/Person/#{@person.uuid}"

    click_on "delete"

    person = Person.new(id: @person.id).load
    person.should == nil
  end

end
