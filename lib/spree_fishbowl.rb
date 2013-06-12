require 'spree_core'
require 'spree_fishbowl/engine'

module SpreeFishbowl

  @@fishbowl = nil

  def self.connection
    @@fishbowl
  end

  def self.enabled?
    defined? @@enabled ?
      @@enabled :
      Spree::Config[:enable_fishbowl]
  end

  def self.client_from_config
    @@fishbowl ||= SpreeFishbowl::Client.from_config
  end

end
