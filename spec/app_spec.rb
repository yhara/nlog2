require 'spec_helper'

describe 'NLog2' do
  include Rack::Test::Methods
  def app
    @app ||= NLog2
  end

  before :all do
    @valid_params = {
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
      get '/'
      expect(last_response.body).to include("BODY")
    end
  end

  describe '/_list' do
    it 'should show the list of recent posts' do
      Post.create!(@valid_posted)
      get '/'
      expect(last_response.body).to include("TITLE")
    end
  end

  describe '/yyyy/dd/mm/xx' do
    it 'should show post matching slug' do
      Post.create!(@valid_posted.merge(
        slug: "this-is-slug",
        body: "this is body",
        datetime: Time.utc(1234, 12, 12),
      ))
      get '/1234/12/12/this-is-slug'
      expect(last_response.body).to include("this is body")
    end

    it 'should show post matching id' do
      post = Post.create!(@valid_posted.merge(
        slug: nil,
        datetime: Time.utc(1234, 12, 12),
        body: "this is body",
      ))
      get "/1234/12/12/#{post.id}"
      expect(last_response.body).to include("this is body")
    end
  end

  describe '/_feed.xml' do
    it 'should return xml' do
      Post.create!(@valid_posted)
      get '/_feed.xml'
      expect(last_response.body).to start_with("<?xml")
      expect(last_response.body).to include(@valid_params[:body])
    end
  end

  describe '/_edit (no trailing slash)' do
    it 'should redirect to /_edit/' do
      get '/_edit'
      expect(last_response).to be_redirect
      expect(last_response.header["Location"]).to end_with("/_edit/")
    end
  end

  describe '/_edit/' do
    it 'should show editor' do
      authorize 'jhon', 'passw0rd'
      get '/_edit/'
      expect(last_response).to be_ok
      expect(last_response.body).to include("form")
    end
  end

  describe '/_edit/:id' do
    it 'should show editor for the post' do
      post = Post.create!(@valid_posted)
      authorize 'jhon', 'passw0rd'
      get "/_edit/#{post.id}"
      expect(last_response).to be_ok
      expect(last_response.body).to include(@valid_posted[:title])
    end
  end

  describe '/_edit (Preview)' do
    it 'should not create a record' do
      count = Post.count

      authorize 'jhon', 'passw0rd'
      post '/_edit', @valid_params.merge(submit_by: "Preview")

      expect(Post.count).to eq(count)
    end

    it 'should not raise error when failed to parse datetime' do
      authorize 'jhon', 'passw0rd'
      post '/_edit', @valid_params.merge(datetime: "asdf", submit_by: "Preview")
    end
  end

  describe '/_edit (Save)' do
    it 'creates a public post' do
      count = Post.count
      Timecop.freeze(@now) do
        authorize 'jhon', 'passw0rd'
        post '/_edit', @valid_params.merge(submit_by: "Save")
      end
      expect(Post.count).to eq(count+1)
      expect(last_response).to be_redirect

      new_post = Post.order("id desc").first
      expect(new_post.title).to eq("TITLE")
      expect(new_post.slug).to eq("SLUG")
      expect(new_post.body).to eq("BODY")
      expect(new_post.published_at).to eq(@now)
      expect(last_response.header["Location"]).to(
        end_with(@now.in_time_zone.strftime("/%Y/%m/%d/SLUG")))
    end

    it 'updates a post' do
      existing = Post.create!(@valid_posted)

      authorize 'jhon', 'passw0rd'
      post '/_edit', title: "TITLE2", slug: "SLUG2", body: "BODY2",
                     datetime: "1234-12-12 12:12:12",
                     id: existing.id, submit_by: "Save"

      updated = Post.find_by!(id: existing.id)
      expect(updated.title).to eq("TITLE2")
      expect(updated.slug).to eq("SLUG2")
      expect(updated.body).to eq("BODY2")
      expect(last_response.header["Location"]).to(
        end_with("/1234/12/12/SLUG2"))
    end

    it 'should not raise error when failed to parse datetime' do
      count = Post.count

      authorize 'jhon', 'passw0rd'
      post '/_edit', @valid_params.merge(datetime: "asdf", submit_by: "Preview")

      expect(Post.count).to eq(count)
    end
  end

  context 'when timezone is set' do
    describe 'Post' do
      it 'should format post url in that timezone' do
        post = Post.create!(@valid_posted.merge(
          datetime: '2016-10-07 23:00:00 UTC', slug: 'tz-post'))
        expect(post.path_to_show).to eq('/2016/10/08/tz-post')
      end
    end

    describe 'post url' do
      it 'should have a date in that timezone' do
        post = Post.create!(@valid_posted.merge(
          datetime: '2016-10-07 23:00:00 UTC', slug: 'tz-test'))
        get '/2016/10/08/tz-test'
        expect(last_response.body).to include("BODY")
      end
    end

    describe 'editor' do
      it 'should parse datetime in that timezone' do
        authorize 'jhon', 'passw0rd'
        post '/_edit', @valid_params.merge(datetime: '1234-12-12 00:00:00',
                                           submit_by: "Save")
        new_post = Post.order("id desc").first
        expect(new_post.datetime).to eq(Time.parse("1234-12-12 00:00:00 +1000").utc)
      end
    end
  end
end
