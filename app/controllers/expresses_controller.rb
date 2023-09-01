class ExpressesController < ApplicationController
  load_and_authorize_resource :express
  protect_from_forgery :except => [:tkzd]

  # 邮件管理
  def index
  	if !params[:batch_id].blank?
  		@expresses = Express.where(batch_id: params[:batch_id]).order("scaned_at desc")
  	end
  	
    @expresses_grid = initialize_grid(@expresses.order("scaned_at desc"),
      :per_page => params[:page_size],
      name: 'expresses'
      # ,
      # :enable_export_to_csv => true,
      # :csv_file_name => 'expresses',
      # :csv_encoding => 'gbk'
      )
    # export_grid_if_requested
  end

  # 异常邮件处理
  def anomaly_index
		@expresses = Express.where(anomaly: true, removed: false).order("scaned_at desc, express_no asc")
	  
    @expresses_grid = initialize_grid(@expresses,
         :per_page => params[:page_size])
  end

  def edit
  end

  def show
  end

  def update
    respond_to do |format|
      if !express_params[:receiver_province].blank? && !express_params[:receiver_city].blank? && !express_params[:receiver_district].blank?
      	if @express.update(express_params)
          format.html { redirect_to @express, notice: I18n.t('controller.update_success_notice', model: '邮件')}
          format.json { head :no_content }
        else
          format.html { render action: 'edit' }
          format.json { render json: @express.errors, status: :unprocessable_entity }
        end
      else
        flash[:alert] = "收件人省市区不能为空"
        format.html { render action: 'edit' }
        format.json { render json: @express.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if @express.status.eql?"waiting"
      @express.destroy
    else
      flash[:alert] = " 该邮件不可删除。"
    end
    respond_to do |format|
      format.html { redirect_to expresses_url }
      format.json { head :no_content }
    end
  end

  # 打印
  def tkzd
  	@result = []
  	@express_id = params[:express_id]
 	
  	if !@express_id.blank?
  		@result << Express.find(@express_id)
  	else
	  	if !params[:expresses].blank? && !params[:expresses][:selected].blank?
	      # selected = params[:expresses][:selected].split(",")
        selected = params[:expresses][:selected]
	       
	      until selected.blank? do 
	        @result += Express.where(id:selected.pop(1000))
	      end
      else
	      flash[:alert] = "请勾选需要打印的邮件"
	      respond_to do |format|
	        format.html { redirect_to request.referer }
	        format.json { head :no_content }
	      end
	    end
    end
  end

  # 退件扫描
  def return_scan
  end

  # 退件扫描,保存
  def return_save
  	if !params["batch_name"].blank? && !params["scaned_nos"].blank?
  		scaned_nos = params["scaned_nos"].split(",")
  		batch = Batch.create! name: params["batch_name"], status: "waiting", operator1: current_user.id
  		scaned_nos.each do |s|
  			batch.expresses.create! express_no: s, scaned_at: Time.now, status: "waiting", operator1: current_user.id, sender_province: "上海", sender_city: "上海", sender_district: "浦东新区", sender_addr: "上海浦东新区上海邮政120-058信箱", sender_name: "招商银行信用卡中心", sender_phone: "4008205555"
  		end
  	end
  	flash[:notice] = "保存成功"		
  	redirect_to request.referer
  end

  # 重寄扫描
  def resend_scan
  	@express = nil
  end

  # 重寄扫描,查询邮件号
  def find_resend_express_result
  	@resend_express_no = params[:resend_express_no]
  	@express = Express.find_by(status: "pending", express_no: @resend_express_no)
  	@deal_require = ""

  	if @express.blank?
  		@deal_require = "not_found"
  	else
      # 03退回卡厂,05退回卡厂成功
      if @express.deal_require.eql?"03"
        @deal_require = "03"
        @express.update status: "done", deal_result: "05", operator2: current_user.id, scaned_at: Time.now
      else
    		if !@express.address_status.eql?"address_success"
    			@deal_require = "address_failed"
    		else
    			@deal_require = @express.deal_require  			
    		end
      end
  	end
  end

  # 取新邮件号,格口码并跳转打印
  def get_new_express_no_and_print
  	deal_result = ""
  	last_express_no = params[:last_express_no]

  	if !last_express_no.blank?
  		@express = Express.find_by(status: "pending", address_status: "address_success", express_no: last_express_no)
  		@msg = express_send(@express)

  		# deal_require: 01(改址重寄), 02(原地址重寄), 03(退回卡厂)
  		# deal_result: 01(已改址重寄), 02(重寄失败), 03(已原地址寄送), 04(重寄失败), 05(退回卡厂成功), 06(退回卡厂失败)
  		if @msg.eql?"成功"
	    	if @express.deal_require.eql?"01"
	    		deal_result = "01"
	    	elsif @express.deal_require.eql?"02"
	    		deal_result = "03"
	    	end
	    			
	    	@express.update status:"done", deal_result: deal_result, operator2: current_user.id, scaned_at: Time.now
	    end
	  end
  end

  # 邮件改址
  def change_express_addr
  	@expresses = @expresses.accessible_by(current_ability).where(status: "pending").where(no_modify: false)

  	# 筛选异地邮件
    if !params[:abnormal].blank? && (params[:abnormal].eql?"true")
      @expresses = @expresses.where("(receiver_province not like (?) or ((receiver_province is ? or receiver_city is ? or receiver_district is ?) and address_status = ?) or address_status= ?) and no_modify = ?", "上海%", nil, nil, nil, "address_success", "address_failed", false)
    end

    @expresses_grid = initialize_grid(@expresses,
         :order => 'express_no',
         :order_direction => 'asc', 
         :per_page => params[:page_size])
  end

  # 邮件改址,无需修改
  def set_no_modify
    if params[:grid] && params[:grid][:selected]
      selected = params[:grid][:selected]
         
      until selected.blank? do 
        expresses = Express.where(id:selected.pop(1000)).where.not(receiver_province: nil).where.not(receiver_city: nil).where.not(receiver_district: nil)
        expresses.each do |o|
          o.update no_modify: true, address_status: "address_success"
        end
      end
      flash[:notice] = "已设置成功"      
    else
      flash[:alert] = "请勾选邮件"
    end   
    
    respond_to do |format|
      format.html { redirect_to request.referer }
      format.json { head :no_content }
    end
  end

	# 发送新一代接口，获取邮件号，格口码,返回'成功'或出错信息
	def express_send(express)
		interface_sender = XydInterfaceSender.order_create_interface_sender_initialize(express)
		interface_sender.interface_send(10)
		msg = XydInterfaceSender.get_response_message(interface_sender)
		# express.update new_express_no: "0000004", route_code: "0000004"
		# msg = "成功"
		return msg			
	end

	# 异常邮件处理,异常处理完成
	def anomaly_done
		expresses = []

		if params[:grid] && params[:grid][:selected]
  		selected = params[:grid][:selected]
	       
	    until selected.blank? do 
	      expresses = Express.where(id:selected.pop(1000))
	      expresses.each do |e|
	      	e.update status: "cancelled", removed: true
	      end
	    end
	    flash[:notice] = "异常处理完成"	    
	  else
	  	flash[:alert] = "请勾选邮件"
	  end   
	  
  	respond_to do |format|
      format.html { redirect_to request.referer }
      format.json { head :no_content }
    end
	end

  def express_export
    expresses = filter_expresses(@expresses,params)
    
    if expresses.blank?
      flash[:alert] = "无数据"
      redirect_to :action => 'index'
    else
      send_data(express_xls_content_for(expresses.order("scaned_at desc")), :type => "text/excel;charset=utf-8; header=present", :filename => "数据_#{Time.now.strftime("%Y%m%d")}.xls")  
    end
  end

  def filter_expresses(expresses, params)
    start_date = nil
    end_date = nil
    expresses = expresses.left_joins(:batch)

    if !params[:expresses].blank?
      if !params[:expresses][:f].blank?
        params_f = params[:expresses][:f]
        if !params_f[:express_no].blank?
          expresses = expresses.where("express_no like ?", '%'+params_f[:express_no]+'%')
        end

        if !params_f[:scaned_at][:fr].blank?
          start_date = params_f[:scaned_at][:fr] 
          expresses = expresses.where("scaned_at >= ?", start_date)
        end

        if !params_f[:scaned_at][:to].blank?
          end_date = params_f[:scaned_at][:to].to_date+1.day 
          expresses = expresses.where("scaned_at < ?", end_date)
        end

        if !params_f['batches.name'].blank?
          batch_name = params_f['batches.name']
          expresses = expresses.where("batches.name like ?", '%'+batch_name+'%')
        end
        
        if !params_f[:anomaly][0].blank?
          expresses = expresses.where(anomaly: params_f[:anomaly][0])
        end

        if !params_f[:status].blank?
          if !params_f[:status][0].blank?
            expresses = expresses.where(status: params_f[:status][0])
          end
        end

        if !params_f[:deal_require].blank?
          if !params_f[:deal_require][0].blank?
            expresses = expresses.where(deal_require: params_f[:deal_require][0])
          end
        end

        if !params_f[:deal_result].blank?
          if !params_f[:deal_result][0].blank?
            expresses = expresses.where(deal_result: params_f[:deal_result][0])
          end
        end

        if !params_f[:new_express_no].blank?
          expresses = expresses.where("new_express_no like ?", '%'+params_f[:new_express_no]+'%')
        end

        if !params_f[:receiver_name].blank?
          expresses = expresses.where("receiver_name like ?", '%'+params_f[:receiver_name]+'%')
        end

        if !params_f[:receiver_phone].blank?
          expresses = expresses.where("receiver_phone like ?", '%'+params_f[:receiver_phone]+'%')
        end

        if !params_f[:receiver_addr].blank?
          expresses = expresses.where("receiver_addr like ?", '%'+params_f[:receiver_addr]+'%')
        end

        if !params_f[:receiver_postcode].blank?
          expresses = expresses.where("receiver_postcode like ?", '%'+params_f[:receiver_postcode]+'%')
        end

        if !params_f[:operator1].blank?
          if !params_f[:operator1][0].blank?
            expresses = expresses.where(operator1: params_f[:operator1][0])
          end
        end

        if !params_f[:operator2].blank?
          if !params_f[:operator2][0].blank?
            expresses = expresses.where(operator2: params_f[:operator2][0])
          end
        end
      end
    end
    
    return expresses
  end

  def express_xls_content_for(objs)  
    xls_report = StringIO.new  
    book = Spreadsheet::Workbook.new  
    sheet1 = book.create_worksheet :name => "数据"  
  
    blue = Spreadsheet::Format.new :color => :blue, :weight => :bold, :size => 10  
    sheet1.row(0).default_format = blue  

    sheet1.row(0).concat %w{原运单号 扫描时间 堆名 是否异常 状态 处理方式 处理结果 新运单号 收件人姓名 收件人电话 收件人地址 收件人邮编 退件扫描员 重寄扫描员} 
    count_row = 1
    objs.each do |obj|  
      sheet1[count_row,0]=obj.express_no
      sheet1[count_row,1]=obj.scaned_at.blank? ? "" : obj.scaned_at.strftime('%Y-%m-%d').to_s
      sheet1[count_row,2]=obj.batch.try(:name)
      sheet1[count_row,3]=obj.anomaly? ? "是" : "否"
      sheet1[count_row,4]=obj.status_name
      sheet1[count_row,5]=obj.deal_require.blank? ? "" : obj.deal_require_name
      sheet1[count_row,6]=obj.deal_result.blank? ? "" : obj.deal_result_name
      sheet1[count_row,7]=obj.try(:new_express_no)
      sheet1[count_row,8]=obj.try(:receiver_name)
      sheet1[count_row,9]=obj.try(:receiver_phone)
      sheet1[count_row,10]=obj.try(:receiver_addr)
      sheet1[count_row,11]=obj.try(:receiver_postcode)
      sheet1[count_row,12]=obj.operator1.blank? ? "" : User.find(obj.operator1).name
      sheet1[count_row,13]=obj.operator2.blank? ? "" : User.find(obj.operator2).name
      
      count_row += 1
    end

    book.write xls_report  
    xls_report.string  
  end
	
	private

	def express_params
    params.require(:express).permit(:receiver_province, :receiver_city, :receiver_district, :receiver_addr, :receiver_name, :receiver_phone, :receiver_postcode, :express_no, :scaned_at, :batch_id, :anomaly, :status, :deal_require, :deal_result, :new_express_no, :operator1, :operator2)
  end

end
