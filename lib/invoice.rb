require 'redis'
require 'json'
require './lib/redis_record.rb'
require './lib/invoice_order_list.rb'
require './lib/order.rb'

class Invoice < RedisRecord

  def self.property_names
    [ 
      :created_at,	
      :customer_id, 
      :charge_id,
      :charge_status,
      :invoice_order_list_id,
      :tax_percent,
      :membership_discount_percent
    ]
  end

  def self.children
    [ 
      :invoice_order_list_id
    ]
  end

  def self.actions
    [:edit, :delete, :show, :email_invoice, :charge_card, :send_charge_confirmation, :retrieve_charge_status]
  end

  def identifier
    "404 Store Invoice #{self.uuid}"
  end

  def initialize_attributes
    @ivs += Invoice.property_names
  end

  def self.build
    order_customers = Order.not_invoiced.uniq { |o| o.customer_id }.map { |o| o.customer }     

    order_customers.each do |customer|
      pp customer.identifier
      customer_orders = Order.not_invoiced.select { |o| o.customer_id == customer.id }
      pp customer_orders.size
      list = InvoiceOrderList.new(members: customer_orders).save

      Invoice.new(customer_id: customer.id,
      			  invoice_order_list_id: list.id,
      			  created_at: Time.now.to_i.to_s,
              tax_percent: "0.08375" ,
              membership_discount_percent: "0.10").save.log

    end

  end

  def subtotal
    self.invoice_order_list.members.map{|order| order.items.map{|i| i[:price].to_i * i[:quantity].to_i}.sum}.sum  
  end

  def membership_discount
    amount = 0
    amount -= (self.subtotal.to_f * self.membership_discount_percent.to_f).to_i if self.customer.member_id && self.customer.member_id != ""
    amount
  end

  def discounted_subtotal
    self.subtotal + self.membership_discount
  end

  def tax_text
    sprintf("%.3f Percent Tax", self.tax_percent.to_f * 100.to_f)
  end

  def tax
    (self.discounted_subtotal.to_f * self.tax_percent.to_f).to_i
  end

  def total
    self.discounted_subtotal + self.tax
  end

  def date
    Time.at(self.created_at.to_i).to_datetime.strftime("%m/%d/%Y")
  end

  def body(template)
    invoice = self
    orders = self.invoice_order_list.members
    base = Class.new do
      include Haml::Helpers
      @invoice = invoice
      @orders = orders
    end
    Haml::Engine.new(IO.read(template)).render(base)
  end

  def email_invoice()
    return false unless self.customer.email && self.customer.email!=""
    return true if self.charge_id && self.charge_status=true
    email = {
      :to => self.customer.email,
      :from => "billing@self_service_kiosk.com",
      :subject => "New Store Invoice",
      :html_body => self.body('./views/admin/invoice_email.haml')
    }      
    email[:via_options] = { :location  => 'cat - > /tmp/last_email.html;', 
                            :arguments => '' } if DEVELOPMENT
    Pony.mail(email)
    true
  end

  def log()
    file_name = "#{INVOICE_PATH}/#{self.uuid}.invoice"
    begin
      File.open(file_name, "w") { |f| 
        YAML.dump(self.customer, f)
        YAML.dump(self, f)
        YAML.dump(self.invoice_order_list, f)
        f.write(self.body('./views/admin/invoice_email.haml')) 
      }
      return self
    rescue Exception => e
      return [nil, e.message]
    end
  end

  def show()
    return [200, self.body('./views/admin/invoice_email.haml')]
  end

  def charge_card()
    return false unless customer.charge_method
    return false if self.charge_id
    success, charge = customer.charge_card({
      :amount => self.total, 
      :description => self.identifier}
    )
    return [false, charge] unless success
    self.charge_id = charge.id
    self.charge_status = charge.paid
    save
    return [success, charge]
  end

  def retrieve_charge_status()
    return false unless self.charge_id
    self.charge_status = customer.retrieve_charge_status(self.charge_id)
    self.save
  end

  def send_charge_confirmation()
    return true unless self.customer.email && self.customer.email!=""
    return false unless self.charge_id && self.charge_status==true
    email = {
      :to => self.customer.email,
      :from => "billing@self_service_kiosk.com",
      :subject => "Store Credit Card Charge Successful",
      :html_body => self.body('./views/admin/charge_email.haml')
    }      
    email[:via_options] = { :location  => 'cat - > /tmp/last_email.html;', 
                            :arguments => '' } if DEVELOPMENT
    Pony.mail(email)
    true
  end

   
end
