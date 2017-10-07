require 'spec_helper'

describe 'NLog2 edit', type: :feature do
  include NLog2::IntegrationTest

  def fill_editor(params)
    check "permanent" if params[:permanent]
    fill_in "title", with: params[:title]
    fill_in "slug", with: params[:slug]
    fill_in "body", with: params[:body]
    fill_in "datetime", with: params[:datetime]
    select params[:category].name, from: "category"
  end

  before :all do
    Capybara.app = app
    Category.delete_all
    @category1 = Category.create!(name: "Category1")
    @category2 = Category.create!(name: "Category2")
    @valid_params = {
      permanent: false,
      title: "TITLE",
      slug: "SLUG",
      body: "BODY",
      datetime: Time.now.to_s,
      category: @category1,
    }
    @valid_posted = @valid_params.merge(published_at: Time.now).except(:permanent)
  end

  before :each do
    Post.delete_all
    @now = Time.now.utc
  end

  describe '/_admin/edit (no trailing slash)' do
    it 'should redirect to /_admin/edit/' do
      login
      visit '/_admin/edit'
      expect(page.current_path).to end_with("/_admin/edit/")
    end
  end

  describe '/_admin/edit/' do
    it 'should show editor' do
      login
      visit '/_admin/edit/'
      expect(page).to have_selector("form")
    end

    it 'should not show editor without login' do
      visit '/_admin/edit/'
      expect(page).not_to have_selector("form")
    end
  end

  describe '/_admin/edit/:id' do
    it 'should show editor for the post' do
      post = Post.create!(@valid_posted)
      login
      visit "/_admin/edit/#{post.id}"
      expect(page).to have_selector("input[name='title'][value='#{@valid_posted[:title]}']")
    end
  end

  describe '/_admin/edit (Preview)' do
    it 'should set current value to the form' do
      count = Post.count

      login
      visit '/_admin/edit/'
      fill_editor @valid_params.merge(category: @category2)
      click_button "Preview"

      expect(page).to have_content(@valid_params[:body])
      expect(find_field("category").value).to eq(@category2.id.to_s)
    end

    it 'should not create a record' do
      count = Post.count

      login
      visit '/_admin/edit/'
      fill_editor @valid_params
      click_button "Preview"

      expect(Post.count).to eq(count)
    end

    it 'should not raise an exception when failed to parse datetime' do
      login
      visit '/_admin/edit/'
      expect {
        fill_editor @valid_params.merge(datetime: "asdf")
        click_button "Preview"
      }.not_to raise_error
    end
  end

  describe '/_admin/edit (Save)' do
    it 'creates a public post' do
      count = Post.count
      Timecop.freeze(@now) do
        login
        visit '/_admin/edit/'
        fill_editor @valid_params
        click_button "Save"
      end
      expect(Post.count).to eq(count+1)

      new_post = Post.order("id desc").first
      expect(new_post.title).to eq("TITLE")
      expect(new_post.slug).to eq("SLUG")
      expect(new_post.body).to eq("BODY")
      expect(new_post.published_at).to eq(@now)
      expect(new_post.category).to eq(@category1)
      expect(page.current_path).to(
        end_with(@now.in_time_zone.strftime("/%Y/%m/%d/SLUG")))
    end

    it 'updates a post' do
      existing = Post.create!(@valid_posted)

      login
      visit "/_admin/edit/#{existing.id}"
      fill_editor title: "TITLE2", slug: "SLUG2", body: "BODY2",
                  datetime: "1234-12-12 12:12:12", permanent: false,
                  category: @category1
      click_button "Save"

      updated = Post.find_by!(id: existing.id)
      expect(updated.title).to eq("TITLE2")
      expect(updated.slug).to eq("SLUG2")
      expect(updated.body).to eq("BODY2")
      expect(page.current_path).to(end_with("/1234/12/12/SLUG2"))
    end

    it 'should set current time if blank' do
      Timecop.freeze(@now) do
        login
        visit '/_admin/edit/'
        fill_editor @valid_params.merge(datetime: "")
        click_button "Save"
      end
      new_post = Post.order("id desc").first
      expect(new_post.datetime).to eq(@now)
    end

    it 'should redirect to url without date for an article' do
      login
      visit '/_admin/edit'
      fill_editor @valid_params.merge(permanent: true)
      click_button "Save"

      expect(page.current_path).not_to match(%r{/\d\d\d\d/\d\d/\d\d})
      expect(page.current_path).to end_with("SLUG")
    end

    context 'when saving future post' do
      it 'should show edit page again' do
        login
        visit '/_admin/edit'
        fill_editor @valid_params.merge(datetime: (Time.now + 3600).to_s)
        click_button "Save"

        expect(page.current_path).to eq("/_admin/edit")
      end
    end

    it 'should not raise an exception when failed to parse datetime' do
      login
      visit '/_admin/edit'
      expect {
        fill_editor @valid_params.merge(datetime: "asdf")
        click_button "Preview"
      }.not_to raise_error
    end

    it 'should not create a post when validation is failed' do
      count = Post.count

      login
      visit '/_admin/edit'
      fill_editor @valid_params.merge(body: "")
      click_button "Save"

      expect(Post.count).to eq(count)
    end
  end

  context 'when timezone is set' do
    describe 'editor' do
      it 'should parse datetime in that timezone' do
        login
        visit '/_admin/edit'
        fill_editor @valid_params.merge(datetime: '1234-12-12 00:00:00')
        click_button "Save"
                   
        new_post = Post.order("id desc").first
        expect(new_post.datetime).to eq(Time.parse("1234-12-12 00:00:00 +1000").utc)
      end
    end
  end
end
