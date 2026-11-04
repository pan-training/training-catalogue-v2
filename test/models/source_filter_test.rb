require 'test_helper'

class SourceFilterTest < ActiveSupport::TestCase
  # All filter definitions are tested as part of the ingestor_test ingestors unit test.

  test 'string matching must be case insensitive' do
    [
      'does_match',
      'DOES_MATCH',
      'DOES_match'
    ].each do | t |
      assert(source_filters(:source_filter_title).match(OpenStruct.new({'title': t})), "failed matching: #{t}")
    end

    refute(source_filters(:source_filter_title).match(OpenStruct.new({'title': 'does_not_match'})))
  end

  test 'prefix string matching must be case insensitive' do
    [
      'does_match suffix',
      'DOES_MATCH SUFFIX',
      'DOES_match suFFix'
    ].each do | u |
      assert(source_filters(:source_filter_url_prefix).match(OpenStruct.new({'url': u})), "failed matching: #{u}")
    end

    refute(source_filters(:source_filter_url_prefix).match(OpenStruct.new({'url': 'not_a_match'})))
  end

  test 'contains string matching must be case insensitive' do
    [
      'prefix does_match suffix',
      'PREFIX DOES_MATCH SUFFIX',
      'PREFIX DOES_match suffix'
    ].each do | t |
      assert(source_filters(:source_filter_title_contains).match(OpenStruct.new({'title': t})), "failed matching: #{t}")
    end

    refute(source_filters(:source_filter_title_contains).match(OpenStruct.new({'title': 'not_a_match'})))
  end

  test 'array string matching must be case insensitive' do
    [
      'does_match',
      'DOES_MATCH',
      'DOES_match'
    ].each do | k |
      assert(source_filters(:source_filter_keyword).match(OpenStruct.new({'keywords': ['does_not_match', k]})), "failed matching: #{k}")
    end

    refute(source_filters(:source_filter_keyword).match(OpenStruct.new({'keywords': []})))
  end

  test 'source filter must have filter_property and nested_property properties' do
    assert(source_filters(:source_filter_keyword).filter_property == 'keywords')
    assert(source_filters(:source_filter_title).filter_property == 'title')
    assert_equal 'name', SourceFilter.new(property: 'author_name').nested_property
    assert_nil SourceFilter.new(property: 'title').nested_property
  end

  test 'value type is taken from the filter definition' do
    assert_equal :language, SourceFilter.new(property: 'language').value_type
    assert_equal :date, SourceFilter.new(property: 'date_published_after').value_type
    assert_equal :date, SourceFilter.new(property: 'date_published_before').value_type
    assert_equal :text, SourceFilter.new(property: 'title').value_type

    assert_equal :text, SourceFilter.new.value_type
    assert_equal :text, SourceFilter.value_type_for(nil), 'unset property should fall back to text'
  end

  test 'nested properties are matched through their parent association' do
    item = OpenStruct.new(
      authors: [
        OpenStruct.new(name: 'Jane Doe', orcid: '0000-0002-1825-0090'),
        OpenStruct.new(name: 'John Doe', orcid: 'https://orcid.org/0000-0002-1825-0097')
      ],
      instructors: [
        OpenStruct.new(name: 'Alice Smith', orcid: 'https://orcid.org/0000-0002-1825-0098')
      ],
      contributors: [
        OpenStruct.new(name: 'Bob Jones', orcid: '0000-0002-1825-0099')
      ],
      content_provider: OpenStruct.new(title: 'Goblet'),
      scientific_topics: [OpenStruct.new(label: 'RNA-Seq')],
      external_resources: [OpenStruct.new(title: 'Bio.tools', url: 'https://bio.tools/tool')],
      date_published: Date.new(2021, 7, 14)
    )

    [
      ['author_name', 'JOHN DOE', true],
      ['author_name', 'John', false],
      ['author_name_contains', 'doe', true],
      ['author_name_contains', 'Smith', false],
      ['author_orcid', 'https://orcid.org/0000-0002-1825-0090', true],
      ['author_orcid', '0000-0002-1825-0097', true],
      ['author_orcid', '0000-0002-1825-0099', false],
      ['instructor_name', 'ALICE SMITH', true],
      ['instructor_name', 'Alice', false],
      ['instructor_orcid', '0000-0002-1825-0098', true],
      ['instructor_orcid', '0000-0002-1825-0090', false],
      ['contributor_name', 'bob jones', true],
      ['contributor_name', 'Bob', false],
      ['contributor_orcid', '0000-0002-1825-0099', true],
      ['contributor_orcid', '0000-0002-1825-0090', false],
      ['content_provider_name', 'goblet', true],
      ['content_provider_name', 'iAnn', false],
      ['scientific_topic', 'RNA-Seq', true],
      ['scientific_topic', 'Genomics', false],
      ['external_resource_name', 'bio.tools', true],
      ['external_resource_name', 'Other', false],
      ['external_resource_url', 'https://bio.tools/tool', true],
      ['external_resource_url', 'https://example.com', false],
      ['external_resource_url_prefix', 'HTTPS://BIO.TOOLS', true],
      ['external_resource_url_prefix', 'https://example.com', false],
      ['date_published_after', '2021-07-13', true],
      ['date_published_after', '2021-07-14', false],
      ['date_published_before', '2021-07-15', true],
      ['date_published_before', '2021-07-14', false],
      ['date_published_after', 'not-a-date', false]
    ].each do |property, value, expected|
      filter = SourceFilter.new(property: property, value: value)
      if expected
        assert filter.match(item), "Expected #{property}=#{value} to match"
      else
        refute filter.match(item), "Expected #{property}=#{value} not to match"
      end
    end

    refute SourceFilter.new(property: 'author_name', value: 'John').match(OpenStruct.new)
    refute SourceFilter.new(property: 'author_name', value: 'John').match(OpenStruct.new(authors: []))
    refute SourceFilter.new(property: 'date_published_after', value: '2021-07-01').match(OpenStruct.new)

    material = materials(:material_with_optionals)
    assert SourceFilter.new(property: 'author_name', value: 'Nicolai Tesla').match(material)
    assert SourceFilter.new(property: 'author_name_contains', value: 'tesla').match(material)
    refute SourceFilter.new(property: 'author_name', value: 'Tesla').match(material)
  end

  test 'source filter must handle nil and empty values' do
    assert(source_filters(:source_filter_empty_title).match(OpenStruct.new({'title': ''})))
    assert(source_filters(:source_filter_empty_title).match(OpenStruct.new({'title': nil})))
    refute(source_filters(:source_filter_empty_title).match(OpenStruct.new({'title': 'a'})))
    
    assert(source_filters(:source_filter_no_title).match(OpenStruct.new({'title': ''})))
    assert(source_filters(:source_filter_no_title).match(OpenStruct.new({'title': nil})))
    refute(source_filters(:source_filter_no_title).match(OpenStruct.new({'title': 'a'})))
  end
end
