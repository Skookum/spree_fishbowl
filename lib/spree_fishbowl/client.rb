require 'fishbowl'

module SpreeFishbowl

  class Client

    attr_reader :hostname, :port, :user, :password, :location_group,
      :last_error, :last_request, :last_response

    def initialize(options = nil)
      @max_retries = options[:max_retries] || 1
      set_options(options) if options
      # initializing like a boss
      @fishbowl = nil
      @last_error = nil
      @last_request, @last_response = nil, nil
      @auto_close = true
    end

    def self.from_config(addl_options = {})
      self.new({
        :hostname => Spree::Config[:fishbowl_host],
        :port => Spree::Config[:fishbowl_port],
        :user => Spree::Config[:fishbowl_user],
        :password => Spree::Config[:fishbowl_password],
        :location_group => Spree::Config[:fishbowl_location_group]
      }.merge(addl_options))
    end

    def set_options(options)
      [:hostname, :port, :user, :password, :location_group].each do |o|
        instance_variable_set("@#{o}", options[o])
      end
    end

    # You MUST manually close the connection if you disable
    # auto-close
    def set_auto_close(do_auto_close = true)
      @auto_close = do_auto_close
    end

    def self.enabled?
      SpreeFishbowl.enabled?
    end

    def configured?
      self.class.enabled? && hostname.present? &&
        user.present? && password.present?
    end

    def connected?
      !!@fishbowl && @fishbowl.connected?
    end

    def logged_in?
      !!@fishbowl && @fishbowl.has_ticket?
    end

    def error?
      !!@last_error
    end

    def error
      @last_error
    end

    def connect!
      raise 'No Fishbowl configuration specified' if !configured?

      (
        @fishbowl ||=
        Fishbowl::Connection.new(:host => hostname, :port => port)
      ).connect unless connected?

      connected?
    end

    def connect
      connect! rescue false
    end

    def disconnect!
      @fishbowl.close if connected?
      true
    end

    def disconnect
      disconnect! rescue false
    end

    def reconnect!
      disconnect! && connect!
    end

    def reconnect
      reconnect! rescue false
    end

    def login!
      connect! || (raise Fishbowl::Errors::ConnectionNotEstablished.new)
      @fishbowl.login(user, password).has_ticket?
    end

    def login
      login! rescue false
    end

    def customer!(name)
      execute_request(:get_customer, { :name => name })
    end

    def customer(name)
      customer!(name) rescue nil
    end

    def carriers!
      execute_request(:get_carrier_list)
    end

    def carriers
      carriers! rescue []
    end

    def location_groups!
      execute_request(:get_location_group_list)
    end

    def location_groups
      location_groups! rescue []
    end

    def part!(sku, location_group = nil)
      execute_request(:get_part, {
        :part_num => sku,
        :location_group => location_group || @location_group
      })
    end

    def part(*args)
      part!(*args) rescue nil
    end

    def product!(sku)
      execute_request(:get_product, {
        :product_num => sku
      })
    end

    def product(sku)
      product!(sku) rescue nil
    end

    def parts!
      execute_request(:get_light_part_list)
    end

    def parts
      parts! rescue []
    end

    def available_inventory!(variant, location_group = nil)
      location_group = location_group || @location_group
      return nil if variant.sku.blank?

      fb_product = product!(variant.sku)

      inventory_counts = execute_request(:get_inventory_quantity, {
          :part_number => fb_product.part.num
        }) unless fb_product.nil?
      if inventory_counts && inventory_counts.first
        inventory_counts.first.qty_available
      else
        nil
      end
    end

    def available_inventory(*args)
      available_inventory!(*args) rescue nil
    end

    def create_customer!(order)
      customer_obj = CustomerAdapter.adapt(order)
      execute_request(:save_customer, { :customer => customer_obj }, order.id)
    end

    def create_customer(order)
      create_customer!(order) rescue nil
    end

    def create_sales_order!(order, issue = true)
      sales_order = SalesOrderAdapter.adapt(order)
      if sales_order.customer_name.present?
        customer_obj = customer(sales_order.customer_name)
        if !customer_obj
          create_customer!(order)
        end
      end
      execute_request(:save_sales_order, { :issue => issue, :sales_order => sales_order}, order.id)
    end

    def create_sales_order(*args)
      create_sales_order!(*args) rescue nil
    end

    def get_order_shipments!(order)
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

    def get_order_shipments(order)
      get_order_shipments!(order) rescue []
    end

  private

    def connection
      connect! && @fishbowl
    end

    def execute_request(request_name, params = {}, order_id = nil)
      failure_count = 0

      begin
        @last_error = nil

        fb = connection
        fb.login! if !logged_in?

        fb.send(request_name, params)
      rescue Fishbowl::Errors::ServerError => e
        Rails.logger.debug e
        # Attempt call up to max_retries times
        unless ((failure_count += 1) <= @max_retries && reconnect)
          log_error e
          raise e
        end
        retry
      rescue Fishbowl::Errors::StatusError => e
        # Nothing special at the moment
        log_error e
        raise e
      ensure
        @last_request = fb.last_request
        @last_response = fb.last_response
        fb.close if @auto_close
      end
    end

    def log_error(e)
      @last_error = e
      Rails.logger.debug e
    end

  end

end
