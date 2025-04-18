class Order < ApplicationRecord
  validates_uniqueness_of :express_no, :message => '该发卡信息已存在'

  enum status: {waiting: 'waiting', uploading: 'uploading',uploaded: 'uploaded'}
  STATUS_NAME = {waiting: '待上传', uploading: '上传中', uploaded: '已上传'}

  enum address_status: {address_waiting: 'address_waiting', address_success: 'address_success', address_failed: 'address_failed', address_noparse: 'address_noparse', address_parseing: 'address_parseing'}
  ADDRESS_STATUS_NAME = {address_waiting: '待解析', address_success: '解析成功', address_failed: '解析失败', address_noparse: '不解析', address_parseing: '解析中'}

  def status_name
    status.blank? ? "" : Order::STATUS_NAME["#{status}".to_sym]
  end

  def address_status_name
    address_status.blank? ? "" : Order::ADDRESS_STATUS_NAME["#{address_status}".to_sym]
  end

  # 金邦达
  def self.get_jbda_orders_by_date(start_date = nil)
    direct = I18n.t("orders_r_path")
    
  	to_deal_r_files = Order.get_to_deal_files(start_date, "jbda", direct)   
  	
  	to_deal_r_files.each do |ff|
      #加密压缩文件路径
    	file_path_r_encrypt = File.join(direct, ff)

      begin
        Order.get_jbda_orders(file_path_r_encrypt)
      rescue Exception => e
        error_msg = "#{e.class.name} #{e.message} \n#{e.backtrace.join("\n")}"
        puts error_msg
        Rails.logger.error(error_msg)
      end
    end
  end



  def self.get_jbda_orders(file_path_r_encrypt)
    ActiveRecord::Base.transaction do
      # 解密文件
      FileHelper.gpg_decrypt_file("12345678", file_path_r_encrypt, nil)
      #解密压缩文件路径
      file_path_r_zip = file_path_r_encrypt.gsub(File.extname(file_path_r_encrypt), '')  
      # 解压文件
      unzip_decrypt_files = FileHelper.extract_rar(file_path_r_zip, nil)
      #解密解压文件夹路径
      file_path_r_unzip = file_path_r_zip.gsub(File.extname(file_path_r_zip), '')  

      Dir.children(file_path_r_unzip).each do |f|
        # 数据文件路径
        to_deal_file_path = File.join(file_path_r_unzip, f) 
        Order.deal_file(to_deal_file_path)
      end

      file_name = File.basename(file_path_r_encrypt)
      File.rename(file_path_r_encrypt, file_path_r_encrypt.gsub(file_name, 'do_' + file_name))
    end
  end

  # 捷德
  def self.get_jd_orders_by_date(start_date = nil)
    direct = I18n.t("orders_r_path")
    
    to_deal_r_files = Order.get_to_deal_files(start_date, "jd", direct) 
    
    to_deal_r_files.each do |ff|
      file_path_r_encrypt = File.join(direct, ff)
      
      begin
        Order.get_jd_orders(file_path_r_encrypt)
      rescue Exception => e
        error_msg = "#{e.class.name} #{e.message} \n#{e.backtrace.join("\n")}"
        puts error_msg
        Rails.logger.error(error_msg)
      end
    end
  end

  def self.get_jd_orders(file_path_r_encrypt)
    ActiveRecord::Base.transaction do
      # 解密文件
      FileHelper.gpg_decrypt_file("12345abcde！", file_path_r_encrypt, nil)
      #解密文件路径
      to_deal_file_path = file_path_r_encrypt.gsub(File.extname(file_path_r_encrypt), '')   
      Order.deal_file(to_deal_file_path)

      file_name = File.basename(file_path_r_encrypt)
      File.rename(file_path_r_encrypt, file_path_r_encrypt.gsub(file_name, 'do_' + file_name))
    end
  end

  # 金邦达重寄
  def self.get_jbda_repost_orders_by_date(start_date = nil)
    direct = I18n.t("orders_r_path")
    
  	to_deal_r_files = Order.get_to_deal_files(start_date, "jbda_repost", direct)   
  	
  	to_deal_r_files.each do |ff|
      #加密压缩文件路径
    	file_path_r_encrypt = File.join(direct, ff)

      begin
        Order.get_jbda_repost_orders(file_path_r_encrypt)
      rescue Exception => e
        error_msg = "#{e.class.name} #{e.message} \n#{e.backtrace.join("\n")}"
        puts error_msg
        Rails.logger.error(error_msg)
      end
    end
  end

  def self.get_jbda_repost_orders(file_path_r_encrypt)
    ActiveRecord::Base.transaction do
      # 解密文件
      FileHelper.gpg_decrypt_file("12345678", file_path_r_encrypt, nil)
      #解密文件路径
      to_deal_file_path = file_path_r_encrypt.gsub(File.extname(file_path_r_encrypt), '')   
      Order.deal_file(to_deal_file_path)

      file_name = File.basename(file_path_r_encrypt)
      File.rename(file_path_r_encrypt, file_path_r_encrypt.gsub(file_name, 'do_' + file_name))
    end
  end

  # 获取需解密文件
  def self.get_to_deal_files(start_date, type, direct)
    to_deal_r_files = []   
    # fdate = start_date.strftime('%Y%m%d')

    if type.eql? "jbda"
      fname_starts = I18n.t("jbda_file_name")
    elsif type.eql? "jd"
      fname_starts = I18n.t("jd_file_name")
    elsif type.eql? "jbda_repost"
      fname_starts = I18n.t("jbda_repost_file_name")
    end
        
    if !fname_starts.blank?
      fname_start= fname_starts#+fdate
    
      Dir.children(direct).each do |f|
        if (f.start_with? fname_start) && (f.end_with? ".pgp")
          to_deal_r_files << f
        end
      end
    end
    return to_deal_r_files
  end

  # 读文件插表
  def self.deal_file(to_deal_file_path)
    File.open(to_deal_file_path, "r:UTF-8") do |file|
      senders = Order.get_senders(File.basename(to_deal_file_path))
       
      file.each_line do |line|
        columns = line.gsub(/\r\n?|\n/, '').split("!^?")
        ActiveRecord::Base.transaction do
          begin
            receiver_addr = columns[2].encode('GBK', invaild: :replace, replace: '').encode('UTF-8')
            receiver_name = columns[3].encode('GBK', invaild: :replace, replace: '').encode('UTF-8')

            Order.create! express_no: columns[0], receiver_postcode: columns[1], receiver_addr: receiver_addr, receiver_name: receiver_name, receiver_phone: remove_zero(columns[5]), sender_province: "上海", sender_city: "上海市", sender_district: "浦东新区", sender_addr: "上海邮政信箱120-058", sender_name: senders[0], sender_phone: "4008205555", sender_postcode: senders[1], status: "waiting", address_status: "address_waiting", source: senders[2]
          rescue Exception => e
            error_msg = "#{e.class.name} #{e.message} \n#{e.backtrace.join("\n")}"
            puts "============= #{columns[0]}  ========="
            puts error_msg
            Rails.logger.error(error_msg)
            next
            raise ActiveRecord::Rollback
          end
        end 
      end
    end
  end

  #写一个方法去掉number开头的所有0
  def self.remove_zero(number)
    number.gsub!(/^0*/, "")
    number
  end

  # 获取发件人信息

  def self.get_senders(file_name) 
    # 捷德
    if file_name.start_with?(I18n.t("jd_file_name"))
      return [I18n.t("jd_sender_name"), I18n.t("jd_sender_postcode"), "jd"]
    elsif file_name.start_with?(I18n.t("jbda_file_name"))
      # 金邦达
      return [I18n.t("jbda_sender_name"), I18n.t("jbda_sender_postcode"), "jbda"]
    elsif file_name.start_with?(I18n.t("jbda_repost_file_name"))
      # 金邦达
      return [I18n.t("jbda_repost_sender_name"), I18n.t("jbda_repost_sender_postcode"), "jbda_repost"]
    end
  end

  def self.destroy_orders_2days_ago!
    ActiveRecord::Base.transaction do
      Order.where("created_at < ?", (Date.today - 2.days)).destroy_all
      InterfaceSender.where("created_at < ?", (Date.today - 2.days)).where(parent_class: 'Order').destroy_all
    end
  end
end