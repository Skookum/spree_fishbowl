require 'fishbowl'

module SpreeFishbowl

  class SalesOrderItemAdapter

    # Magic constants brought to you by:
    # http://fishbookspro.com/wp-content/uploads/2011/11/Poster_FishbowlMagicNumbers.pdf

    STATUS = {
      :entered => 10,
      :awaiting_build => 11,
      :building => 12,
      :built => 14,
      :picking => 20,
      :partial => 30,
      :picked => 40,
      :fulfilled => 50,
      :closed_short => 60,
      :voided => 70
    }

    TYPE = {
      :sale => 10,
      :misc_sale => 11,
      :drop_ship => 12,
      :credit_return => 20,
      :misc_credit => 21,
      :discount_percentage => 30,
      :discount_amount => 31,
      :subtotal => 40,
      :assoc_price => 50,
      :shipping => 60,
      :tax => 70,
      :kit => 80
    }

    def self.base_item(item)
      {
        :product_number => item.variant.sku,
        :description => item.variant.product.description,
        :quantity => item.quantity,
        :product_price => item.price,
        :total_price => item.amount,
        :uom_code => nil,
        :item_type => item_type(item),
        :status => status(item),
        #:quickbooks_class_name => nil,
        :new_item => false,
        #:line_number => nil,
        #:kit_item => false,
        #:adjustment_amount => nil,
        #:adjustment_percentage => nil,
        :customer_part_num => nil,
        #:date_last_fulfillment => nil,
        #:date_last_modified => nil,
        #:date_scheduled_fulfillment => nil,
        #:exchange_so_line_item => nil,
        #:item_adjust_id => nil,
        #:qty_fulfilled => nil,
        #:qty_picked => nil,
        #:revision_level => nil,
        #:total_cost => nil,
        # apparently all items are sent as not-taxable, as Fishbowl
        # doesn't manage the taxes
        #:tax_id => nil,
        #:tax_rate => nil,
        #:taxable => false
      }
    end

    def self.item_type(item)
      TYPE[:sale]
    end

    def self.status(item)
      STATUS[:entered]
    end

    def self.adapt(item)
      sales_order_item = Fishbowl::Objects::SalesOrderItem.new

      properties = base_item(item)
      properties.each { |k, v| sales_order_item.send("#{k}=", v) }

      sales_order_item
    end

  end

end
