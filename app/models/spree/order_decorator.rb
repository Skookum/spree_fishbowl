module Spree
  Variant.class_eval do
    has_many :fishbowl_logs
    attr_accessible :fishbowl_id, :so_number

    alias_method :original_can_ship?, :can_ship?

    def fishbowl_sales_order_created?
      fishbowl_id.present?
    end

    def can_ship?
      original_can_ship? && fishbowl_sales_order_created?
    end
  end
end
