class Express < ApplicationRecord
  belongs_to :batch
  
  enum status: {waiting: 'waiting', uploaded: 'uploaded', checked: 'checked', cancelled: 'cancelled', pending: 'pending', done: 'done',  feedback: 'feedback'}
  STATUS_NAME = {waiting: '待上传', uploaded: '待核实', checked: '已核实', cancelled: '已取消', pending: '待处理', done: '处理完成', feedback: '已反馈'}

  enum address_status: {address_waiting: 'address_waiting', address_success: 'address_success', address_failed: 'address_failed', address_noparse: 'address_noparse', address_parseing: 'address_parseing'}
  ADDRESS_STATUS_NAME = {address_waiting: '待解析', address_success: '解析成功', address_failed: '解析失败', address_noparse: '不解析', address_parseing: '解析中'}

  DEAL_REQUIRE_NAME = {'01': '改址重寄', '02': '原地址重寄', '03': '退回卡厂'}

  DEAL_RESULT_NAME = {'01': '已改址重寄', '02': '改址重寄失败', '03': '已原地址寄送', '04': '原地址重寄失败', '05': '退回卡厂成功', '06': '退回卡厂失败'}

  def status_name
    status.blank? ? "" : Express::STATUS_NAME["#{status}".to_sym]
  end

  def address_status_name
    address_status.blank? ? "" : Express::ADDRESS_STATUS_NAME["#{address_status}".to_sym]
  end

  def deal_require_name
    deal_require.blank? ? "" : Express::DEAL_REQUIRE_NAME["#{deal_require}".to_sym]
  end

  def deal_result_name
    deal_result.blank? ? "" : Express::DEAL_RESULT_NAME["#{deal_result}".to_sym]
  end

  def self.to_zh_first_file_by_date(start_date, end_date)
    file_path_name = nil
    results = Express.where("status=? and scaned_at<?", "waiting", end_date)
    if !results.blank?
    	filename = "#{I18n.t("first_upload")}#{Time.now.strftime('%Y%m%d%H%M')}.TXT"
      direct = I18n.t("to_zh_first_file_path")
  	    	
      if !File.exist?(direct)
  	    Dir.mkdir(direct)          
  		end

      file_path = direct + filename 
      file_path_name = [file_path, filename]

      to_zh_first_file_content_for(results, file_path)
    end  
    return file_path_name 
  end

  def self.to_zh_first_file_content_for(results, file_path)
  	f = File.new(file_path, "w+:UTF-8", &:read)
  	
  	ActiveRecord::Base.transaction do
	  	results.each do |r|
	  		f.write("#{r.express_no}!001!#{r.scaned_at.strftime('%Y-%m-%d %H:%M:%S')}!!!!\n")
	  	end
	  	results.update_all status: "uploaded"
	  end
  	f.close
  end

  def self.to_zh_second_file_by_date(start_date, end_date)
    file_path_name = nil
    results = Express.where("status=? and scaned_at<?", "done", end_date).order(:scaned_at, :express_no)
    if !results.blank?
    	filename = "#{I18n.t("second_upload")}#{Time.now.strftime('%Y%m%d%H%M')}.TXT"
      direct = I18n.t("to_zh_second_file_path")
  	    	
      if !File.exist?(direct)
  	    Dir.mkdir(direct)          
  		end

      file_path = direct + filename 
      file_path_name = [file_path, filename]
    
      to_zh_second_file_content_for(results, file_path)
    end
	  
    return file_path_name    
  end


  def self.to_zh_second_file_content_for(results, file_path)
  	f = File.new(file_path, "w+:UTF-8", &:read)
  	
  	ActiveRecord::Base.transaction do
	  	results.each do |r|
	  		f.write("#{r.express_no}!#{(r.new_express_no.eql?r.express_no) ? "" : r.new_express_no}!#{r.deal_result}!#{r.deal_desc}!\n")
	  	end
	  	results.update_all status: "feedback"
	  end
  	f.close
  end

  def self.from_zh_first_file_by_date(start_date)
  	to_deal_files = []
  	fdate = start_date.strftime('%Y%m%d')

  	direct = I18n.t("from_zh_first_file_path")
  	if !File.exist?(direct)
	    Dir.mkdir(direct)          
		end
  	fname_start = I18n.t("first_download")+fdate

  	# all_files = Dir.children(direct)
  	Dir.children(direct).each do |f|
  		if f.start_with?fname_start
  			to_deal_files << f
  		end
  	end

	  to_deal_files.each do |ff|
	  	file_path = File.join(direct, ff)
	  	Express.from_zh_first_file(file_path)
	  end
  end

  def self.from_zh_first_file(file_path)
    ActiveRecord::Base.transaction do
  		File.open(file_path, "r:UTF-8") do |file|
  			file.each_line do |line|
  				columns = line.split("!")
  				e = Express.find_by(express_no: columns[1], status: "uploaded")
  				if !e.blank?
  					if columns[3].eql?"02"
  						e.update! anomaly: true, anomaly_desc: columns[4], status: "checked"
  					else
  						e.update! status: "checked"
  					end  					
  				end
  			end
  		end
    end
	end

  def self.from_zh_second_file_by_date(start_date)
  	to_deal_r_files = []
  	fdate = start_date.strftime('%Y%m%d')

  	direct_r = I18n.t("from_zh_second_file_r_path")
  	if !File.exist?(direct_r)
	    Dir.mkdir(direct_r)          
		end
  
		fname_start = I18n.t("second_download")+fdate
  	
  	# all_r_files = Dir.children(direct_r)
  	Dir.children(direct_r).each do |f|
  		if f.start_with? fname_start
  			to_deal_r_files << f
  		end
  	end

  	to_deal_r_files.each do |ff|
  		file_path_r = File.join(direct_r, ff)
      Express.from_zh_second_file(file_path_r)
  	end
  end

  def self.from_zh_second_file(file_path_r)
    ActiveRecord::Base.transaction do
      batches = []

      direct_t = I18n.t("from_zh_second_file_t_path")
      if !File.exist?(direct_t)
        Dir.mkdir(direct_t)          
      end

      file_name_r = file_path_r.split("/").last

      file_path_t = File.join(direct_t, "decrypt_#{file_name_r}")
      FileHelper.sm4_decrypt_file("EMWL888888888888", file_path_r, file_path_t)

      File.open(file_path_t, "r:UTF-8") do |file|
      # File.open(file_path_r, "r:UTF-8") do |file|
        file.each_line do |line|
          columns = line.split("!")
          e = Express.find_by(express_no: columns[0], status: "checked")
          if !e.blank?
            batches << e.batch_id if !(batches.include?e.batch_id)
          
            if ["01", "02"].include?columns[1]
              addr = columns[3].encode('GBK', invaild: :replace, replace: '').encode('UTF-8')
              e.update! deal_require: columns[1], status: "pending", address_status: "address_waiting", receiver_postcode: columns[2], receiver_addr: columns[3], receiver_name: columns[4], receiver_phone: columns[5]
            else
              e.update! deal_require: columns[1], status: "pending"#, address_status: "address_waiting"
            end
          end
        end
      end
      Batch.where(id: batches).each{|x| x.update! status: "pending" }  
    end
  end

  def self.get_done_deal_result(deal_require)
    deal_result = ""
    case deal_require
    when "01"
      deal_result = "02"
    when "02"
      deal_result = "04"
    when "03"
      deal_result = "06"
    end
    return deal_result
  end
end
