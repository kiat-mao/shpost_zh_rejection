class OrdersController < ApplicationController
  load_and_authorize_resource :order
  protect_from_forgery :except => [:change_order_addr]

  def index
    @orders = Order.accessible_by(current_ability).all
    
    @orders_grid = initialize_grid(@orders,
         :order => 'created_at',
         :order_direction => 'desc', 
         :per_page => params[:page_size])
  end

  def edit
  end

  def show
  end

  def update
    respond_to do |format|
      if !order_params[:receiver_province].blank? && !order_params[:receiver_city].blank?
      	if @order.update(order_params)
          @order.update address_status: "address_success"
          format.html { redirect_to @order, notice: I18n.t('controller.update_success_notice', model: '邮件')}
          format.json { head :no_content }
        else
          format.html { render action: 'edit' }
          format.json { render json: @order.errors, status: :unprocessable_entity }
        end
      else
        flash[:alert] = "收件人省市不能为空"
        format.html { render action: 'edit' }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  # # 邮件改址
  # def change_order_addr
  # 	@orders = @orders.accessible_by(current_ability).where(status: "waiting").where(no_modify: false)

  # 	# 筛选异地邮件
  #   if !params[:abnormal].blank? && (params[:abnormal].eql?"true")
  #     @orders = @orders.where("(receiver_province not like (?) or ((receiver_province is ? or receiver_city is ? or receiver_district is ?) and address_status = ?) or address_status= ?) and no_modify = ?", "上海%", nil, nil, nil, "address_success", "address_failed", false)
  #   end

  #   @orders_grid = initialize_grid(@orders,
  #        :order => 'express_no',
  #        :order_direction => 'asc', 
  #        :per_page => params[:page_size])
  # end

  # 邮件改址
  def change_order_addr
    @orders = @orders.accessible_by(current_ability).where("receiver_province is ? or receiver_city is ? or address_status = ?", nil, nil, Order.address_statuses[:address_failed])

    @orders_grid = initialize_grid(@orders,
         :order => 'express_no',
         :order_direction => 'asc', 
         :per_page => params[:page_size])
  end

  # 邮件改址,无需修改
  def set_no_modify
    if params[:grid] && params[:grid][:selected]
      selected = params[:grid][:selected]
         
      until selected.blank? do 
        orders = Order.where(id:selected.pop(1000)).where.not(receiver_province: nil).where.not(receiver_city: nil).where.not(receiver_district: nil)
        orders.each do |o|
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

  private

	def order_params
    params.require(:order).permit(:receiver_province, :receiver_city, :receiver_district, :receiver_addr, :receiver_name, :receiver_phone, :receiver_postcode, :express_no, :status)
  end

  end