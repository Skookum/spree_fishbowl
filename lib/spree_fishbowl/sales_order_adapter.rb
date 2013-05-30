require 'fishbowl'
require 'pry'

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
        :register_id => nil,
        :number => order.number,
        :customer_po => nil,
        :vendor_po => nil,
        :status => status(order),
        :location_group => Spree::Config[:fishbowl_location_group],
        :issue => true,
        :note => nil,
        :created_date => order.created_at,
        :issued_date => nil,
        :fob => nil,
        :quickbooks_class_name => nil,
        :type_id => type(order),
        :url => nil,
        :cost => nil,
        :date_completed => nil,
        :date_last_modified => nil,
        :date_revision => nil,
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
      order.line_items.map do |item|
        SalesOrderItemAdapter.adapt(item)
      end
    end

    def self.status(order)
      nil
    end

    def self.type(order)
      TYPE[:standard]
    end

    def self.customer(order)
      {
        :customer_contact => nil,
        :customer_name => nil,
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

    def self.billing(order)
      {
        :bill_to => bill_to(order),
        :payment_total => order.payment_total,
        :payment_terms => nil
      }
    end

    def self.shipping(order)
      {
        :ship => ship_to(order),
        :residential => false,
        :carrier => nil,
        :shipping_cost => order.ship_total,
        :shipping_terms => nil,
        :first_ship_date => nil,
        :ups_service_id => nil
      }
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
      bill_to_addr = Fishbowl::Objects::BillTo.new
      address(order.billing_address).each do |k, v|
        bill_to_addr.send("#{k}=", v)
      end

      bill_to_addr
    end

    def self.ship_to(order)
      ship_to_addr = Fishbowl::Objects::Ship.new
      address(order.shipping_address).each do |k, v|
        ship_to_addr.send("#{k}=", v)
      end

      ship_to_addr
    end

    def self.adapt(order)
      sales_order = Fishbowl::Objects::SalesOrder.new

      properties = base_order(order).merge(:items => line_items(order))
      [:base_order, :customer, :billing, :shipping, :taxes, :totals].each do |p|
        properties.merge!(send(p, order))
      end

      properties.each { |k, v| sales_order.send("#{k}=", v) }

      sales_order
    end

  end

end
