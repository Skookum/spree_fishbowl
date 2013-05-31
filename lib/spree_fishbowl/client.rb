require 'fishbowl'

module SpreeFishbowl

  class Client

    def self.connection
      hostname = Spree::Config[:fishbowl_host]
      user = Spree::Config[:fishbowl_user]
      password = Spree::Config[:fishbowl_password]

      if hostname && !hostname.empty? && password && !password.empty?
        return ::Fishbowl::Connection.new(:host => hostname).connect.login(user, password)
      end

      nil
    end

    def self.location_groups
      execute_request(:get_location_group_list)
    end

    def self.parts
      execute_request(:get_light_part_list)
    end

    def self.available_inventory(varient)
      location_group = Spree::Config[:fishbowl_location_group]
      return nil if location_group.nil? || location_group.empty? ||
        varient.sku.nil? || varient.sku.empty?

      execute_request(:get_total_inventory, {
        :part_number => varient.sku,
        :location_group => location_group
      })
    end

    def self.create_sales_order(sales_order, issue = true)
      execute_request(:save_sales_order, :issue => issue, :sales_order => sales_order)
    end

    def self.execute_request(request_name, params = nil)
      fishbowl = connection
      return nil if fishbowl.nil?

      begin
        result = fishbowl.send(request_name, params)
      rescue ::Fishbowl::Errors::StatusError
        Rails.logger.debug fishbowl.last_request
        Rails.logger.debug fishbowl.last_response
      ensure
        fishbowl.close
      end

      result
    end

  end

end