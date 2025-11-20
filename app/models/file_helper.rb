class FileHelper
  FTP_CONFIG = Rails.application.config_for(:ftp)
  

	def self.sftp_upload(file_path_l, file_path_r)
    Net::SFTP.start(FileHelper::FTP_CONFIG[:ftp_ip], FileHelper::FTP_CONFIG[:username], :password => FileHelper::FTP_CONFIG[:password], :port =>  FileHelper::FTP_CONFIG[:port]) do |sftp|
      sftp.upload!(file_path_l, file_path_r)
    end
  end

  # def self.sftp_download(file_path_r, file_path_l)
  #   Net::SFTP.start(FileHelper::FTP_CONFIG[:ftp_ip], FileHelper::FTP_CONFIG[:username], :password => FileHelper::FTP_CONFIG[:password], :port =>  FileHelper::FTP_CONFIG[:port]) do |sftp|
  #     sftp.download!(file_path_r, file_path_l)
  #   end
  # end

  def self.gpg_decrypt_file(password, file_path_r, file_path_t = nil)
    #If file_path_t is balnk,then set it
    file_path_t ||= file_path_r.gsub(File.extname(file_path_r), '')
    # 解密
    system("gpg --no-tty -o #{file_path_t} -d #{file_path_r}")
  end

  # #gpg解密
  # def self.gpg_decrypt_file(password, file_path_r, file_path_t = nil)
  #   file_path_t = file_path_r.gsub(File.extname(file_path_r), '') if file_path_t.blank?
  #   # 解密
  #   crypto = GPGME::Crypto.new(:password => password)
  #   File.open(file_path_t, "w") do |file|
  #     decrypt_data = crypto.decrypt(date, password: password, pinentry_mode: GPGME::PINENTRY_MODE_LOOPBACK)
  #     file.write decrypt_data.to_s.force_encoding("utf-8")
  #   end
  # end

  # 解压RAR文件的函数
  def self.extract_rar(file_path, destination_path = nil)
    destination_path = file_path.gsub(File.extname(file_path), '') if destination_path.blank?
    # 确保目标路径存在
    FileUtils.mkdir_p(destination_path) unless File.exist?(destination_path)

    # 调用unrar命令
    system("unrar x -y #{file_path.shellescape} #{destination_path.shellescape}")
  end


  #not use
  def self.sm4_encrypt_file(key, file_path_r, file_path_t = nil)
    file_path_t = "encrypt_#{file_path_r}" if file_path_t.blank?
    data = File.new(file_path_r).read
    data_encrypt = sm4_encrypt(key, Base64.encode64(data))
    file = File.new(file_path_t, "w+:gbk")
    file.puts data_decrypt.force_encoding('utf-8')
    file.close
  end

  def self.sm4_decrypt_file(key, file_path_r, file_path_t = nil)
    file_path_t = "decrypt_#{file_path_r}" if file_path_t.blank?
    data = File.new(file_path_r).read
    data_decrypt = sm4_decrypt(key, data)
    file = File.new(file_path_t, "w+")
    file.puts data_decrypt.force_encoding('utf-8')
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

    upload_dir = "/#{FileHelper::FTP_CONFIG[:upload_dir]}"

    file_path_name = Express.to_zh_first_file_by_date(start_date, end_date)
    if !file_path_name.blank?
      self.sftp_upload(file_path_name[0], "#{upload_dir}/#{file_path_name[1]}")
      Rails.logger.info("#{Time.now} zh_first_file upload #{file_path_name[1]}")
    end
  end

  # 生成文件（第2次上传）
  def self.to_zh_second_file
    start_date = Date.today-1.days
    end_date = Date.today

    upload_dir = "/#{FileHelper::FTP_CONFIG[:upload_dir]}"

    file_path_name = Express.to_zh_second_file_by_date(start_date, end_date)
    if !file_path_name.blank?
      self.sftp_upload(file_path_name[0], "#{upload_dir}/#{file_path_name[1]}")
      Rails.logger.info("#{Time.now} zh_second_file upload #{file_path_name[1]}")
    end
  end

  # 招行反馈核实结果（第1次取回）
  def self.from_zh_first_file
    direct_r = I18n.t("from_zh_first_file_path")
    if !File.exist?(direct_r)
      Dir.mkdir(direct_r)          
    end

    download_dir = "/#{FileHelper::FTP_CONFIG[:download_dir]}"

    self.sftp_download(download_dir, direct_r, I18n.t("first_download"))

    start_date = Date.yesterday
    Express.from_zh_first_file_by_date(start_date)
  end

  # 招行反馈核实结果（第2次取回）
  def self.from_zh_second_file
    direct_r = I18n.t("from_zh_second_file_r_path")
    if !File.exist?(direct_r)
      Dir.mkdir(direct_r)          
    end

    download_dir = "/#{FileHelper::FTP_CONFIG[:download_dir]}"

    self.sftp_download(download_dir, direct_r, I18n.t("second_download"))

    start_date = Date.yesterday
    Express.from_zh_second_file_by_date(start_date)
  end

  # 取金邦达订单文件
  def self.from_jbda_file
    direct_r = I18n.t("orders_r_path")
    if !File.exist?(direct_r)
      Dir.mkdir(direct_r)          
    end

    #POST原发卡业务
    download_dir = "/#{FileHelper::FTP_CONFIG[:jbda_dir]}"

    self.sftp_download(download_dir, direct_r, I18n.t("jbda_file_name"))

    #REPOST退卡重寄业务
    download_dir = "/#{FileHelper::FTP_CONFIG[:jbda_repost_dir]}"

    self.sftp_download(download_dir, direct_r, I18n.t("jbda_repost_file_name"))

    #REPOST业务

    # start_date = Date.today
    # Order.get_jbda_orders_by_date(start_date)
  end
  
  # 取捷德订单文件
  def self.from_jd_file
    direct_r = I18n.t("orders_r_path")
    if !File.exist?(direct_r)
      Dir.mkdir(direct_r)          
    end

    download_dir = "/#{FileHelper::FTP_CONFIG[:jd_dir]}"

    self.sftp_download(download_dir, direct_r, I18n.t("jd_file_name"))

    # start_date = Date.today
    # Order.get_jd_orders_by_date(start_date)
  end

  def self.sftp_download(r_dir, t_dir, file_name, remove = true)
    Net::SFTP.start(FileHelper::FTP_CONFIG[:ftp_ip], FileHelper::FTP_CONFIG[:username], :password => FileHelper::FTP_CONFIG[:password], :port =>  FileHelper::FTP_CONFIG[:port]) do |sftp|
      sftp.dir.foreach(r_dir) do |entry|
        
        name = entry.name.force_encoding('UTF-8')

        r_file = "#{r_dir}/#{name}"
        t_file = "#{t_dir}/#{name}"

        if self.is_file(name, file_name)

        #如果目标文件是空文件或者不存在该文件，则再取一次,最多取3次。
          3.times do
            if ! File.exist?(t_file) || file_size_zero?(t_file)
              sftp.download!(r_file, t_file)
              size = File.size(t_file)
              Rails.logger.info("#{Time.now} r_dir download #{name}  size： #{size}")
              # 等待2秒
              sleep(2)
            end
          end

          if remove && File.exist?(t_file) && ! file_size_zero?(t_file)
            sftp.remove!(r_file) 
          end
        end
      end
    end
  end

    #写一个方法判断文件大小是否为0
  def self.file_size_zero?(file_path)
    File.size(file_path) == 0
  end

  # 取金邦达银行订单文件
  def self.from_jbda_bank_file
    direct_bank = I18n.t("orders_bank_path")
    if !File.exist?(direct_bank)
      Dir.mkdir(direct_bank)          
    end

    download_dir = "/#{FileHelper::FTP_CONFIG[:jbda_bank_dir]}"
    file_name_start = I18n.t("bank_names")

    self.sftp_download(download_dir, direct_bank, file_name_start)
  end

  def self.is_file(name, file_name)
    result = false

    if file_name.is_a?Array
      file_name.each do |f|
        if name.include? f && ((name.end_with? ".pgp") || (name.end_with? ".PGP"))
          result = true
          return result
        end
      end
    elsif file_name.is_a?String
      if name.start_with? file_name
        result = true
      end
    end
    return result
  end
end