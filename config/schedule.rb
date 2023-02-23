every :day, :at => '0:01am' do
  runner "Express.to_zh_first_file"
  runner "Express.from_zh_first_file"
  runner "Express.from_zh_second_file"
  runner "Express.to_zh_second_file"
end

