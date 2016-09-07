require "sinatra/activerecord/rake"
require 'irb'
require 'securerandom'
require 'digest'
require 'io/console'

$config = YAML.load_file("config/nlog2.yml")

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

namespace :config do
  desc "Generate config[:auth][:salt]"
  task :generate_salt do
    puts SecureRandom.hex(32)
  end

  desc "Generate config[:auth][:password_hash]"
  task :hash_password do
    salt = $config[:auth][:salt] || "Set salt first"
    puts "Type password"
    pass1 = $stdin.noecho(&:gets).chomp
    puts "Type password again"
    pass2 = $stdin.noecho(&:gets).chomp
    raise "Password mismatch" unless pass1 == pass2
    puts Digest::SHA256.hexdigest(pass1 + salt)
  end
  
  desc "Show list of supported time zone name"
  task :zones do
    puts ActiveSupport::TimeZone::MAPPING.keys
  end
end

task default: :test
