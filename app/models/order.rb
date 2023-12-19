class Order < ApplicationRecord
  enum status: {waiting: 'waiting', uploaded: 'uploaded'}
  STATUS_NAME = {waiting: '待上传', uploaded: '已上传'}

  enum address_status: {address_waiting: 'address_waiting', address_success: 'address_success', address_failed: 'address_failed', address_noparse: 'address_noparse', address_parseing: 'address_parseing'}
  ADDRESS_STATUS_NAME = {address_waiting: '待解析', address_success: '解析成功', address_failed: '解析失败', address_noparse: '不解析', address_parseing: '解析中'}

  def status_name
    status.blank? ? "" : Order::STATUS_NAME["#{status}".to_sym]
  end

  def address_status_name
    address_status.blank? ? "" : Order::ADDRESS_STATUS_NAME["#{address_status}".to_sym]
  end

  def self.get_orders_by_date(start_date)
  	to_deal_r_files = []   #加密压缩文件
  	fdate = start_date.strftime('%Y%m%d')

  	direct = I18n.t("orders_r_path")
  	if !File.exist?(direct)
	    Dir.mkdir(direct)          
		end

    fname_starts = I18n.t("jbda_file_name")
    if !fname_starts.blank?
      fname_start= fname_starts+'_'+fdate
    
    	Dir.children(direct).each do |f|
    		if f.start_with? fname_start
	  			to_deal_r_files << f
	  		end
  	  end

    	to_deal_r_files.each do |ff|
        #加密压缩文件路径
    		file_path_r_encrypt = File.join(direct, ff)   
        Order.get_orders(file_path_r_encrypt)
    	end
    end
  end

  def self.get_orders(file_path_r_encrypt)
    ActiveRecord::Base.transaction do
      # 解密文件
      FileHelper.gpg_decrypt_file("888888888888", file_path_r_encrypt, nil)
      #解密压缩文件路径
      file_path_r_zip = file_path_r_encrypt.gsub(File.extname(file_path_r_encrypt), '')  
      # 解压文件
      unzip_decrypt_files = FileHelper.extract_rar(file_path_r_zip, nil)
      #解密解压文件夹路径
      file_path_r_unzip = file_path_r_zip.gsub(File.extname(file_path_r_zip), '')  

      Dir.children(file_path_r_unzip).each do |f|
        # 数据文件路径
        to_deal_file_path = File.join(file_path_r_unzip, f) 

        File.open(to_deal_file_path, "r:UTF-8") do |file|
          # sender_name = Order.get_sender_name(File.basename(to_deal_file_path))
        	sender_name = "招行卡中心"  
          file.each_line do |line|
            columns = line.split("!^?")
            Order.create! express_no: columns[0], receiver_postcode: columns[1], receiver_addr: columns[2], receiver_name: columns[3], receiver_phone: columns[5], sender_province: "上海", sender_city: "上海市", sender_district: "浦东新区", sender_addr: "上海邮政信箱120-058", sender_name: sender_name, sender_phone: "4008205555", status: "waiting", address_status: "address_waiting"
          end
        end
      end
    end
  end

  def self.get_sender_name(file_name)
  	if file_name.start_with?("JBD")
  		return "招行卡中心"
  	elsif file_name.start_with?("JD")
  		return "招商银行信用卡中心"
  	end
  end




end