require 'spec_helper'

describe 'Post' do
  before :all do
    @category1 = Category.find_or_create_by!(name: "Category1")
    @valid_posted = {
      title: "TITLE",
      slug: "SLUG",
      body: "BODY",
      datetime: Time.now.to_s,
      published_at: Time.now,
      category: @category1,
    }
  end

  before :each do
    Post.delete_all
  end

  describe '#slug_or_id' do
    it 'should return id when slug is ""' do
      post = Post.create!(@valid_posted.merge(slug: ""))
      expect(post.slug_or_id).to match(/\A\d+\z/)
    end
  end

  describe '#path_to_show' do
    it "should format post url in editor's timezone" do
      post = Post.create!(@valid_posted.merge(
        datetime: '2016-10-07 23:00:00 UTC', slug: 'tz-post'))
      expect(post.path_to_show).to eq('/2016/10/08/tz-post')
    end
  end
end
