class FileHelper
  ftp_config = Rails.application.config_for(:ftp)
  

	def self.sftp_upload(file_path_l, file_path_r = './')
    Net::SFTP.start(ftp_config[:ftp_ip], ftp_config[:username], :password => ftp_config[:password]) do |sftp|
      sftp.upload!(file_path_l, file_path_r)
    end
  end

  #not use
  def self.sm4_encrypt_file(key, file_path_r, file_path_t = nil)
    file_path_t = "encrypt_#{file_path_r}" if file_path_t.blank?
    data = File.new(file_path_r).read
    data_encrypt = sm4_encrypt(key, Base64.encode64(data))
    file = File.new(file_path_t, "w+:gbk")
    file.puts data_decrypt.force_encoding('gbk')
    file.close
  end

  def self.sm4_decrypt_file(key, file_path_r, file_path_t = nil)
    file_path_t = "decrypt_#{file_path_r}" if file_path_t.blank?
    data = File.new(file_path_r).read
    data_decrypt = sm4_decrypt(key, data)
    file = File.new(file_path_t, "w+")
    file.puts data_decrypt.force_encoding('gbk')
    file.close
  end

  def self.sm4_encrypt(key, data)
    cipher = OpenSSL::Cipher.new('sm4-ecb')
    cipher.encrypt
    cipher.key = key
    encrypted = cipher.update(data) + cipher.final
  end

  def self.sm4_decrypt(key, data)
    decipher = OpenSSL::Cipher.new("sm4-ecb")
    decipher.decrypt
    decipher.key = key
    decipher.update(data) + decipher.final
  end
end