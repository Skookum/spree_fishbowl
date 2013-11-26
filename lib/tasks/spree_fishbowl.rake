namespace :spree_fishbowl do

  desc "Sync inventory for all variants"
  task :sync_inventory => [:environment] do
    # errors are rescued inside the method because it iterates
    # across all variants, and we don't want a single exception to
    # stop the batch process
    sync_inventory unless Spree::Config[:fishbowl_always_fetch_current_inventory]
  end

  desc "Create a sales order in Fishbowl for the specified Spree order"
  task :issue_sales_order, [:order_id] => [:environment] do |t, args|
    rescue_errors do
      issue_sales_order(args[:order_id])
    end
  end

  desc "Create sales orders in Fishbowl for all complete, unprocessed Spree orders"
  task :issue_sales_orders => [:environment] do |t|
    Spree::Order.with_state(:complete).fishbowl_unsubmitted.each do |order|
      # Only create sales order after the order has been paid for; past
      # that point, shipping happens solely in Fishbowl (and we must have a
      # paid-for order in order to ship)
      if order.paid?
        Rake::Task['spree_fishbowl:issue_sales_order'].reenable
        Rake::Task['spree_fishbowl:issue_sales_order'].invoke(order.id)
      end
    end
  end

  desc "Update shipping information for an order (if any)"
  task :sync_order_shipping, [:order_id] => [:environment] do |t, args|
    rescue_errors do
      sync_order_shipping(args[:order_id])
    end
  end

  desc "Update shipping information for all orders"
  task :sync_shipping => [:environment] do |t|
    # To work around issue with orders not transitioning shipments
    # to "ready" state
    Spree::Shipment.pending.each do |shipment|
      shipment.ready if shipment.can_ready?
    end
    Spree::Order.with_state(:complete).where(:shipment_state => :ready).each do |order|
      Rake::Task['spree_fishbowl:sync_order_shipping'].reenable
      Rake::Task['spree_fishbowl:sync_order_shipping'].invoke(order.id)
    end
  end

  desc "Run all Fishbowl sync tasks"
  task :sync => [:issue_sales_orders, :sync_inventory, :sync_shipping] do
    # No-op, just run the above
  end

  def issue_sales_order(order_id)
    raise 'order_id is required' if order_id.nil?
    order = Spree::Order.find(order_id)
    raise 'Order is incomplete' if !order.complete?

    fishbowl = SpreeFishbowl.client_from_config

    puts "Processing order ##{order.id} (#{order.number})"
    print "- Creating Fishbowl sales order ... "

    sales_order = fishbowl.create_sales_order!(order)

    puts "##{sales_order.db_id}"
    print "- Updating order with Fishbowl information ... "
    order.fishbowl_id = sales_order.db_id
    order.so_number = sales_order.number
    order.save!
    puts "done."
  end

  def sync_order_shipping(order_id)
    raise 'order_id is required' if order_id.nil?

    order = Spree::Order.find(order_id)
    puts "Processing order ##{order.id} (#{order.number})"
    raise 'Order not ready to be shipped' if !order.can_ship?

    fishbowl = SpreeFishbowl.client_from_config

    print '- Fetching shipments ... '
    fishbowl_shipments = fishbowl.get_order_shipments!(order)
    if fishbowl_shipments.blank?
      puts 'none found.'
      return
    end

    order_shipments = order.shipments
    if order_shipments.blank?
      puts 'ERROR: no defined shipments in Spree'
      return
    end

    if fishbowl_shipments.length > 1
      puts 'ERROR: multiple shipments, update manually'
    end

    puts "#{fishbowl_shipments.length} found."

    fishbowl_shipment = fishbowl_shipments.first
    cartons = fishbowl_shipment.cartons || []

    # Currently setting each Spree shipment to the details
    # of the first and only shipment and carton until we support
    # multiple shipments / cartons per order
    order_shipments.each do |order_shipment|
      puts "- Updating shipment #{order_shipment.id}"
      order_shipment.fishbowl_id = fishbowl_shipment.db_id
      puts "  * Fishbowl ID #{order_shipment.fishbowl_id}"
      order_shipment.tracking = cartons.first.tracking_num if cartons.length > 0
      puts "  * Tracking number '#{order_shipment.tracking}'"
      puts '- Transitioning to shipped state'
      order_shipment.ship!
      order_shipment.save
    end
  end

  def sync_inventory
    fishbowl = SpreeFishbowl.client_from_config
    # This is inefficient, but constructing this in a single
    # Arel query will take a bit of time
    Spree::Variant.active.reject do |variant|
      variant.sku.blank? || (
        variant.is_master? && variant.product.has_variants?
      )
    end.each do |variant|
      rescue_errors do
        inventory = fishbowl.available_inventory!(variant)
        unless inventory.nil? || (variant.orig_on_hand === inventory)
          puts "Setting on-hand count to #{inventory} for #{variant.sku} (was #{variant.orig_on_hand})"
          variant.on_hand = inventory
          variant.save
        end
      end
    end
  end

  def rescue_errors(fmt = 'ERROR: %s')
    yield if block_given?
  rescue Fishbowl::Errors::ServerError, Fishbowl::Errors::StatusError => e
    puts fmt.printf("(from Fishbowl) #{e}")
  rescue => e
    puts fmt.printf(e)
  end
end
