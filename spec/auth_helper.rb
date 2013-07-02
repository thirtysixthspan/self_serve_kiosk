module AuthHelper
  require 'Base64'

  def install_admin
    p = Person.new()
    p.id = "Person:id:c616fe0f-3616-4265-97e2-9cd9c162c4b1"
    p.first_name = "Site"
    p.last_name = "Administrator"
    p.api_key = "fe724804-fc32-4e53-a834-de1a031d2dd5" 
    p.save
  end

  def clear_database
    Person.flushdb
    install_admin
  end 

  def auth_login
    admin_id = "c616fe0f-3616-4265-97e2-9cd9c162c4b1"
    admin_api_key = "fe724804-fc32-4e53-a834-de1a031d2dd5"    
    code = "#{admin_id}:#{admin_api_key}"
    @headers = {'HTTP_AUTHORIZATION' => "Basic " + Base64::encode64(code)}    
    @admin = Person.new(:id => admin_id).load
  end

  def basic_auth
    admin_id = "c616fe0f-3616-4265-97e2-9cd9c162c4b1"
    admin_api_key = "fe724804-fc32-4e53-a834-de1a031d2dd5"    
    page.driver.browser.basic_authorize(admin_id,admin_api_key)
  end
  
end

