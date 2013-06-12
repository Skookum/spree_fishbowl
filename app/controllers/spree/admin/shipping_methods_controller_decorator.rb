Spree::Admin::ShippingMethodsController.class_eval do

  alias_method :original_load_data, :load_data

  def load_data
    original_load_data
    @fishbowl_carriers = []

    if SpreeFishbowl.enabled?
      @fishbowl_carriers =
        SpreeFishbowl.client_from_config.carriers
    end
  end

end
