module Spree
  Order.class_eval do
    has_many :fishbowl_logs
    attr_accessible :fishbowl_id, :so_number

    scope :fishbowl_submitted, lambda { where(table[:fishbowl_id].not_eq(nil) }
    scope :fishbowl_unsubmitted, lambda { where(table[:fishbowl_id].eq(nil) }

    alias_method :original_can_ship?, :can_ship?

    def fishbowl_sales_order_created?
      fishbowl_id.present?
    end

    def can_ship?
      original_can_ship? && fishbowl_sales_order_created?
    end
  end
end
