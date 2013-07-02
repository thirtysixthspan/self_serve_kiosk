#!/usr/bin/env ruby

require 'rest-client'
require './lib/credit_card.rb'
require 'yaml'
require './lib/customer.rb'

AES_PASSPHRASE = 'secret_passphrase_must_replace'
ENC_SECRET = { 
  :aes_passphrase => AES_PASSPHRASE,
  :rsa_key => CreditCard.load_public_key(:passphrase => AES_PASSPHRASE, :key_file_name => "/tmp/public.yaml")
}
@cc_data = { 
  :timestamp => Time.now.to_i.to_s, 
  :name => 'Parkhurst/ Derrick J',
  :number => '4242424242424242',
  :exp_month => '12',
  :exp_year => '2014'
}
cc = CreditCard.new( @cc_data, ENC_SECRET )

signed_query = CreditCard.add_signature({:data => cc.encrypted},AES_PASSPHRASE)
RestClient.post 'http://0.0.0.0:8080/store/card', signed_query


