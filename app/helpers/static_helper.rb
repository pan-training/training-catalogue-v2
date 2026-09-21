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

  # Determines whether the home page promo blocks should be shown for the
  # current space. The `home_page.promo_blocks` config accepts:
  #   - true:  show in the default space only (backwards compatible)
  #   - false: never show
  #   - a list of space identifiers (e.g. ['default', 'plants.mytess.training']):
  #     show when the current space is in the list. Use 'default' for the
  #     default space.
  def promo_blocks_enabled?
    config = TeSS::Config.site.dig('home_page', 'promo_blocks')
    return false if config.blank?
    return current_space.default? if config == true

    space_string = current_space.default? ? 'default' : current_space.host
    Array(config).include?(space_string)
  end
end
