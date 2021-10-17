# NLog2

nlog2 is a simple blog engine/cms for me, written in Ruby and Sinatra.

(Rather than using it as-is, it is preferred to fork this repo and
customize it for you because some of the features may not make sense to you.
I'd like to keep the code simple enough to do that.)

## Features

- Permanent pages (accessible without date, like http://yhara.jp/About)

## Requirements

- Ruby (tested with 3.0)

## Install

1. git clone
1. Configuration
  1. cp config/nlog2.yml.example config/nlog2.yml
  1. Edit config/nlog2.yml
  1. `bundle exec rake config:hash_password`
1. Setup
  1. `bundle install`
  1. `bundle exec rake db:migrate RACK_ENV=production`
1. Run
  1. `bundle exec rackup -e production`
  1. `open http://localhost:9292/_edit`

## Run test

1. rake db:migrate RACK_ENV=test
1. bundle exec rspec

## License

MIT

## Contact

https://github.com/yhara/nlog2
