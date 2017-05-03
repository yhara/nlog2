require "bundler/setup"
require_relative "app/nlog2.rb"

NLog2.init("#{__dir__}/config/nlog2.yml")

run NLog2
