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

            Order.create! express_no: columns[0], receiver_postcode: columns[1], receiver_addr: receiver_addr, receiver_name: receiver_name, receiver_phone: remove_zero(columns[5]), sender_province: "上海", sender_city: "上海市", sender_district: "浦东新区", sender_addr: "上海邮政信箱120-058", sender_name: senders[0], sender_phone: "4008205555", sender_postcode: senders[1], status: "waiting", address_status: "address_waiting", source: senders[2], category: I18n.t("order_category_factory"), unit_id: I18n.t("orders_zh_unit_id")
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
    elsif file_name.start_with?(I18n.t("jbda_sub_file_name"))
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

  # 商企金邦达银行订单
  def self.get_bank_orders 
    direct = I18n.t("orders_bank_path")
    
    if File.exist?(direct)
      to_deal_files = Order.get_to_deal_bank_files(direct)   
      
      to_deal_files.each do |ff|
        file_path_r_encrypt = File.join(direct, ff)

        begin
          Order.get_borders(file_path_r_encrypt)
        rescue Exception => e
          error_msg = "#{e.class.name} #{e.message} \n#{e.backtrace.join("\n")}"
          puts error_msg
          Rails.logger.error(error_msg)
        end
      end
    end
  end

  def self.get_to_deal_bank_files(direct)
    to_deal_files = []   

    Dir.children(direct).each do |f|
      if (!f.start_with? "do_") && (FileHelper.is_file(f, I18n.t("bank_names")))
        to_deal_files << f
      end
    end

    return to_deal_files
  end

  def self.get_borders(file_path_r_encrypt)
    ActiveRecord::Base.transaction do
      # 解密文件
      FileHelper.gpg_decrypt_file("12345678", file_path_r_encrypt, nil)
      #解密文件路径
      file_path = file_path_r_encrypt.gsub(File.extname(file_path_r_encrypt), '')  
      
      Order.deal_bank_file(file_path)
      
      file_name = File.basename(file_path_r_encrypt)
      File.rename(file_path_r_encrypt, file_path_r_encrypt.gsub(file_name, 'do_' + file_name))
    end
  end

  def self.deal_bank_file(file_path)
    instance=nil
    rowarr = [] 
    current_line = 0

    if file_path.try :end_with?, '.xlsx'
      instance= Roo::Excelx.new(file_path)
    elsif file_path.try :end_with?, '.xls'
      instance= Roo::Excel.new(file_path)
    else
      return
    end
    file_name = File.basename(file_path)
    instance.default_sheet = instance.sheets.first
    title_row = instance.row(2)

    mailNum_index = title_row.index("mailNum")
    # bankName_index = title_row.index("bankName")
    sname_index = title_row.index("sname")
    spostCode_index = title_row.index("spostCode")
    smobile_index = title_row.index("smobile")
    sprov_index = title_row.index("sprov")
    scity_index = title_row.index("scity")
    scounty_index = title_row.index("scounty")
    saddress_index = title_row.index("saddress")
    rname_index = title_row.index("rname")
    rpostCode_index = title_row.index("rpostCode")
    rphone_index = title_row.index("rphone")
    rprov_index = title_row.index("rprov")
    rcity_index = title_row.index("rcity")
    rcounty_index = title_row.index("rcounty")
    raddress_index = title_row.index("raddress")
    
    4.upto(instance.last_row) do |line|
      ActiveRecord::Base.transaction do
        begin
          current_line = line
          rowarr = instance.row(line)

          express_no = rowarr[mailNum_index].blank? ? "" : to_string(rowarr[mailNum_index])
          # bank_name = rowarr[bankName_index].blank? ? "" : to_string(rowarr[bankName_index])
          bank_name = Order.get_bank_name(file_name)
          sender_name = rowarr[sname_index].blank? ? "" : to_string(rowarr[sname_index]).encode('GBK', invaild: :replace, replace: '').encode('UTF-8')
          sender_postcode = rowarr[spostCode_index].blank? ? "" : to_string(rowarr[spostCode_index])
          sender_phone = rowarr[smobile_index].blank? ? "" : to_string(rowarr[smobile_index])
          sender_province = rowarr[sprov_index].blank? ? "" : to_string(rowarr[sprov_index]).encode('GBK', invaild: :replace, replace: '').encode('UTF-8')
          sender_city = rowarr[scity_index].blank? ? "" : to_string(rowarr[scity_index]).encode('GBK', invaild: :replace, replace: '').encode('UTF-8')
          sender_district = rowarr[scounty_index].blank? ? "" : to_string(rowarr[scounty_index]).encode('GBK', invaild: :replace, replace: '').encode('UTF-8')
          sender_addr = rowarr[saddress_index].blank? ? "" : to_string(rowarr[saddress_index]).encode('GBK', invaild: :replace, replace: '').encode('UTF-8')
          receiver_name = rowarr[rname_index].blank? ? "" : to_string(rowarr[rname_index]).encode('GBK', invaild: :replace, replace: '').encode('UTF-8')
          receiver_postcode = rowarr[rpostCode_index].blank? ? "" : to_string(rowarr[rpostCode_index])
          receiver_phone = rowarr[rphone_index].blank? ? "" : to_string(rowarr[rphone_index])
          receiver_province = rowarr[rprov_index].blank? ? "" : to_string(rowarr[rprov_index]).encode('GBK', invaild: :replace, replace: '').encode('UTF-8')
          receiver_city = rowarr[rcity_index].blank? ? "" : to_string(rowarr[rcity_index]).encode('GBK', invaild: :replace, replace: '').encode('UTF-8')
          receiver_district = rowarr[rcounty_index].blank? ? "" : to_string(rowarr[rcounty_index]).encode('GBK', invaild: :replace, replace: '').encode('UTF-8')
          receiver_addr = rowarr[raddress_index].blank? ? "" : to_string(rowarr[raddress_index]).encode('GBK', invaild: :replace, replace: '').encode('UTF-8')

          Order.create! express_no: express_no, bank_name: bank_name, sender_name: sender_name, sender_postcode: sender_postcode, sender_phone: sender_phone, sender_province: sender_province, sender_city: sender_city, sender_district: sender_district, sender_addr: sender_addr, receiver_name: receiver_name, receiver_postcode: receiver_postcode, receiver_phone: receiver_phone, receiver_province: receiver_province, receiver_city: receiver_city, receiver_district: receiver_district, receiver_addr: receiver_addr, status: "waiting", address_status: "address_waiting", category: I18n.t("order_category_bank"), unit_id: I18n.t("orders_sq_unit_id")
        rescue Exception => e
          error_msg = "#{e.class.name} #{e.message} \n#{e.backtrace.join("\n")}"
          puts "============= #{express_no}  ========="
          puts error_msg
          Rails.logger.error(error_msg)
          next
          raise ActiveRecord::Rollback
        end
      end
    end 
  end

  def self.to_string(text)
    if text.is_a? Float
      return text.to_s.split('.0')[0]
    else
      return text
    end
  end 

  def self.get_bank_name(file_name)
    bank_name = ""

    I18n.t("bank_names").each do |n|
      if file_name.include?n
        bank_name = n
        break
      end
    end
    return bank_name
  end
end