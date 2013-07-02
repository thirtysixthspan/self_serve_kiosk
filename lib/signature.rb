require 'gibberish'
require 'yaml'

def verify_signature(data, passphrase)
  test = {}
  data.each { |k,v| test[k.to_sym] = v }
  test[:passphrase] = passphrase
  sha512 = test[:sha512]
  test.delete(:sha512)
  Gibberish::SHA512(test.sort.to_s) == sha512
end

def add_signature(data, passphrase, originator = nil)
  signed = data.clone
  signed.delete(:sha512)
  signed[:passphrase] = passphrase
  signed[:timestamp] = Time.now.to_i.to_s
  signed[:originator] = originator if originator
  signed[:sha512] = Gibberish::SHA512(signed.sort.to_s)
  signed.delete(:passphrase)
  signed
end

def load_private_key(path=nil)
  file_name = path || 'conf/private.yaml'
  fail "Cannot find private configuration file" unless File.exists?(file_name)
  private = YAML.load(File.open(file_name))
  fail "Invalid Passphrase" unless verify_signature(private,AES_PASSPHRASE) 
  { 
    :aes_passphrase => AES_PASSPHRASE,
    :rsa_key => private[:rsa_key]
  }
end 


