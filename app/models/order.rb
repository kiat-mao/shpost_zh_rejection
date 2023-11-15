class Order < ApplicationRecord
  enum status: {waiting: 'waiting', uploaded: 'uploaded'}
  STATUS_NAME = {waiting: '待上传', uploaded: '已上传'}

  enum address_status: {address_waiting: 'address_waiting', address_success: 'address_success', address_failed: 'address_failed', address_noparse: 'address_noparse', address_parseing: 'address_parseing'}
  ADDRESS_STATUS_NAME = {address_waiting: '待解析', address_success: '解析成功', address_failed: '解析失败', address_noparse: '不解析', address_parseing: '解析中'}

  def address_status_name
    address_status.blank? ? "" : Order::ADDRESS_STATUS_NAME["#{address_status}".to_sym]
  end

  def self.get_orders_by_date(start_date)
  	to_deal_r_files = []
  	fdate = start_date.strftime('%Y%m%d')

  	direct_r = I18n.t("orders_r_path")
  	if !File.exist?(direct_r)
	    Dir.mkdir(direct_r)          
		end
  
		fname_starts = I18n.t("download_file_start")
  	
  	Dir.children(direct_r).each do |f|
  		fname_starts.each do |s|
  			fname_start= s+"MAIL"+fdate
	  		if f.start_with? fname_start
	  			to_deal_r_files << f
	  		end
	  	end
  	end

  	to_deal_r_files.each do |ff|
  		file_path_r = File.join(direct_r, ff)
      Order.get_orders(file_path_r)
  	end
  end

  def self.get_orders(file_path_r)
    ActiveRecord::Base.transaction do
      direct_t = I18n.t("orders_t_path")
      if !File.exist?(direct_t)
        Dir.mkdir(direct_t)          
      end

      file_name_r = file_path_r.split("/").last

      file_path_t = File.join(direct_t, "decrypt_#{file_name_r}")
      FileHelper.sm4_decrypt_file("EMWL888888888888", file_path_r, file_path_t)

      File.open(file_path_t, "r:UTF-8") do |file|
      # File.open(file_path_r, "r:UTF-8") do |file|
      	sender_name = Order.get_sender_name(file_name_r)
        file.each_line do |line|
          columns = line.split("!^?")
          Order.create! express_no: columns[0], receiver_postcode: columns[1], receiver_addr: columns[2], receiver_name: columns[3], receiver_phone: columns[5], sender_province: "上海", sender_city: "上海市", sender_district: "浦东新区", sender_addr: "上海邮政信箱120-058", sender_name: sender_name, sender_phone: "4008205555", status: "waiting", address_status: "address_waiting"
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