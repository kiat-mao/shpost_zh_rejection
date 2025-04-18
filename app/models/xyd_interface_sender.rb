class XydInterfaceSender < ActiveRecord::Base

	def self.order_create_by_waybill_no_schedule
		xydConfig = Rails.application.config_for(:xyd)
		orders = Order.waiting.address_success.limit(1000)
		orders.each do |order|
			self.order_create_by_waybill_no_interface_sender_initialize order
		end
	end


	def self.address_parsing_schedule
		xydConfig = Rails.application.config_for(:xyd)
		expresses = Express.address_waiting.limit(1000)
		expresses.each do |express|
			self.address_parsing_interface_sender_initialize express
		end
		orders = Order.address_waiting.limit(1000)
		orders.each do |order|
			self.address_parsing_interface_sender_initialize order
		end
	end

	def self.order_create_interface_sender_initialize(express)
		xydConfig = Rails.application.config_for(:xyd)
		body = self.order_create_request_body_generate(express, xydConfig)
		args = Hash.new
		callback_params = Hash.new
		callback_params["express_id"] = express.id
		args[:callback_params] = callback_params.to_json
		args[:url] = xydConfig[:order_create_url]
		args[:parent_id] = express.id
		# args[:unit_id] = express.unit_id
		InterfaceSender.interface_sender_initialize("xyd_order_create", body, args)
	end

	def self.order_create_request_body_generate(express, xydConfig)
		now_time = Time.new

		params = {}
		head = {}
		head["system_name"] = xydConfig[:oc_system_name]
		head["req_time"] = now_time.strftime("%Y%m%d%H%M%S%L")
		head["req_trans_no"] = xydConfig[:oc_system_name] + head["req_time"]
		signature = Digest::MD5.hexdigest("system_name" + head["system_name"] + "req_time" + head["req_time"] + "req_trans_no" + head["req_trans_no"] + xydConfig[:oc_pwd])
		head["signature"] = signature
		params["head"] = head
		body = {}
		# body["ecCompanyId"] = xydConfig[:ecCompanyId]
		# body["parentId"] = xydConfig[:parentId]
		order = {}
		order["created_time"] = now_time.strftime("%Y-%m-%d %H:%M:%S")
		order["logistics_provider"] = xydConfig[:logistics_provider]
		order["ecommerce_no"] = xydConfig[:ecommerce_no]
		order["ecommerce_user_id"] = now_time.strftime("%Y%m%d%H%M%S%L")
		order["inner_channel"] = xydConfig[:inner_channel]
		order["logistics_order_no"] = "express" + express.id.to_s

		# 20221115 区分国药上药
		# if I18n.t('unit_no.gy').to_s == package.unit.no
		# 	if !xydConfig[:sender_no].nil?
		# 		order["sender_no"] = xydConfig[:gy_sender_no]
		# 		order["sender_type"] = '1'
		# 	end
		# 	if !o.nil? && express.freight == true
		# 		order["base_product_no"] = xydConfig[:base_product_no_3]
		# 		order["payment_mode"] = xydConfig[:payment_mode_2]
		# 	else
		# 		order["base_product_no"] = xydConfig[:base_product_no_1]
		# 	end
		# else
		if !xydConfig[:sender_no].nil?
			order["sender_no"] = xydConfig[:sender_no]
			order["sender_type"] = '1'
		end
		order["base_product_no"] = xydConfig[:base_product_no_1]
		# end
		sender = {}
		receiver = {}
		sender["name"] = express.sender_name
		sender["mobile"] = express.sender_phone
		sender["prov"] = express.sender_province
		sender["city"] = express.sender_city
		sender["county"] = express.sender_district
		sender["address"] = express.sender_addr
		receiver["name"] = express.receiver_name
		receiver["mobile"] = express.receiver_phone
		receiver["prov"] = express.receiver_province
		receiver["city"] = express.receiver_city
		receiver["county"] = express.receiver_district
		receiver["address"] = express.receiver_addr
		order["sender"] = sender
		order["receiver"] = receiver
		body["order"] = order
		params["body"] = body

		params.to_json
	end

	def self.get_response_message interfaceSender
		puts 'get_response_message!!'
		if interfaceSender == nil
			return '空的InterfaceSender对象'
		end
		# 优先显示last_response信息,其次是error_msg信息
		last_response_string = interfaceSender.last_response
		if last_response_string != nil
			last_response = JSON.parse last_response_string
			head = last_response["head"]
			if head == nil
				return '不是新一代InterfaceSender对象'
			end
			error_code = head["error_code"]
			error_msg = head["error_msg"]
			if error_code == '0'
				return '成功'
			else
				return error_msg
			end
		else
			error_message = interfaceSender.error_msg
			if (error_message == nil)
				return '未发送'
			else
				return error_message.split("\n")[0]
			end
		end
	end

	def self.order_create_callback_method(response, callback_params)
		puts 'order_create_callback_method!!'

		return false if callback_params.nil?
		
		express_id = callback_params["express_id"]

	
		if response.nil?
			puts 'response:'
			puts '运单号:'
			puts '分拣码:'
			return false
		else
			puts 'response:' + response
			resJSON = JSON.parse response
			resHead = resJSON["head"]
			error_code = resHead["error_code"]
			if (error_code=='0')
				resBody = resJSON["body"]
				express_no = resBody["wayBillNo"]
				route_code = resBody["routeCode"]
				if (! express_id.blank? && express_id.is_a?(Numeric))
					Express.find(express_id).update!(new_express_no: express_no, route_code: route_code)
					puts '运单号:' + express_no.to_s
					puts '分拣码:' + route_code.to_s
					return true
				end
			end
			return false
		end
	end

	def self.address_parsing_interface_sender_initialize(address_object)
		xydConfig = Rails.application.config_for(:xyd)
		body = self.address_parsing_request_body_generate(address_object, xydConfig)
		args = Hash.new
		callback_params = Hash.new
		callback_params["address_object_id"] = address_object.id
		callback_params["address_object_class"] = address_object.class.name
		args[:callback_params] = callback_params.to_json
		args[:url] = xydConfig[:address_parsing_url]
		args[:parent_id] = address_object.id
		args[:parent_class] = address_object.class
		# args[:unit_id] = order.unit_id
		InterfaceSender.interface_sender_initialize("xyd_address_parsing", body, args)
		address_object.address_parseing!
	end

	def self.address_parsing_request_body_generate(address_object, xydConfig)
		now_time = Time.new

		params = {}
		head = {}
		head["system_name"] = xydConfig[:ap_system_name]
		head["req_time"] = now_time.strftime("%Y%m%d%H%M%S%L")
		head["req_trans_no"] = xydConfig[:ap_system_name] + head["req_time"]
		signature = Digest::MD5.hexdigest("system_name" + head["system_name"] + "req_time" + head["req_time"] + "req_trans_no" + head["req_trans_no"] + xydConfig[:ap_pwd])
		head["signature"] = signature
		params["head"] = head
		body = {}
		body["salt"] = xydConfig[:ap_salt]
		addresses = []
		address = {}
		address["address"] = address_object.receiver_addr
		addresses << address
		body["addresses"] = addresses
		params["body"] = body

		params.to_json
	end

	def self.address_parsing_callback_method(response, callback_params)
    return false if callback_params.blank? || response.blank?

    # 判断order是否存在,是否不可修改
    begin
			if callback_params["address_object_id"].blank?
				#兼容老数据
				order ||= Express.find callback_params["express_id"]
			else
				order ||= callback_params["address_object_class"].constantize.find callback_params["address_object_id"]
			end
    rescue StandardError => e
      Rails.logger.error e.message
      return false
    ensure
			if order.address_success?
				return true
			end
      if order.no_modify
        order.address_success!
        return true
      end
    end

    resJSON = JSON.parse response
    error_code = resJSON['head']['error_code']

    if ! error_code.eql? '0'
			order.address_failed!
      return true
    end

    address = resJSON['body']['results'][0]
    res_code = address['resCode']
    if res_code.eql? '0000'
      order.receiver_province = address['provName']
      order.receiver_city = address['cityName']
      order.receiver_district = address['countyName']

      if order.receiver_province.blank? || order.receiver_city.blank?
        order.address_failed!
				return true
      end

			if order.is_a?(Express) && order.receiver_district.blank?
				order.address_failed!
				return true
			end


			order.address_success!
			return true
    else
      order.address_failed!
      false
    end
  end


	def self.order_create_by_waybill_no_interface_sender_initialize(order)
		xydConfig = Rails.application.config_for(:xyd)
		body = self.order_create_by_waybill_no_request_body_generate(order, xydConfig)
		args = Hash.new
		callback_params = Hash.new
		callback_params["order_id"] = order.id
		args[:callback_params] = callback_params.to_json
		args[:url] = xydConfig[:order_create_by_waybill_no_url]
		args[:parent_id] = order.id
		# args[:unit_id] = order.unit_id
		InterfaceSender.interface_sender_initialize("xyd_order_create_by_waybill_no", body, args)
		order.uploading!
	end

	def self.order_create_by_waybill_no_request_body_generate(order, xydConfig)
		now_time = Time.new

		params = {}
		head = {}
		head["system_name"] = xydConfig[:oc_system_name]
		head["req_time"] = now_time.strftime("%Y%m%d%H%M%S%L")
		head["req_trans_no"] = xydConfig[:oc_system_name] + head["req_time"]
		signature = Digest::MD5.hexdigest("system_name" + head["system_name"] + "req_time" + head["req_time"] + "req_trans_no" + head["req_trans_no"] + xydConfig[:oc_pwd_waybill])
		head["signature"] = signature
		params["head"] = head
		body = {}
		body["ecCompanyId"] = xydConfig[:ecCompanyId]
		body["parentId"] = xydConfig[:parentId]
		orders = {}
		orderNormals = []
		orderNormal = {}
		orderNormal["created_time"] = now_time.strftime("%Y-%m-%d %H:%M:%S")
		orderNormal["logistics_provider"] = xydConfig[:logistics_provider]
		orderNormal["ecommerce_no"] = xydConfig[:ecommerce_no]
		orderNormal["ecommerce_user_id"] = now_time.strftime("%Y%m%d%H%M%S%L")
		orderNormal["inner_channel"] = xydConfig[:inner_channel]
		orderNormal["logistics_order_no"] = "order" + order.id.to_s

		#different from order_create
		orderNormal["waybill_no"] = order.express_no
		orderNormal["one_bill_flag"] = "0"
		orderNormal["product_type"] = "1"

		orderNormal["weight"] = "70"


		if !xydConfig[:sender_no].nil?
			orderNormal["sender_no"] = xydConfig[:sender_no]
			orderNormal["sender_type"] = '1'
		end
		orderNormal["base_product_no"] = xydConfig[:base_product_no_1]
		# end
		sender = {}
		receiver = {}
		sender["name"] = order.sender_name
		sender["mobile"] = order.sender_phone
		sender["prov"] = order.sender_province
		sender["city"] = order.sender_city
		sender["county"] = order.sender_district
		sender["address"] = order.sender_addr
		sender["post_code"] = order.sender_postcode

		receiver["name"] = order.receiver_name
		receiver["mobile"] = order.receiver_phone
		receiver["prov"] = order.receiver_province
		receiver["city"] = order.receiver_city
		receiver["county"] = order.receiver_district
		receiver["address"] = order.receiver_addr
		receiver["post_code"] = order.receiver_postcode

		orderNormal["sender"] = sender
		orderNormal["receiver"] = receiver

		orderNormals << orderNormal
		orders["orderNormal"] = orderNormals
		body["orders"] = orders
		
		params["body"] = body

		params.to_json
	end

	def self.order_create_by_waybill_no_callback_method(response, callback_params)
		return false if callback_params.nil?

		order_id = callback_params["order_id"]

		if response.nil?
			return false
		else
			puts 'response:' + response
			resJSON = JSON.parse response
			resHead = resJSON["head"]
			error_code = resHead["error_code"]
			if (error_code=='0')
				resBody = resJSON["body"]
				logistic_id = resBody["logisticId"]
				route_code = resBody["routeCode"]
				if (! order_id.blank? && order_id.is_a?(Numeric))
					order = Order.find order_id
					order.logistic_id = logistic_id
					order.route_code = route_code
					order.uploaded!
					return true
				end
			elsif (error_code=='50401')
				if (! order_id.blank? && order_id.is_a?(Numeric))
					order = Order.find order_id
					order.address_failed!
					order.waiting!
					return true
				end
			end
			return false
		end
	end
end