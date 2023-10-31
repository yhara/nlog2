# Supplimental tests (controller is mainly tested by spec/integration. This
# file contains security tests that cannot be written in Capybara)
require 'rack/test'
require 'spec_helper'

describe 'NLog2 edit' do
  include Rack::Test::Methods

  def app
    NLog2
  end

  context 'when not logged in' do
    it 'should not delete image' do
      image = Image.create!(
        orig_path: "",
        thumb_path: "",
        entry_id: 0
      )
      delete "/_admin/delete_image?id=#{image.id}"
      expect(last_response.status).to eq(401)
      image.reload
    end
  end
end
