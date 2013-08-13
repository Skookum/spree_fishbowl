require 'fishbowl'

module SpreeFishbowl

  class CustomerAdapter

    def self.adapt(order)
      Fishbowl::Objects::Customer.from_hash({
        :name => order.billing_address.full_name,
        :job_depth => 1,
        :active => true,
        :tax_rate => nil,
        :addresses => addresses(order).map do |a|
          Fishbowl::Objects::Address.from_hash(a)
        end
      })
    end

    def self.addresses(order)
      main_address = base_address(order.billing_address).merge({
        :name => 'Main Address',
        :type => 'Main Office'
       })

      [main_address,
       billing_address(order.billing_address),
       shipping_address(order.shipping_address)]
    end

    def self.base_address(address)
      {
        :attn => address.full_name,
        :street => [address.address1, address.address2].join("\n").strip,
        :city => address.city,
        :zip => address.zipcode,
        :default => true,
        :residential => false,
        :state => StateAdapter.adapt(address.state),
        #:state => address.state.abbr,
        :country => CountryAdapter.adapt(address.country),
        #:country => address.country.iso,
        :address_information => []
      }
    end

    def self.billing_address(address)
      {
        :name => 'Billing Address',
        :type => 'Bill To'
      }.merge(base_address(address))
    end

    def self.shipping_address(address)
      {
        :name => 'Shipping Address',
        :type => 'Ship To'
      }.merge(base_address(address))
    end

  end

end
