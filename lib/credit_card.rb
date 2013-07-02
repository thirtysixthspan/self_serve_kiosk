require 'gibberish'
require 'json'
require 'redis'
require 'uuidtools'

class CreditCard

  @@ivs = [:timestamp, 
           :name, :number, :exp_month, :exp_year, 
           :encrypted]
  @@ivs.each { |v| attr_accessor v }

  @@svs = [:rsa_key, :aes_passphrase ]
  
  def data
    { 
      :timestamp => @timestamp.to_s,
      :name => @name.to_s,
      :number => @number.to_s,
      :exp_month => @exp_month.to_s,
      :exp_year => @exp_year.to_s
    }
  end
  
  def plaintext
    JSON.dump(data)
  end
  
  def encrypted?
    @encryption_completed
  end

  def encrypt
    begin
      aes_cypher = Gibberish::AES.new(@aes_passphrase)
      aes_encrypted = aes_cypher.enc(plaintext)
      
      rsa_cipher = Gibberish::RSA.new(@rsa_key)
      @encrypted = rsa_cipher.encrypt(aes_encrypted)
    rescue Exception => e  
      LOG.info "Encryption failed: #{e.message}"  
      @encryption_completes = false
      return
    end
    @encrypttion_completed = true
  end
  
  def decrypted?
    @decryption_completed
  end

  def decrypt
    return unless @encrypted

    begin
      rsa_cipher = Gibberish::RSA.new(@rsa_key)
      rsa_decrypted = rsa_cipher.decrypt(@encrypted)
      
      aes_cypher = Gibberish::AES.new(@aes_passphrase)
      double_decrypted = aes_cypher.dec(rsa_decrypted)
      
      decrypted = JSON.parse(double_decrypted)
    rescue Exception => e  
      LOG.info "Decryption failed: #{e.message}"  
      @decryption_completed = false
      return
    end
    decrypted.each do |k,v|
      self.instance_variable_set("@#{k}", v) if @@ivs.include?(k.to_sym)      
    end    
    @decryption_completed = true
  end
  
  def initialize(data, secret)
    data.each do |k,v|
      self.instance_variable_set("@#{k}", v) if @@ivs.include?(k.to_sym)
    end
    @@svs.each do |k,v|
      if secret.include?(k)
        self.instance_variable_set("@#{k}", secret[k]) 
      else  
       raise ArgumentError, "Missing #{k}"
      end
    end
    
    @decryption_completed = false
    @encryption_completed = false

    if data.include?(:encrypted)
      decrypt()
    else
      encrypt()
    end
  end

  def put_in_redis
    REDIS.set "last_card", @encrypted 
    REDIS.expire "last_card", 5*60
  end

  def self.generate_card_token
    token = UUIDTools::UUID.random_create.to_s
    REDIS.del "last_card"    
    REDIS.set "last_card_token", token
    REDIS.expire "last_card_token", 5*60
    token
  end

  def swipe_requested?
    REDIS.exists "last_card_token"
  end

  def card_token
    @card_token
  end

  def get_from_redis
    @encrypted = REDIS.get "last_card"
    @card_token = REDIS.get "last_card_token"
  end

  def self.verify_signature(data, passphrase)
    test = {}
    data.each { |k,v| test[k.to_sym] = v }
    test[:passphrase] = passphrase
    sha512 = test[:sha512]
    test.delete(:sha512)
    Gibberish::SHA512(test.sort.to_s) == sha512
  end

  def self.add_signature(data, passphrase, originator = nil)
    signed = data.clone
    signed.delete(:sha512)
    signed[:passphrase] = passphrase
    signed[:timestamp] = Time.now.to_i.to_s
    signed[:originator] = originator if originator
    signed[:sha512] = Gibberish::SHA512(signed.sort.to_s)
    signed.delete(:passphrase)
    signed
  end
  
  def self.generate_keys(params)
    originator = params[:originator]
    passphrase = params[:passphrase]

    rsa_keys = Gibberish::RSA.generate_keypair(4096)

    enc_secret = add_signature( {:rsa_key => rsa_keys.public_key.to_s}, passphrase, originator ) 
    File.open(params[:public_key_file_name], 'w') { |f| YAML.dump(enc_secret, f) }

    dec_private = add_signature( {:rsa_key => rsa_keys.private_key.to_s}, passphrase, originator) 
    File.open(params[:private_key_file_name], 'w') { |f| YAML.dump(dec_private, f) }
  end

  def self.load_key(params = {})
    key = params[:type] || 'private'
    key_file_name = params[:key_file_name] || "conf/#{type}.yaml"
    passphrase = params[:passphrase]

    fail "Cannot find #{key} configuration file" unless File.exists?(key_file_name)
    key_data = YAML.load(File.open(key_file_name))
    fail "Invalid Passphrase" unless CreditCard.verify_signature(key_data, passphrase) 
    key_data[:rsa_key]
  end

  def self.load_public_key(params)
    params[:type] = 'public'
    load_key(params)
  end

  def self.load_private_key(params)
    params[:type] = 'private'
    load_key(params)
  end

end
  