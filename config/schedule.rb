every :day, :at => '0:01am' do
  runner "FileHelper.to_zh_first_file"
  runner "FileHelper.from_zh_first_file"
  runner "FileHelper.from_zh_second_file"
  runner "FileHelper.to_zh_second_file"
end

