module Spree
  Variant.class_eval do
    include ActiveModel::Validations

    validates :sku, 'spree_fishbowl/sku_in_fishbowl' => true,
      :if => lambda { |variant| !variant.is_master? && variant.sku.present? }

    alias_method :orig_on_hand, :on_hand

    def on_hand
      return orig_on_hand unless (
        SpreeFishbowl.enabled? &&
        sku.present? &&
        Spree::Config[:fishbowl_always_fetch_current_inventory]
      )

      if Spree::Config[:track_inventory_levels] && !self.on_demand
        available = update_inventory_from_fishbowl
        available.nil? ? orig_on_hand : available
      else
        (1.0 / 0) # Infinity
      end
    end

    def update_inventory_from_fishbowl
      available = SpreeFishbowl.client_from_config.available_inventory(self)
      # don't trigger callbacks, because there's an after_save
      # hook that will attempt to fetch on_hand ... vicious
      # cycle
      update_column(:count_on_hand, available) unless available.nil?
      available
    end

  end
end
