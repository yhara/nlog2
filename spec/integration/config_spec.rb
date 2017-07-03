require 'spec_helper'

describe 'NLog2 config', type: :feature do
  include NLog2::IntegrationTest

  before :all do
    Capybara.app = app
  end

  describe '/_admin/config/' do
    it 'should redirect to /_admin/config' do
      login
      visit '/_admin/config/'
      expect(page.current_path).to end_with("/_admin/config")
    end
  end

  context 'Category' do
    before :each do
      Category.delete_all
    end

    describe '/_admin/config' do
      it 'should show list of categories' do
        Category.create!(name: "Category1")

        login
        visit '/_admin/config'
        expect(page).to have_content("Category1")
      end
    end

    describe 'add button' do
      it 'should create new category' do
        login
        visit '/_admin/config'
        find("form.create-category input[name=name]").set("Category1")
        click_button "create"

        expect(Category.find_by(name: "Category1")).to be_truthy
      end
    end

    describe 'rename button' do
      it 'should update that category' do
        Category.create!(name: "Category1")
        login
        visit '/_admin/config'
        find("form.update-category input[name=name]").set("Category1")
        click_button "delete(no confirm)", disabled: true

        expect(Category.find_by(name: "Category1")).to be_nil
      end
    end

    describe 'delete button' do
      it 'should delete that category' do
        Category.create!(name: "Category1")
        login
        visit '/_admin/config'
        click_button "delete(no confirm)", disabled: true

        expect(Category.find_by(name: "Category1")).to be_nil
      end
    end
  end
end
