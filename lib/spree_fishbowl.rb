require 'spree_core'
require 'spree_fishbowl/engine'

module SpreeFishbowl

  def self.enabled?
    Spree::Config[:enable_fishbowl]
  end

  def self.client_from_config
    SpreeFishbowl::Client.from_config
  end

end
