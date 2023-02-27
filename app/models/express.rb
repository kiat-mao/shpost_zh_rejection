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

  def self.sftp_upload(file_path_l, file_path_r = './')
    Net::SFTP.start('172.10.126.51', 'test0817', :password => 'test0817') do |sftp|
      sftp.upload!(file_path_l, file_path_r)
    end
  end

  # 生成文件（第1次上传）
  def self.to_zh_first_file
  	start_date = Date.today-1.days
    end_date = Date.today
    file_path_name = to_zh_first_file_by_date(start_date, end_date)
    # sftp_upload(file_path_name[0], "/upload/#{file_path_name[1]}")
  end

  def self.to_zh_first_file_by_date(start_date, end_date)
  	filename = "OAPEM11U#{Time.now.strftime('%Y%m%d%H%M')}.txt"
    direct = I18n.t("to_zh_first_file_path")
	    	
    if !File.exist?(direct)
	    Dir.mkdir(direct)          
		end

    file_path = direct + filename 

    results = Express.where("status=? and scaned_at>=? and scaned_at<?", "waiting", start_date, end_date)
    to_zh_first_file_content_for(results, file_path)
	   
    return [file_path, filename]    
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

  # 生成文件（第2次上传）
  def self.to_zh_second_file
  	start_date = Date.today-1.days
    end_date = Date.today
    file_path_name = to_zh_second_file_by_date(start_date, end_date)
    # sftp_upload(file_path_name[0], "/upload/#{file_path_name[1]}")
  end

  def self.to_zh_second_file_by_date(start_date, end_date)
  	filename = "OAPEM02U#{Time.now.strftime('%Y%m%d%H%M')}.txt"
    direct = I18n.t("to_zh_second_file_path")
	    	
    if !File.exist?(direct)
	    Dir.mkdir(direct)          
		end

    file_path = direct + filename 

    results = Express.where("status=? and scaned_at>=? and scaned_at<?", "done", start_date, end_date).order(:scaned_at, :express_no)
    to_zh_second_file_content_for(results, file_path)
	  
    return [file_path, filename]    
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

  # 招行反馈核实结果（第1次取回）
  def self.from_zh_first_file
  	start_date = Date.today-1.days
    file_path_name = from_zh_first_file_by_date(start_date)
  end

  def self.from_zh_first_file_by_date(start_date)
  	to_deal_r_files = []
  	fdate = start_date.strftime('%Y%m%d')

  	direct_r = I18n.t("from_zh_first_file_r_path")
  	if !File.exist?(direct_r)
	    Dir.mkdir(direct_r)          
		end
  	direct_t = I18n.t("from_zh_first_file_t_path")
  	if !File.exist?(direct_t)
	    Dir.mkdir(direct_t)          
		end
		fname_start = "OAPEM11D"+fdate

  	all_r_files = Dir.children(direct_r)
  	all_r_files.each do |f|
  		if f.start_with?fname_start
  			to_deal_r_files << f
  		end
  	end

  	ActiveRecord::Base.transaction do
	  	to_deal_r_files.each do |ff|
	  		file_path_r = File.join(direct_r, ff)
	  		file_path_t = File.join(direct_t, "decrypt_#{ff}")
	  		FileHelper.sm4_decrypt_file(key, file_path_r, file_path_t = nil)

	  		File.open(file_path_t, "r:UTF-8") do |file|
	  		# File.open(file_path_r, "r:UTF-8") do |file|
	  			file.each_line do |line|
	  				columns = line.split("!")
	  				e = Express.find_by(express_no: columns[1], status: "uploaded")
	  				if !e.blank?
	  					if columns[3].eql?"02"
	  						e.update anomaly: true, anomaly_desc: columns[4], status: "checked"
	  					else
	  						e.update status: "checked"
	  					end  					
	  				end
	  			end
	  		end
	  	end
	  end
  end

  # 招行反馈核实结果（第2次取回）
  def self.from_zh_second_file
  	start_date = Date.today-1.days
    file_path_name = from_zh_second_file_by_date(start_date)
  end

  def self.from_zh_second_file_by_date(start_date)
  	batches = []
  	to_deal_r_files = []
  	fdate = start_date.strftime('%Y%m%d')

  	direct_r = I18n.t("from_zh_second_file_r_path")
  	if !File.exist?(direct_r)
	    Dir.mkdir(direct_r)          
		end
  	direct_t = I18n.t("from_zh_second_file_t_path")
  	if !File.exist?(direct_t)
	    Dir.mkdir(direct_t)          
		end
		fname_start = "OAPEM02D"+fdate
  	
  	all_r_files = Dir.children(direct_r)
  	all_r_files.each do |f|
  		if f.start_with? fname_start
  			to_deal_r_files << f
  		end
  	end

  	ActiveRecord::Base.transaction do
	  	to_deal_r_files.each do |ff|
	  		file_path_r = File.join(direct_r, ff)
	  		file_path_t = File.join(direct_t, "decrypt_#{ff}")
	  		FileHelper.sm4_decrypt_file(key, file_path_r, file_path_t = nil)

	  		File.open(file_path_t, "r:UTF-8") do |file|
	  		# File.open(file_path_r, "r:UTF-8") do |file|
	  			file.each_line do |line|
	  				columns = line.split("!")
	  				e = Express.find_by(express_no: columns[0], status: "checked")
	  				if !e.blank?
	  					batches << e.batch_id if !batches.include?e.batch_id
	  				
	  					if ["01", "02"].include?columns[1]
	  						e.update deal_require: columns[1], status: "pending", address_status: "address_waiting", receiver_postcode: columns[2], receiver_addr: columns[3], receiver_name: columns[4], receiver_phone: columns[5]
	  					else
	  						e.update deal_require: columns[1], status: "pending", address_status: "address_waiting"
	  					end
	  				end
	  			end
	  		end
	  		Batch.where(id: batches).update_all status: "pending" if !batches.blank?
	  	end
	  end
  end
end
