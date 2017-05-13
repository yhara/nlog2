require 'spec_helper'

describe 'NLog2', type: :feature do
  include NLog2::IntegrationTest

  before :all do
    Capybara.app = app
    @valid_params = {
      permanent: false,
      title: "TITLE",
      slug: "SLUG",
      body: "BODY",
      datetime: Time.now.to_s,
    }
    @valid_posted = @valid_params.merge(published_at: Time.now)
  end

  before :each do
    Post.delete_all
  end

  describe '/' do
    it 'should show recent posts' do
      Post.create!(@valid_posted)
      visit '/'
      expect(page).to have_content("BODY")
    end
  end

  describe '/_list' do
    it 'should show the list of recent posts' do
      Post.create!(@valid_posted)
      visit '/'
      expect(page).to have_content("TITLE")
    end

    it 'should not show future post' do
      Post.create!(@valid_posted.merge(datetime: Time.now + 3600,
                                       title: "FUTURE POST"))
      visit '/'
      expect(page).not_to have_content("FUTURE POST")
    end
  end

  describe '/yyyy/dd/mm/xx' do
    it 'should show post matching slug' do
      Post.create!(@valid_posted.merge(
        slug: "this-is-slug",
        body: "this is body",
        datetime: Time.utc(1234, 12, 12),
      ))
      visit '/1234/12/12/this-is-slug'
      expect(page).to have_content("this is body")
    end

    it 'should show post matching id' do
      post = Post.create!(@valid_posted.merge(
        slug: nil,
        datetime: Time.utc(1234, 12, 12),
        body: "this is body",
      ))
      visit "/1234/12/12/#{post.id}"
      expect(page).to have_content("this is body")
    end

    it 'should not show future post' do
      Post.create!(@valid_posted.merge(
        slug: "future-post",
        datetime: Time.utc(9999, 12, 12)))
      visit '/9999/12/12/future-post'
      expect(page.status_code).to eq(404)
    end
  end

  describe '/_feed.xml' do
    it 'should return xml' do
      Post.create!(@valid_posted)
      visit '/_feed.xml'
      expect(page.body).to start_with("<?xml")
      expect(page).to have_content(@valid_params[:body])
    end

    it 'should not include future post' do
      Post.create!(@valid_posted.merge(datetime: Time.now + 3600,
                                       title: "FUTURE POST"))
      visit '/_feed.xml'
      expect(page).not_to have_content("FUTURE POST")
    end
  end

  describe 'permanent pages' do
    it 'should be accessible without date' do
      Post.create!(@valid_posted.merge(permanent: true))
      visit "/SLUG"
      expect(page).to have_content("BODY")
    end
  end

  context 'when timezone is set' do
    describe 'post url' do
      it 'should have a date in that timezone' do
        post = Post.create!(@valid_posted.merge(
          datetime: '2016-10-07 23:00:00 UTC', slug: 'tz-test'))
        visit '/2016/10/08/tz-test'
        expect(page).to have_content("BODY")
      end
    end
  end
end
