class Batch < ApplicationRecord
	has_many :expresses

	enum status: {waiting: 'waiting', done: 'done'}
  STATUS_NAME = {waiting: '待上传', done: '处理完成'}

  def status_name
    status.blank? ? "" : Batch::STATUS_NAME["#{status}".to_sym]
  end

  def all_expresses_done
  	if self.expresses.where(status: "pending").count > 0
	  	return false
	  else
	  	return true
	  end
  end
end
