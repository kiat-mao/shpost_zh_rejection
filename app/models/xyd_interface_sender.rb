class XydInterfaceSender < ActiveRecord::Base

	def self.address_parsing_schedule
		xydConfig = Rails.application.config_for(:xyd)
		expresses = Express.address_waiting
		expresses.each do |express|
			self.address_parsing_interface_sender_initialize express
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
		body["ecCompanyId"] = xydConfig[:ecCompanyId]
		body["parentId"] = xydConfig[:parentId]
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

	def self.address_parsing_interface_sender_initialize(express)
		xydConfig = Rails.application.config_for(:xyd)
		body = self.address_parsing_request_body_generate(express, xydConfig)
		args = Hash.new
		callback_params = Hash.new
		callback_params["express_id"] = express.id
		args[:callback_params] = callback_params.to_json
		args[:url] = xydConfig[:address_parsing_url]
		args[:parent_id] = express.id
		# args[:unit_id] = order.unit_id
		InterfaceSender.interface_sender_initialize("xyd_address_parsing", body, args)
		express.update!(address_status: :address_parseing)
	end

	def self.address_parsing_request_body_generate(express, xydConfig)
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
		address["address"] = express.receiver_addr
		addresses << address
		body["addresses"] = addresses
		params["body"] = body

		params.to_json
	end

	def self.address_parsing_callback_method(response, callback_params)
		puts 'address_parsing_callback_method!!'
		express_id = nil
		prov_name = nil
		city_name = nil
		county_name = nil
		if callback_params.nil?
			puts 'callback_params:'
		else
			puts 'callback_params:' + callback_params.to_s
			express_id = callback_params["express_id"]
		end
		if response.nil?
			puts 'response:'
			return false
		else
			puts 'response:' + response
			resJSON = JSON.parse response
			resHead = resJSON["head"]
			error_code = resHead["error_code"]
			if (error_code=='0')
				resBody = resJSON["body"]
				results = resBody["results"]
				address = results[0]
				res_code = address["resCode"]
				if res_code == '0000'
					prov_name = address["provName"]
					city_name = address["cityName"]
					county_name = address["countyName"]
					puts '省:' + prov_name.to_s
					puts '市:' + city_name.to_s
					puts '区:' + county_name.to_s
					if (!express_id.nil? && express_id.is_a?(Numeric))
						if (!prov_name.nil? && !city_name.nil? && !county_name.nil? && !prov_name.empty? && !city_name.empty? && !county_name.empty?)
							Express.find(express_id).update!(receiver_province: prov_name, receiver_city: city_name, receiver_district: county_name, address_status: :address_success)
						else
							# TODO
							Express.find(express_id).update!(receiver_province: prov_name, receiver_city: city_name, receiver_district: county_name, address_status: :address_failed)
						end
						return true
					end
				else
					if (!express_id.nil? && express_id.is_a?(Numeric))
						Express.find(express_id).update!(address_status: :address_failed)
						return true
					end
				end
			else
				puts "address parsing failed, error_code:" + error_code.to_s
				if (!express_id.nil? && express_id.is_a?(Numeric))
					Express.find(express_id).update!(address_status: :address_failed)
					return true
				end
			end
			return false
		end
	end
end