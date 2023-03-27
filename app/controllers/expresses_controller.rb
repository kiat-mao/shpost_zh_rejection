class ExpressesController < ApplicationController
  load_and_authorize_resource :express
  protect_from_forgery :except => [:tkzd]

  # 邮件管理
  def index
  	if !params[:batch_id].blank?
  		@expresses = Express.where(batch_id: params[:batch_id]).order("scaned_at desc, express_no asc")
  	end
  	
    @expresses_grid = initialize_grid(@expresses,
         :per_page => params[:page_size])
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

  # 打印
  def tkzd
  	@result = []
  	@express_id = params[:express_id]
 	
  	if !@express_id.blank?
  		@result << Express.find(@express_id)
  	else
	  	if !params[:selected].blank?
	      selected = params[:selected].split(",")
	       
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
  			batch.expresses.create! express_no: s, scaned_at: Time.now, status: "waiting", operator1: current_user.id
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
  		if !@express.address_status.eql?"address_success"
  			@deal_require = "address_failed"
  		else
  			@deal_require = @express.deal_require
  			# 03退回卡厂,05退回卡厂成功
  			if @deal_require.eql?"03"
  				@express.update status: "done", deal_result: "05", operator2: current_user.id, scaned_at: Time.now
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
		# interface_sender = XydInterfaceSender.order_create_interface_sender_initialize(express)
		# interface_sender.interface_send(10)
		# msg = XydInterfaceSender.get_response_message(interface_sender)
		express.update new_express_no: "0000004", route_code: "0000004"
		msg = "成功"
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

	
	private

	def express_params
    params.require(:express).permit(:receiver_province, :receiver_city, :receiver_district, :receiver_addr)
  end

end
