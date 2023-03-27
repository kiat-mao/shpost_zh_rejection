class FileHelper
  ftp_config = Rails.application.config_for(:ftp)
  

	def self.sftp_upload(file_path_l, file_path_r)
    Net::SFTP.start(ftp_config[:ftp_ip], ftp_config[:username], :password => ftp_config[:password]) do |sftp|
      sftp.upload!(file_path_l, file_path_r)
    end
  end

  def self.sftp_download(file_path_r, file_path_l)
    Net::SFTP.start(ftp_config[:ftp_ip], ftp_config[:username], :password => ftp_config[:password]) do |sftp|
      sftp.download!(file_path_r, file_path_l)
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

  # 生成文件（第1次上传）
  def self.to_zh_first_file
    start_date = Date.today-1.days
    end_date = Date.today
    file_path_name = Express.to_zh_first_file_by_date(start_date, end_date)
    self.sftp_upload(file_path_name[0], "/fct2ap/#{file_path_name[1]}")
  end

  # 生成文件（第2次上传）
  def self.to_zh_second_file
    start_date = Date.today-1.days
    end_date = Date.today
    file_path_name = Express.to_zh_second_file_by_date(start_date, end_date)
    self.sftp_upload(file_path_name[0], "/fct2ap/#{file_path_name[1]}")
  end

  # 招行反馈核实结果（第1次取回）
  def self.from_zh_first_file
    direct_r = I18n.t("from_zh_first_file_r_path")
    if !File.exist?(direct_r)
      Dir.mkdir(direct_r)          
    end


    sftp.dir.foreach("/ap2fct") do |entry|
      self.sftp_download("/ap2fct/#{entry.longname}", "#{direct_r}/#{entry.longname}")
      sftp.remove!("/ap2fct/#{entry.longname}")

      start_date = Date.today-1.days
      Express.from_zh_first_file_by_date(start_date)
    end
  end

    # 招行反馈核实结果（第2次取回）
  def self.from_zh_second_file
    direct_r = I18n.t("from_zh_second_file_r_path")
    if !File.exist?(direct_r)
      Dir.mkdir(direct_r)          
    end

    sftp.dir.foreach("/ap2fct") do |entry|
      self.sftp_download("/ap2fct/#{entry.longname}", "#{direct_r}/#{entry.longname}")
      sftp.remove!("/ap2fct/#{entry.longname}")

      start_date = Date.today-1.days
      Express.from_zh_second_file_by_date(start_date)
    end
  end
end