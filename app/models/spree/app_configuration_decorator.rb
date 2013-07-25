Spree::AppConfiguration.class_eval do

  preference :enable_fishbowl, :boolean, :default => false
  preference :fishbowl_host, :string, :default => 'localhost'
  preference :fishbowl_port, :integer, :default => 28192
  preference :fishbowl_user, :string, :default => 'admin'
  preference :fishbowl_password, :password, :default => nil
  preference :fishbowl_store_abbreviation, :string, :default => nil
  preference :fishbowl_location_group, :string, :default => nil
  preference :fishbowl_always_fetch_current_inventory, :boolean, :default => true

end
