require 'yaml'
require 'irb'
require 'securerandom'
require 'bcrypt'
require 'io/console'

$config = YAML.load_file("config/nlog2.yml")

namespace :db do
  task :load_config do
    require "./app"
  end
end

desc "Open irb with ActiveRecord"
task :console do
  require_relative "app/nlog2.rb"
  NLog2.init("#{__dir__}/config/nlog2.yml")
  ARGV.clear  # To prevent `Errno::ENOENT: No such file or directory @ rb_sysopen - console`
  IRB.start
end

desc "Run test"
task :test do
  sh "bundle exec rspec"
end

namespace :config do
  desc "Generate config[:auth][:password_hash]"
  task :hash_password do
    puts "Type password"
    pass1 = $stdin.noecho(&:gets).chomp
    puts "Type password again"
    pass2 = $stdin.noecho(&:gets).chomp
    raise "Password mismatch" unless pass1 == pass2

    puts "Add this to config[:auth][:password_hash]"
    puts BCrypt::Password.create(pass1)
  end
  
  desc "Show list of supported time zone name"
  task :zones do
    puts ActiveSupport::TimeZone::MAPPING.keys
  end
end

task default: :test
