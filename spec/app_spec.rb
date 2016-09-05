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
  end

  before :each do
    Post.delete_all
    @now = Time.now.utc
  end

  describe '/yyyy/dd/mm/xx' do
    context 'when post is visible' do
      it 'should show post matching slug' do
        Post.create!(@valid_params.merge(
          slug: "this-is-slug",
          body: "this is body",
          datetime: Time.utc(1234, 12, 12),
          visible: true
        ))
        get '/1234/12/12/this-is-slug'
        expect(last_response.body).to include("this is body")
      end

      it 'should show post matching id' do
        post = Post.create!(@valid_params.merge(
          slug: nil,
          datetime: Time.utc(1234, 12, 12),
          body: "this is body",
          visible: true
        ))
        get "/1234/12/12/#{post.id}"
        expect(last_response.body).to include("this is body")
      end
    end

    context 'when post is invisible' do
      it 'should not show post matching slug' do
        Post.create!(@valid_params.merge(
          slug: "this-is-slug",
          datetime: Time.utc(1234, 12, 12),
          visible: false
        ))
        get '/1234/12/12/this-is-slug'
        expect(last_response).to be_not_found
      end
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
      post = Post.create!(title: "TITLE", slug: "SLUG", body: "BODY")
      authorize 'jhon', 'passw0rd'
      get "/_edit/#{post.id}"
      expect(last_response).to be_ok
      expect(last_response.body).to include("TITLE")
    end
  end

  describe '/_edit/:id' do
    it 'should show editor' do
      authorize 'jhon', 'passw0rd'
      get '/_edit/'
      expect(last_response).to be_ok
      expect(last_response.body).to include("form")
    end
  end

  describe '/_save (Preview)' do
    it 'should not create a record' do
      count = Post.count

      authorize 'jhon', 'passw0rd'
      post '/_save', @valid_params.merge(submit_by: "Preview")

      expect(Post.count).to eq(count)
    end
  end

  describe '/_save (Save)' do
    it 'creates a draft post' do
      count = Post.count
      authorize 'jhon', 'passw0rd'
      post '/_save', @valid_params.merge(submit_by: "Save")
      expect(Post.count).to eq(count+1)
      expect(last_response).to be_redirect

      new_post = Post.order("id desc").first
      expect(new_post.title).to eq("TITLE")
      expect(new_post.slug).to eq("SLUG")
      expect(new_post.body).to eq("BODY")
      expect(new_post.visible).to eq(false)
      expect(new_post.published_at).to be_nil
      expect(last_response.header["Location"]).to(
        end_with("/_draft/#{new_post.id}"))
    end

    it 'creates a public post' do
      count = Post.count
      Timecop.freeze(@now) do
        authorize 'jhon', 'passw0rd'
        post '/_save', @valid_params.merge(visible: "y", submit_by: "Save")
      end
      expect(Post.count).to eq(count+1)
      expect(last_response).to be_redirect

      new_post = Post.order("id desc").first
      expect(new_post.title).to eq("TITLE")
      expect(new_post.slug).to eq("SLUG")
      expect(new_post.body).to eq("BODY")
      expect(new_post.visible).to eq(true)
      expect(new_post.published_at).to eq(@now)
      expect(last_response.header["Location"]).to(
        end_with(@now.strftime("/%Y/%m/%d/SLUG")))
    end

    it 'updates a post' do
      existing = Post.create!(title: "TITLE", slug: "SLUG", body: "BODY")

      authorize 'jhon', 'passw0rd'
      post '/_save', title: "TITLE2", slug: "SLUG2", body: "BODY2",
                     datetime: "1234-12-12 12:12:12",
                     visible: "y", id: existing.id, submit_by: "Save"

      updated = Post.find_by!(id: existing.id)
      expect(updated.title).to eq("TITLE2")
      expect(updated.slug).to eq("SLUG2")
      expect(updated.body).to eq("BODY2")
      expect(updated.visible).to eq(true)
      expect(last_response.header["Location"]).to(
        end_with("/1234/12/12/SLUG2"))
    end
  end
end
