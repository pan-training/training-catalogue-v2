
module FilterComparisons
  def self.string_match(content_value, filter_value)
    content_value.to_s.casecmp?(filter_value)
  end

  def self.prefix_string_match(content_value, filter_value)
    content_value.to_s.downcase.start_with?(filter_value.downcase)
  end

  def self.contains_string_match(content_value, filter_value)
    content_value.to_s.downcase.include?(filter_value.downcase)
  end

  def self.array_string_match(content_value, filter_value)
    return false if content_value.nil?
    content_value.any? { |i| i.to_s.casecmp?(filter_value) }
  end

  def self.array_contains_string_match(content_value, filter_value)
    return false if content_value.nil?
    content_value.any? { |i| i.to_s.downcase.include?(filter_value.downcase) }
  end

  def self.array_prefix_string_match(content_value, filter_value)
    return false if content_value.nil?
    content_value.any? { |i| i.to_s.downcase.start_with?(filter_value.downcase) }
  end

  def self.date_after_match(content_value, filter_value)
    Date.parse(content_value.to_s) > Date.parse(filter_value.to_s)
  rescue ArgumentError, TypeError
    false
  end

  def self.date_before_match(content_value, filter_value)
    Date.parse(content_value.to_s) < Date.parse(filter_value.to_s)
  rescue ArgumentError, TypeError
    false
  end

  def self.orcid_match(content_value, filter_value)
    return false if content_value.nil?

    normalize_orcid = ->(value) { value.to_s.strip.sub(%r{\Ahttps?://orcid\.org/}i, '') }
    filter_orcid = normalize_orcid.call(filter_value)
    content_value.any? { |i| normalize_orcid.call(i).casecmp?(filter_orcid) }
  end
end


FILTER_DEFINITIONS = {
  'target_audience' => {
    comparison: FilterComparisons.method(:array_string_match)
  },

  'keyword' => {
    comparison: FilterComparisons.method(:array_string_match),
    filter_property: 'keywords'
  },

  'title' => {
    comparison: FilterComparisons.method(:string_match)
  },

  'title_contains' => {
    comparison: FilterComparisons.method(:contains_string_match),
    filter_property: 'title'
  },

  'description' => {
    comparison: FilterComparisons.method(:string_match)
  },

  'description_contains' => {
    comparison: FilterComparisons.method(:contains_string_match),
    filter_property: 'description'
  },

  'url' => {
    comparison: FilterComparisons.method(:string_match)
  },

  'url_prefix' => {
    comparison: FilterComparisons.method(:prefix_string_match),
    filter_property: 'url'
  },

  'doi' => {
    comparison: FilterComparisons.method(:string_match)
  },

  'license' => {
    comparison: FilterComparisons.method(:string_match),
    filter_property: 'licence'
  },

  'difficulty_level' => {
    comparison: FilterComparisons.method(:string_match)
  },

  'resource_type' => {
    comparison: FilterComparisons.method(:array_string_match)
  },

  'prerequisites_contains' => {
    comparison: FilterComparisons.method(:contains_string_match),
    filter_property: 'prerequisites'
  },

  'learning_objectives_contains' => {
    comparison: FilterComparisons.method(:contains_string_match),
    filter_property: 'learning_objectives'
  },

  'subtitle' => {
    comparison: FilterComparisons.method(:string_match)
  },

  'subtitle_contains' => {
    comparison: FilterComparisons.method(:contains_string_match),
    filter_property: 'subtitle'
  },

  'city' => {
    comparison: FilterComparisons.method(:string_match)
  },

  'country' => {
    comparison: FilterComparisons.method(:string_match)
  },

  'event_type' => {
    comparison: FilterComparisons.method(:array_string_match),
    filter_property: 'event_types'
  },

  'timezone' => {
    comparison: FilterComparisons.method(:string_match)
  },

  'author_name' => {
    comparison: FilterComparisons.method(:array_string_match),
    filter_property: 'authors',
    nested_property: 'name'
  },

  'author_name_contains' => {
    comparison: FilterComparisons.method(:array_contains_string_match),
    filter_property: 'authors',
    nested_property: 'name'
  },

  'author_orcid' => {
    comparison: FilterComparisons.method(:orcid_match),
    filter_property: 'authors',
    nested_property: 'orcid'
  },

  'instructor_name' => {
    comparison: FilterComparisons.method(:array_string_match),
    filter_property: 'instructors',
    nested_property: 'name'
  },

  'instructor_orcid' => {
    comparison: FilterComparisons.method(:orcid_match),
    filter_property: 'instructors',
    nested_property: 'orcid'
  },

  'contributor_name' => {
    comparison: FilterComparisons.method(:array_string_match),
    filter_property: 'contributors',
    nested_property: 'name'
  },

  'contributor_orcid' => {
    comparison: FilterComparisons.method(:orcid_match),
    filter_property: 'contributors',
    nested_property: 'orcid'
  },

  'organizer' => {
    comparison: FilterComparisons.method(:string_match),
  },

  'content_provider_name' => {
    comparison: FilterComparisons.method(:array_string_match),
    filter_property: 'content_provider',
    nested_property: 'title'
  },

  'language' => {
    comparison: FilterComparisons.method(:string_match),
    value_type: :language
  },

  'scientific_topic' => {
    comparison: FilterComparisons.method(:array_string_match),
    filter_property: 'scientific_topics',
    nested_property: 'label'
  },

  'date_published_after' => {
    comparison: FilterComparisons.method(:date_after_match),
    filter_property: 'date_published',
    value_type: :date
  },

  'date_published_before' => {
    comparison: FilterComparisons.method(:date_before_match),
    filter_property: 'date_published',
    value_type: :date
  },

  'external_resource_name' => {
    comparison: FilterComparisons.method(:array_string_match),
    filter_property: 'external_resources',
    nested_property: 'title'
  },

  'external_resource_url' => {
    comparison: FilterComparisons.method(:array_string_match),
    filter_property: 'external_resources',
    nested_property: 'url'
  },

  'external_resource_url_prefix' => {
    comparison: FilterComparisons.method(:array_prefix_string_match),
    filter_property: 'external_resources',
    nested_property: 'url'
  }
}.freeze


class SourceFilter < ApplicationRecord
  belongs_to :source

  auto_strip_attributes :value
  validates :mode, :property, presence: true

  enum :property, FILTER_DEFINITIONS.keys.index_with(&:itself)

  enum :mode, {
    allow: 'allow',
    block: 'block'
  }

  def self.value_type_for(property)
    FILTER_DEFINITIONS.dig(property.to_s, :value_type) || :text
  end

  def match(item)
    filter_definition[:comparison].call(filter_value_for(item), value.to_s)
  end

  def filter_definition 
    FILTER_DEFINITIONS[property]
  end

  def filter_property
    filter_definition[:filter_property] || property
  end

  # Compare against item.<filter_property>.<nested_property>, if present.
  def nested_property
    filter_definition[:nested_property]
  end

  def value_type
    self.class.value_type_for(property)
  end

  private

  def filter_value_for(item)
    return nil unless item.respond_to?(filter_property)

    content_value = item.send(filter_property)
    return content_value unless nested_property

    values = content_value.is_a?(Enumerable) ? content_value : [content_value]
    values.filter_map do |nested_item|
      nested_item.send(nested_property) if nested_item.respond_to?(nested_property)
    end
  end
end
