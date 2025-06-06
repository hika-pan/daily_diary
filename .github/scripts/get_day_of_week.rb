require 'date'

# 指定された日付の曜日（日本語）を返します。
def get_day_of_week_japanese(year, month, day)
  begin
    date = Date.new(year, month, day)
    # RubyのDate#wdayは 0:日, 1:月, ..., 6:土
    dow_names = ["日", "月", "火", "水", "木", "金", "土"]
    return dow_names[date.wday]
  rescue ArgumentError
    return "Invalid Date"
  end
end

# コマンドライン引数を処理
if ARGV.length != 3
  warn "Usage: ruby get_day_of_week.rb <year> <month> <day>"
  exit 1
end

begin
  year = ARGV[0].to_i
  month = ARGV[1].to_i
  day = ARGV[2].to_i
rescue ArgumentError
  warn "Error: Year, month, and day must be integers."
  exit 1
end

puts get_day_of_week_japanese(year, month, day)
