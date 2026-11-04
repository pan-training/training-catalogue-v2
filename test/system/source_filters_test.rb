require 'application_system_test_case'

class SourceFiltersTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:admin)
    @source = sources(:first_source)
  end

  test 'added filters show one value field matching their property type and are saved' do
    visit edit_source_path(@source)

    find('#add-source-filter-btn').click
    within('#source-filter-list .source-filter-form:last-child') do
      assert_selector '.source-filter-value input[type="text"]:not([disabled])', count: 1
      select 'Language', from: 'Property'
      assert_selector '.source-filter-value select:not([disabled])', count: 1
      select 'English', from: 'Value'
    end

    find('#add-source-block-filter-btn').click
    within('#source-block-list .source-filter-form:last-child') do
      select 'Date published before', from: 'Property'
      assert_selector '.source-filter-value input[type="date"]:not([disabled])', count: 1
      fill_in 'Value', with: Date.iso8601('2026-12-31')
    end

    find('#add-source-filter-btn').click
    within('#source-filter-list .source-filter-form:last-child') do
      select 'Date published after', from: 'Property'
      assert_selector '.source-filter-value input[type="date"]:not([disabled])', count: 1
      select 'Title', from: 'Property'
      assert_selector '.source-filter-value input[type="text"]:not([disabled])', count: 1
      fill_in 'Value', with: 'Example title'
    end

    assert_selector '.source-filter-value [name$="[value]"]:enabled', count: 3

    click_button 'Update Source'
    assert_text 'Source was successfully updated.'

    expected = [
      ['allow', 'language', 'en'],
      ['block', 'date_published_before', '2026-12-31'],
      ['allow', 'title', 'Example title']
    ]
    assert_equal expected.sort, @source.source_filters.reload.pluck(:mode, :property, :value).sort
  end
end
