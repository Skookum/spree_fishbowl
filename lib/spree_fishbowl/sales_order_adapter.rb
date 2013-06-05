require 'fishbowl'

module SpreeFishbowl

  class SalesOrderAdapter

    # Magic constants brought to you by:
    # http://fishbookspro.com/wp-content/uploads/2011/11/Poster_FishbowlMagicNumbers.pdf

    STATUS = {
      :estimate => 10,
      :issued => 20,
      :in_progress => 25,
      :fulfilled => 60,
      :closed_short => 70,
      :void => 80
    }

    TYPE = {
      :standard => 10,
      :point_of_sale => 20
    }

    PRIORITY = {
      :highest => 10,
      :high => 20,
      :normal => 30,
      :low => 40,
      :lowest => 50
    }

    def self.base_order(order)
      {
        :note => order.special_instructions,
        :salesman => 'admin',
        :salesman_initials => 'ADM',
        #:register_id => nil,
        :customer_po => order.number,
        :vendor_po => nil,
        :status => status(order),
        :location_group => Spree::Config[:fishbowl_location_group],
        #:issue => true,
        :note => nil,
        :created_date => DateTime.parse(order.created_at.to_s),
        #:issued_date => nil,
        #:fob => nil,
        #:quickbooks_class_name => nil,
        :type_id => type(order),
        #:url => nil,
        #:cost => nil,
        #:date_completed => nil,
        #:date_last_modified => nil,
        #:date_revision => nil,
        :priority_id => PRIORITY[:normal],
        :memos => []
      }
    end

    def self.totals(order)
      {
        :total_price => order.total,
        :total_includes_tax => true,
        :item_total => order.item_total
      }
    end

    def self.line_items(order)
      (order.line_items.map do |item|
        SalesOrderItemAdapter.adapt(item)
      end << shipping_line_item(order.ship_total))
        .each_with_index do |so_item, idx|
          so_item.line_number = idx + 1
        end
    end

    def self.status(order)
      STATUS[:issued]
    end

    def self.type(order)
      TYPE[:standard]
    end

    def self.customer(order)
      {
        :customer_contact => order.name,
        :customer_name => order.name,
        :customer_id => nil
      }
    end

    def self.taxes(order)
      {
        :total_tax => order.tax_total,
        :tax_rate_percentage => nil,
        :tax_rate_name => nil
      }
    end

    def self.payment_terms(order)
      'COD'
    end

    def self.billing(order)
      {
        :bill_to => bill_to(order),
        :payment_total => order.payment_total,
        :payment_terms => payment_terms(order)
      }
    end

    def self.carrier(order)
      order.shipping_method.name
    end

    def self.shipping_terms(order)
      'Prepaid & Billed'
    end

    def self.shipping(order)
      {
        :ship => ship_to(order),
        :residential => false,
        :carrier => carrier(order),
        :shipping_terms => shipping_terms(order),
        :first_ship_date => nil,
        :ups_service_id => nil
      }
    end

    def self.shipping_line_item(amount)
      Fishbowl::Objects::SalesOrderItem.from_hash({
        :product_number => 'Shipping',
        :description => 'Shipping',
        :quantity => 1,
        :uom_code => 'ea',
        :product_price => amount,
        :total_price => amount,
        :item_type => SalesOrderItemAdapter::TYPE[:shipping],
        :status => SalesOrderItemAdapter::STATUS[:entered],
        :new_item => false,
        :taxable => true
      })
    end

    def self.address(address)
      return {} if address.nil?

      {
        :name => address.full_name,
        :address_field => address.address1,
        :city => address.city,
        :state => address.state_text,
        :zip => address.zipcode,
        :country => address.country.try(:iso)
      }
    end

    def self.bill_to(order)
      Fishbowl::Objects::BillTo.from_hash(
        address(order.billing_address)
      )
    end

    def self.ship_to(order)
      Fishbowl::Objects::Ship.from_hash(
        address(order.shipping_address)
      )
    end

    def self.adapt(order)
      Fishbowl::Objects::SalesOrder.from_hash(
        base_order(order)
          .merge(customer(order))
          .merge(billing(order))
          .merge(shipping(order))
          .merge(taxes(order))
          .merge(totals(order))
          .merge({ :items => line_items(order) })
      )
    end

  end

end
