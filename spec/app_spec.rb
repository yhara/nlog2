require 'spec_helper'

describe 'NLog2', type: :feature do
  def app
    @app ||= NLog2
  end

  def login(username='jhon', password='passw0rd')
    encoded_login = ["#{username}:#{password}"].pack('m*')
    page.driver.header 'Authorization', "Basic #{encoded_login}"
  end

  def fill_editor(params)
    check "permanent" if params[:permanent]
    fill_in "title", with: params[:title]
    fill_in "slug", with: params[:slug]
    fill_in "body", with: params[:body]
    fill_in "datetime", with: params[:datetime]
  end

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
    @now = Time.now.utc
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

  describe '/_edit (no trailing slash)' do
    it 'should redirect to /_edit/' do
      visit '/_edit'
      expect(page.current_path).to end_with("/_edit/")
    end
  end

  describe '/_edit/' do
    it 'should show editor' do
      login
      visit '/_edit/'
      expect(page).to have_selector("form")
    end
  end

  describe '/_edit/:id' do
    it 'should show editor for the post' do
      post = Post.create!(@valid_posted)
      login
      visit "/_edit/#{post.id}"
      expect(page).to have_selector("input[name='title'][value='#{@valid_posted[:title]}']")
    end
  end

  describe '/_edit (Preview)' do
    it 'should not create a record' do
      count = Post.count

      login
      visit '/_edit/'
      fill_editor @valid_params
      click_button "Preview"

      expect(Post.count).to eq(count)
    end

    it 'should not raise error when failed to parse datetime' do
      login
      visit '/_edit/'
      expect {
        fill_editor @valid_params.merge(datetime: "asdf")
        click_button "Preview"
      }.not_to raise_error
    end
  end

  describe '/_edit (Save)' do
    it 'creates a public post' do
      count = Post.count
      Timecop.freeze(@now) do
        login
        visit '/_edit/'
        fill_editor @valid_params
        click_button "Save"
      end
      expect(Post.count).to eq(count+1)

      new_post = Post.order("id desc").first
      expect(new_post.title).to eq("TITLE")
      expect(new_post.slug).to eq("SLUG")
      expect(new_post.body).to eq("BODY")
      expect(new_post.published_at).to eq(@now)
      expect(page.current_path).to(
        end_with(@now.in_time_zone.strftime("/%Y/%m/%d/SLUG")))
    end

    it 'updates a post' do
      existing = Post.create!(@valid_posted)

      login
      visit "/_edit/#{existing.id}"
      fill_editor title: "TITLE2", slug: "SLUG2", body: "BODY2",
                  datetime: "1234-12-12 12:12:12", permanent: false
      click_button "Save"

      updated = Post.find_by!(id: existing.id)
      expect(updated.title).to eq("TITLE2")
      expect(updated.slug).to eq("SLUG2")
      expect(updated.body).to eq("BODY2")
      expect(page.current_path).to(end_with("/1234/12/12/SLUG2"))
    end

    it 'should redirect to url without date when post is permanent' do
      login
      visit '/_edit'
      fill_editor @valid_params.merge(permanent: true)
      click_button "Save"

      expect(page.current_path).not_to match(%r{/\d\d\d\d/\d\d/\d\d})
      expect(page.current_path).to end_with("SLUG")
    end

    context 'when saving future post' do
      it 'should show edit page again' do
        login
        visit '/_edit'
        fill_editor @valid_params.merge(datetime: (Time.now + 3600).to_s)
        click_button "Save"

        expect(page.current_path).to eq("/_edit")
      end
    end

    it 'should not raise error when failed to parse datetime' do
      login
      visit '/_edit'
      expect {
        fill_editor @valid_params.merge(datetime: "asdf")
        click_button "Preview"
      }.not_to raise_error
    end

    it 'should not create a post when validation is failed' do
      count = Post.count

      login
      visit '/_edit'
      fill_editor @valid_params.merge(body: "")
      click_button "Save"

      expect(Post.count).to eq(count)
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

    describe 'editor' do
      it 'should parse datetime in that timezone' do
        login
        visit '/_edit'
        fill_editor @valid_params.merge(datetime: '1234-12-12 00:00:00')
        click_button "Save"
                   
        new_post = Post.order("id desc").first
        expect(new_post.datetime).to eq(Time.parse("1234-12-12 00:00:00 +1000").utc)
      end
    end
  end
end
