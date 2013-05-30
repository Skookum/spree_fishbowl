Spree::AppConfiguration.class_eval do

  preference :fishbowl_host, :string, :default => 'localhost'
  preference :fishbowl_user, :string, :default => 'admin'
  preference :fishbowl_password, :password, :default => nil
  preference :fishbowl_location_group, :string, :default => nil

end