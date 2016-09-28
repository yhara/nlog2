# NLog2

nlog2 is a simple blog engine/cms for me, written in Ruby.

## Requirements

- Ruby (tested with 2.3)

## Install

1. git clone
1. Configuration
  1. cp config/nlog2.yml.example config/nlog2.yml
  1. Edit config/nlog2.yml
  1. `bundle exec rake config:hash_password`
1. Setup
  1. `bundle install`
  1. `bundle exec rake db:migrate RAILS_ENV=production`
1. Run
  1. `bundle exec rackup -e production`
  1. `open http://localhost:9292/_edit`

## Run test

1. rake db:migrate RAILS_ENV=test
1. bundle exec rspec

## License

MIT

## Contact

https://github.com/yhara/nlog2
