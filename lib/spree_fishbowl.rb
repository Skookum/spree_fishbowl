require 'spree_core'
require 'spree_fishbowl/engine'

module SpreeFishbowl

  def self.enabled?
    Spree::Config[:enable_fishbowl]
  end

  def self.client_from_config(addl_options = {})
    SpreeFishbowl::Client.from_config(addl_options)
  end

end
