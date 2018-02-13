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

  describe 'validation' do
    it 'should check slug does not start with _' do
      article = Article.new(@valid_posted.merge(slug: '_FOO'))
      expect(article.valid?).to be(false)
    end
  end

  describe '#path_to_show' do
    it 'should use slag as url' do
      article = Article.create!(@valid_posted)
      expect(article.path_to_show).to eq('/SLUG')
    end
  end
end
