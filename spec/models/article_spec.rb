require 'spec_helper'

describe 'Article' do
  before :all do
    @valid_posted = {
      title: "TITLE",
      slug: "SLUG",
      body: "BODY",
      datetime: Time.now.to_s,
      published_at: Time.now,
    }
  end

  before :each do
    Article.delete_all
  end

  describe '#path_to_show' do
    it 'should use slag as url' do
      article = Article.create!(@valid_posted)
      expect(article.path_to_show).to eq('/SLUG')
    end
  end
end
