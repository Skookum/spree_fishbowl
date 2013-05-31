module Spree
  Variant.class_eval do
    alias_method :orig_on_hand, :on_hand

    def on_hand
      return orig_on_hand if (!Spree::Config[:enable_fishbowl] || !sku)

      if Spree::Config[:track_inventory_levels] && !self.on_demand
        available = SpreeFishbowl::Client.available_inventory(self)
        available.nil? ? orig_on_hand : available
      else
        (1.0 / 0) # Infinity
      end
    end

    def on_hand=(new_level)
      # no-op
    end

  end
end
