require 'fishbowl'

module SpreeFishbowl

  class Client

    def self.connection
      hostname = Spree::Config[:fishbowl_host]
      user = Spree::Config[:fishbowl_user]
      password = Spree::Config[:fishbowl_password]

      if hostname && !hostname.empty? && password && !password.empty?
        begin
          return Fishbowl::Connection.new(:host => hostname).connect.login(user, password)
        rescue
          # connection error; log?
        end
      end

      nil
    end

    def self.customer(name)
      begin
        execute_request(:get_customer, :name => name)
      rescue Fishbowl::Errors::StatusError => e
        raise e if !e.message.match 'not found'
        nil
      end
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

    def self.create_customer(order)
      customer_obj = CustomerAdapter.adapt(order)
      execute_request(:save_customer, { :customer => customer_obj }, order.id)
    end

    def self.create_sales_order(order, issue = true)
      sales_order = SalesOrderAdapter.adapt(order)
      if !sales_order.customer_name.nil?
        customer_obj = customer(sales_order.customer_name)
        create_customer(order) if !customer_obj
      end
      execute_request(:save_sales_order, { :issue => issue, :sales_order => sales_order}, order.id)
    end

    def self.get_order_shipments(order)
      ship_results = execute_request(:get_ship_list, {
        :order_number => order.so_number,
        :record_count => 50
      })
      ship_results.reject { |r| r.order_number != order.so_number }.
        select { |r| r.status == 'Shipped' }.
        map do |ship_result|
          execute_request(:get_shipment, { :shipment_id => ship_result.ship_id }, order.id)
        end if !ship_results.nil?
    end

    def self.execute_request(request_name, params = {}, order_id = nil)
      fishbowl = connection
      return nil if fishbowl.nil?

      begin
        result = fishbowl.send(request_name, params)
      rescue Fishbowl::Errors::StatusError => e
        raise e
      ensure
        last_request = fishbowl.last_request
        last_response = fishbowl.last_response

        Spree::FishbowlLog.new do |l|
          l.request_xml = last_request.to_xml
          l.response_xml = last_response.to_xml
          l.order_id = order_id
          l.message = e.message unless !defined?(e) || e.nil?
        end.save! unless order_id.nil?

        fishbowl.close
      end

      result
    end

  end

end