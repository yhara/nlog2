require "sinatra/activerecord/rake"
require 'irb'

namespace :db do
  task :load_config do
    require "./app"
  end
end

desc "Open irb with ActiveRecord"
task :console do
  require "./app"
  ARGV.clear  # To prevent `Errno::ENOENT: No such file or directory @ rb_sysopen - console`
  IRB.start
end

desc "Run test"
task :test do
  sh "bundle exec rspec"
end

task default: :test
