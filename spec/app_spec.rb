require 'spec_helper'

describe 'NLog2' do
  include Rack::Test::Methods
  def app
    @app ||= NLog2
  end

  before :all do
    Post.delete_all
  end

  before :each do
    @now = Time.now.utc
  end

  describe '/_edit' do
    it 'should redirect to /_edit/' do
      get '/_edit'
      expect(last_response).to be_redirect
      expect(last_response.header["Location"]).to end_with("/_edit/")
    end
  end

  describe '/_edit/' do
    it 'should show editor' do
      post = Post.create!(title: "TITLE", slug: "SLUG", body: "BODY")
      get "/_edit/#{post.id}"
      expect(last_response).to be_ok
      expect(last_response.body).to include("TITLE")
    end
  end

  describe '/_edit/:id' do
    it 'should show editor' do
      get '/_edit/'
      expect(last_response).to be_ok
      expect(last_response.body).to include("form")
    end
  end

  describe '/_save (Preview)' do
    it 'should not create a record' do
      count = Post.count

      post '/_save', title: "TITLE", slug: "SLUG", body: "BODY",
                     submit_by: "Preview"

      expect(Post.count).to eq(count)
    end
  end

  describe '/_save (Save)' do
    it 'creates a draft post' do
      count = Post.count
      post '/_save', title: "TITLE", slug: "SLUG", body: "BODY",
                     submit_by: "Save"
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
        post '/_save', title: "TITLE", slug: "SLUG", body: "BODY",
                       visible: "y", submit_by: "Save"
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
      #p ok: existing.save!, existing: existing
      #p count: Post.count
      post '/_save', title: "TITLE2", slug: "SLUG2", body: "BODY2",
                     visible: "y", id: existing.id, submit_by: "Save"

      updated = Post.find_by!(id: existing.id)
      expect(updated.title).to eq("TITLE2")
      expect(updated.slug).to eq("SLUG2")
      expect(updated.body).to eq("BODY2")
      expect(updated.visible).to eq(true)
      expect(last_response.header["Location"]).to(
        end_with(@now.strftime("/%Y/%m/%d/SLUG2")))
    end
  end
end
