module Spree
  Shipment.class_eval do
    attr_accessible :fishbowl_id
    # Carton currently not used until we can support
    # multiple shipments per order
    #attr_accessible :carton_id

    state_machine.before_transition :to => 'shipped', :do => :has_shipping_details?, :if => lambda { SpreeFishbowl.enabled? }

    def has_shipping_details?
      fishbowl_id.present?
    end

  end
end
