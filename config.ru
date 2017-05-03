require "bundler/setup"
require_relative "app/nlog2.rb"
require_relative "app/post.rb"

NLog2.load_config("#{__dir__}/config/nlog2.yml")

run NLog2
