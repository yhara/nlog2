require 'spec_helper'

describe 'Post' do
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
  end

  describe '#slug_or_id' do
    it 'should return id when slug is ""' do
      post = Post.create!(@valid_params.merge(slug: ""))
      expect(post.slug_or_id).to match(/\A\d+\z/)
    end
  end
end
