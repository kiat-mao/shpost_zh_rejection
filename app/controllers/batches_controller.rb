class BatchesController < ApplicationController
  load_and_authorize_resource :batch
  protect_from_forgery :except => [:tkzd]

  # GET /batches
  # GET /batches.json
  def index
		@batches = Batch.all
	  
    @batches_grid = initialize_grid(@batches,
         :order => 'created_at',
         :order_direction => 'desc', 
         :per_page => params[:page_size])
  end

  def done
    @batch.expresses.where(status:"pending").each do |e|
      e.update status: "done", deal_result: get_done_deal_result(e.deal_require), deal_desc: "异常", scaned_at: Time.now 
    end
    @batch.update status: "done"

    flash[:notice] = "任务已完成" 
    respond_to do |format|
      format.html { redirect_to request.referer }
      format.json { head :no_content }
    end
  end

  def get_done_deal_result(deal_require)
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