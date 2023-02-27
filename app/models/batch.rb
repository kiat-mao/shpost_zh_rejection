class Batch < ApplicationRecord
	has_many :expresses

	enum status: {waiting: 'waiting', pending: 'pending', done: 'done'}
  STATUS_NAME = {waiting: '待上传', pending: '待处理', done: '处理完成'}

  def status_name
    status.blank? ? "" : Batch::STATUS_NAME["#{status}".to_sym]
  end

  def can_done
  	if self.expresses.where(status: "pending").count > 0
	  	return true
	  else
	  	return false
	  end
  end
end
