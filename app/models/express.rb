class Express < ApplicationRecord
  belongs_to :batch

  enum address_status: {address_waiting: 'address_waiting', address_success: 'address_success', address_failed: 'address_failed', address_noparse: 'address_noparse', address_parseing: 'address_parseing'}
  ADDRESS_STATUS_NAME = {address_waiting: '待解析', address_success: '解析成功', address_failed: '解析失败', address_noparse: '不解析', address_parseing: '解析中'}

  def address_status_name
    address_status.blank? ? "" : Order::ADDRESS_STATUS_NAME["#{address_status}".to_sym]
  end
end
