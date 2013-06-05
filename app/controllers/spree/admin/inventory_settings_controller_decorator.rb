Spree::Admin::InventorySettingsController.class_eval do

  alias_method :pre_settings_edit, :edit if self.respond_to?(:edit)

  def edit
    pre_settings_edit if respond_to?(:pre_settings_edit)

    @fishbowl_options = [ :fishbowl_host,
                          :fishbowl_user,
                          :fishbowl_password,
                          :fishbowl_store_abbreviation ]
    @location_groups = SpreeFishbowl::Client.location_groups || []
  end

end
