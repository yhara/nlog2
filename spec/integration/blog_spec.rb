require 'spec_helper'

describe 'NLog2', type: :feature do
  include NLog2::IntegrationTest

  before :all do
    Capybara.app = app
    @valid_params = {
      title: "TITLE",
      slug: "SLUG",
      body: "BODY",
      datetime: Time.now.to_s,
    }
    @valid_posted = @valid_params.merge(published_at: Time.now)
    @category1 = Category.find_or_create_by!(name: "Category1")
    @cat_diary = Category.find_or_create_by!(name: "Diary")
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

    it 'should not show future post' do
      Post.create!(@valid_posted.merge(datetime: Time.now + 3600,
                                       title: "FUTURE POST"))
      visit '/'
      expect(page).not_to have_content("FUTURE POST")
    end

    context 'when category is given' do
      it 'should show the posts in the category' do
        Post.create!(@valid_posted.merge(title: "POST1", category: @category1))
        Post.create!(@valid_posted.merge(title: "POST2"))
        visit "/?category=#{@category1.name}"
        expect(page).to have_content("POST1")
        expect(page).not_to have_content("POST2")
      end
    end
  end

  describe '/_list' do
    it 'should show the list of recent posts' do
      Post.create!(@valid_posted)
      visit '/_list'
      expect(page).to have_content("TITLE")
    end

    context 'when category is given' do
      it 'should show the posts in the category' do
        Post.create!(@valid_posted.merge(title: "POST1", category: @category1))
        Post.create!(@valid_posted.merge(title: "POST2"))
        visit "/_list?category=#{@category1.name}"
        expect(page).to have_content("POST1")
        expect(page).not_to have_content("POST2")
      end
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

    context 'when ?nodiary=1' do
      it 'should exclude diary posts' do
        Post.create!(@valid_posted.merge(title: "POST1"))
        Post.create!(@valid_posted.merge(title: "POST2", category: @cat_diary))
        visit '/_feed.xml?nodiary=1'
        # Should include a post without category
        expect(page).to have_content("POST1")
        expect(page).not_to have_content("POST2")
      end
    end
  end

  describe 'articles' do
    it 'should be accessible without date' do
      Article.create!(@valid_posted)
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
