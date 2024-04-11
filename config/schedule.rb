# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron
env :PATH, ENV['PATH']
# Example:
#
set :output, "./log/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

every 2.minutes do
  runner "XydInterfaceSender.address_parsing_schedule"
end

every 2.minutes do 
  runner "XydInterfaceSender.order_create_by_waybill_no_schedule"
end

every 2.minutes do
  runner "InterfaceSender.schedule_send"
end

every 30.minutes do 
  runner "FileHelper.from_jbda_file"
  runner "FileHelper.from_jd_file"
end

every :day, :at => '0:01am' do
  runner "FileHelper.to_zh_first_file"
  runner "FileHelper.from_zh_first_file"
  runner "FileHelper.from_zh_second_file"
  runner "FileHelper.to_zh_second_file"
end

every 30.minutes do 
	runner "Order.get_jbda_orders_by_date"
	runner "Order.get_jd_orders_by_date"
end