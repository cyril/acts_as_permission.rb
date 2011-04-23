source "http://rubygems.org"

case ENV["MODEL_ADAPTER"]
when nil, "active_record"
  gem "sqlite3"
  gem "activerecord", :require => "active_record"
else
  raise "Unknown model adapter: #{ENV["MODEL_ADAPTER"]}"
end

gemspec
