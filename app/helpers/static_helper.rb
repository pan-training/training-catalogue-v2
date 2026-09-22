# The helper for the static (home page) views
module StaticHelper
  # The promo blocks that can be shown on the home page.
  # Each entry maps a config key to its icon and translation key.
  PROMO_BLOCKS = {
    'nonprofit' => { icon: 'nonprofit-icon.svg', key: 'nonprofit' },
    'community' => { icon: 'community-icon.svg', key: 'community' },
    'sustainable' => { icon: 'sustainable-icon.svg', key: 'sustainable' },
    'domain' => { icon: 'microscope-icon.svg', key: 'domain' },
    'browse_space' => { icon: 'spaces-icon.svg', key: 'browse_space' },
    'create_space' => { icon: 'community-icon.svg', key: 'create_space' },
    'search' => { icon: 'search-icon-blue.svg', key: 'search' }
  }.freeze

  # The promo blocks shown when `home_page.promo_blocks_list` is not set.
  DEFAULT_PROMO_BLOCKS = %w[nonprofit community sustainable domain].freeze

  # The list of promo blocks to show on the home page, based on the
  # `home_page.promo_blocks_list` config. Unknown keys are ignored.
  # Defaults to the original four blocks when the setting is not present.
  def promo_blocks_list
    configured = TeSS::Config.site.dig('home_page', 'promo_blocks_list')
    configured = DEFAULT_PROMO_BLOCKS if configured.blank?

    configured.map { |key| PROMO_BLOCKS[key] }.compact
  end

  # Whether the promo blocks should be shown next to the welcome section
  # (side by side) instead of below the other home page sections.
  # Controlled by the `home_page.promo_blocks_next_to_welcome` config.
  # Defaults to false (promo blocks shown at the bottom, as before).
  def promo_blocks_next_to_welcome?
    TeSS::Config.site.dig('home_page', 'promo_blocks_next_to_welcome') == true
  end

  # The catalogue blocks that can be shown on the home page. Each key is a
  # resource type with a matching icon, `home.catalogue.<key>` description and
  # `features.<key>.long` title.
  CATALOGUE_BLOCKS = %w[events materials learning_paths trainers spaces workflows].freeze

  # The catalogue blocks shown when `home_page.catalogue_blocks_list` is not set.
  DEFAULT_CATALOGUE_BLOCKS = %w[events materials learning_paths trainers].freeze

  # The list of catalogue blocks to show on the home page, based on the
  # `home_page.catalogue_blocks_list` config. Blocks are shown in the configured
  # order; unknown keys are ignored, as are blocks whose feature is not enabled.
  # Defaults to the original four blocks when the setting is not present.
  def catalogue_blocks_list
    configured = TeSS::Config.site.dig('home_page', 'catalogue_blocks_list')
    configured = DEFAULT_CATALOGUE_BLOCKS if configured.blank?

    configured.select { |key| CATALOGUE_BLOCKS.include?(key) && feature_enabled?(key) }
  end

  # Whether the catalogue block links should include the `across_all_spaces=true`
  # option, so they show resources from all spaces instead of only the current one.
  # Controlled by the `home_page.catalogue_blocks_show_all` config.
  # Defaults to false (links point to the current space only, as before).
  def catalogue_blocks_show_all?
    TeSS::Config.site.dig('home_page', 'catalogue_blocks_show_all') == true
  end

  HOME_PAGE_SECTION_DEFAULTS = {
    'catalogue_blocks' => { default_space_only: true },
    'provider_carousel' => { default_space_only: true },
    'provider_grid' => { default_space_only: true },
    'faq' => { default_space_only: true, content: true },
    'promo_blocks' => { default_space_only: true },
    'upcoming_events' => { default_space_only: false, content: true },
    'latest_materials' => { default_space_only: false, content: true },
    'counters' => { default_space_only: false },
    'search_box' => { default_space_only: false }
  }.freeze

  # Evaluates a home page setting that can be either a boolean or a list of
  # spaces. The list is interpreted as:
  #   - [true, 'space.example.com'] => show everywhere except on that space
  #   - [false, 'space.example.com'] => show only on that space
  #   - ['space.example.com'] => show only on that space
  #   - true => preserves the section's legacy meaning for backwards compatibility
  #   - false => never show
  def home_page_space_config_enabled?(config, default_space_only: false)
    return false if config.nil?
    return (default_space_only ? current_space.default? : true) if config == true
    return false if config == false

    values = Array(config).map { |value| value.to_s.strip }
    return false if values.empty?

    default_value = %w[true false].include?(values.first) ? values.first == 'true' : false
    current_identifier = current_space.default? ? 'default' : current_space.host
    space_values = default_value ? values.drop(1) : values

    default_value ? !space_values.include?(current_identifier) : space_values.include?(current_identifier)
  end

  # A single place to determine whether a home page section should be shown.
  # Separate *_enabled settings take precedence when present, while older values
  # retain their original backwards-compatible meaning.
  def home_page_section_enabled?(setting_name, value = nil, default_space_only: nil)
    setting = HOME_PAGE_SECTION_DEFAULTS.fetch(setting_name.to_s, {})
    default_space_only = setting.fetch(:default_space_only, false) if default_space_only.nil?

    enabled = TeSS::Config.site.dig('home_page', "#{setting_name}_enabled")
    return home_page_space_config_enabled?(enabled, default_space_only: default_space_only) unless enabled.nil?

    config = value.nil? ? TeSS::Config.site.dig('home_page', setting_name) : value
    return false if config.nil?

    if setting[:content]
      return false if config.blank?
      return default_space_only ? current_space.default? : true
    end

    if config == true || config == false || config.is_a?(Array)
      return home_page_space_config_enabled?(config, default_space_only: default_space_only)
    end

    default_space_only ? current_space.default? && config.present? : config.present?
  end
end
