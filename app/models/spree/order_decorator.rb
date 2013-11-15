module Spree
  Order.class_eval do
    has_many :fishbowl_logs
    attr_accessible :fishbowl_id, :so_number

    scope :fishbowl_submitted, lambda { where(arel_table[:fishbowl_id].not_eq(nil)) }
    scope :fishbowl_unsubmitted, lambda { where(arel_table[:fishbowl_id].eq(nil)) }

    alias_method :original_can_ship?, :can_ship?

    def fishbowl_sales_order_created?
      fishbowl_id.present?
    end

    def can_ship?
      original_can_ship? && (
        !SpreeFishbowl.enabled? || fishbowl_sales_order_created?
      )
    end

    def reset_fishbowl_sales_order
      self.fishbowl_id = nil
      self.so_number = nil
    end

    def create_fishbowl_sales_order
      fb = SpreeFishbowl.client_from_config

      sales_order = fb.create_sales_order!(self)
      update_from_sales_order(sales_order)
      sales_order
    end

    def update_from_fishbowl
      fb = SpreeFishbowl.client_from_config

      so_number = SpreeFishbowl::SalesOrderAdapter.so_number(self)

      sales_order = fb.sales_order(so_number)

      if sales_order
        update_from_sales_order(sales_order)
      else
        return false
      end

      return true
    end

    def update_from_sales_order(sales_order)
      self.fishbowl_id = sales_order.db_id
      self.so_number = sales_order.number
    end

    def sync_fishbowl_shipments
      fb = SpreeFishbowl.client_from_config

      shipments.pending.each do |shipment|
        shipment.ready if shipment.can_ready?
      end

      fishbowl_shipments = fb.get_order_shipments!(self)
      if fishbowl_shipments.blank?
        return false
      end

      if shipments.blank?
        return false
      end

      if fishbowl_shipments.length > 1
        raise 'Multiple shipments found; update shipment records manually'
      end

      fishbowl_shipment = fishbowl_shipments.first
      cartons = fishbowl_shipment.cartons || []

      # Currently setting each Spree shipment to the details
      # of the first and only shipment and carton until we support
      # multiple shipments / cartons per order
      shipments.each do |shipment|
        shipment.fishbowl_id = fishbowl_shipment.db_id
        shipment.tracking = cartons.first.tracking_num if cartons.length > 0
        shipment.ship!
        shipment.save
      end

      true
    end
  end
end
