require File.dirname(__FILE__) + '/../spec_helper'
require './lib/credit_card.rb'

describe "Credit Card" do
  
  before :all do
    @rsa_keys = Gibberish::RSA.generate_keypair(4096)
    @cc_data = { 
      :timestamp => Time.now.to_i.to_s, 
      :name => 'Parkhurst/ Derrick J',
      :number => '1023102310231023',
      :exp_month => '12',
      :exp_year => '2014'
    }
    @enc_secret = { 
      :aes_passphrase => 'this is my passphrase',
      :rsa_key => @rsa_keys.public_key
    }
    @dec_secret = { 
      :aes_passphrase => 'this is my passphrase',
      :rsa_key => @rsa_keys.private_key
    }      
  end
  
  it "requires all secret parameters upon initialization" do
    expect { CreditCard.new( @cc_data, {} ) }.to raise_error(ArgumentError)       
  end

  it "encrypt and decrypt" do
    cc = CreditCard.new( @cc_data, @enc_secret )

    cc2 = CreditCard.new( { :encrypted => cc.encrypted } , @dec_secret ) 
    
    cc2.data.should == @cc_data
  end

  it "encrypt, store, retrieve and decrypt" do
    cc = CreditCard.new( @cc_data, @enc_secret )

    cc.put_in_redis
    
    cc2 = CreditCard.new( {} , @dec_secret ) 
    cc2.get_from_redis    
    cc2.decrypt

    cc2.data.should == @cc_data
  end

  it "generates private and public keys" do

    FileUtils.rm('/tmp/public.yaml', :force => true)
    FileUtils.rm('/tmp/private.yaml', :force => true)

    CreditCard.generate_keys({
      :originator => "John Doe",
      :passphrase => AES_PASSPHRASE,
      :public_key_file_name => "/tmp/public.yaml",
      :private_key_file_name => "/tmp/private.yaml" 
    })

    File.exists?('/tmp/public.yaml').should == true
    File.exists?('/tmp/private.yaml').should == true

  end

  it "can encrypt and decrypt with generated private and public keys" do

    CreditCard.generate_keys({
      :originator => "John Doe",
      :passphrase => AES_PASSPHRASE,
      :public_key_file_name => "/tmp/public.yaml",
      :private_key_file_name => "/tmp/private.yaml" 
    })

    enc_secret = { 
      :aes_passphrase => AES_PASSPHRASE,
      :rsa_key => CreditCard.load_public_key(:originator => 'test', :passphrase => AES_PASSPHRASE, :key_file_name => "/tmp/public.yaml")
    }
    dec_secret = { 
      :aes_passphrase => AES_PASSPHRASE,
      :rsa_key => CreditCard.load_private_key(:originator => 'test', :passphrase => AES_PASSPHRASE, :key_file_name => "/tmp/private.yaml")
    }      
    cc = CreditCard.new( @cc_data, enc_secret )
    
    cc2 = CreditCard.new( { :encrypted => cc.encrypted } , dec_secret )
    
    cc2.data.should == @cc_data

  end

 it "can encrypt, store, retrieve and decrypt with generated private and public keys" do

    CreditCard.generate_keys({
      :originator => "John Doe",
      :passphrase => AES_PASSPHRASE,
      :public_key_file_name => "/tmp/public.yaml",
      :private_key_file_name => "/tmp/private.yaml" 
    })

    enc_secret = { 
      :aes_passphrase => AES_PASSPHRASE,
      :rsa_key => CreditCard.load_public_key(:originator => 'test', :passphrase => AES_PASSPHRASE, :key_file_name => "/tmp/public.yaml")
    }
    dec_secret = { 
      :aes_passphrase => AES_PASSPHRASE,
      :rsa_key => CreditCard.load_private_key(:originator => 'test', :passphrase => AES_PASSPHRASE, :key_file_name => "/tmp/private.yaml")
    }      
    cc = CreditCard.new( @cc_data, enc_secret )
    cc.put_in_redis   
 
    cc2 = CreditCard.new( {} , dec_secret ) 
    cc2.get_from_redis    
    cc2.decrypt
    
    cc2.data.should == @cc_data

  end

  it "provides accessors" do
    cc = CreditCard.new( @cc_data, @enc_secret )
    @cc_data.each do |k,v|
      eval("cc.#{k}").should == @cc_data[k]
    end
  end
  
end
