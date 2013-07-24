namespace :spree_fishbowl do

  desc "Create a sales order in Fishbowl for the specified Spree order"
  task :issue_sales_order, [:order_id] => [:environment] do |t, args|
    begin
      issue_sales_order(args[:order_id])
    rescue RuntimeError => e
      puts "ERROR: #{e}"
    end
  end

  desc "Create sales orders in Fishbowl for all complete, unprocessed Spree orders"
  task :issue_sales_orders => [:environment] do |t|
    Spree::Order.complete.fishbowl_unsubmitted.each do |order|
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
    begin
      sync_order_shipping(args[:order_id])
    rescue RuntimeError => e
      puts "ERROR: #{e}"
    end
  end

  desc "Update shipping information for all orders"
  task :sync_shipping => [:environment] do |t|
    # To work around issue with orders not transitioning shipments
    # to "ready" state
    Spree::Shipment.pending.each do |shipment|
      shipment.ready if shipment.can_ready?
    end
    Spree::Shipment.ready.each do |shipment|
      Rake::Task['spree_fishbowl:sync_order_shipping'].reenable
      Rake::Task['spree_fishbowl:sync_order_shipping'].invoke(shipment.order_id)
    end
  end

  def issue_sales_order(order_id)
    raise 'order_id is required' if order_id.nil?
    order = Spree::Order.find(order_id)
    raise 'Order is incomplete' if !order.complete?

    fishbowl = SpreeFishbowl.client_from_config

    puts "Processing order ##{order_id}"
    print "- Creating Fishbowl sales order ... "

    sales_order = fishbowl.create_sales_order(order)
    if sales_order.blank?
      puts "ERROR: (from Fishbowl) #{fishbowl.last_error}"
      return
    end

    puts "##{sales_order.db_id}"
    print "- Updating order with Fishbowl information ... "
    order.fishbowl_id = sales_order.db_id
    order.so_number = sales_order.number
    order.save!
    puts "done."
  end

  def sync_order_shipping(order_id)
    raise 'order_id is required' if order_id.nil?

    puts "Processing order ##{order_id}"
    order = Spree::Order.find(order_id)
    raise 'Order not ready to be shipped' if !order.can_ship?

    fishbowl = SpreeFishbowl.client_from_config

    print '- Fetching shipments ... '
    fishbowl_shipments = fishbowl.get_order_shipments(order)
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
      order_shipment.transaction do
        puts "- Updating shipment #{order_shipment.id}"
        order_shipment.fishbowl_id = fishbowl_shipment.db_id
        puts "  * Fishbowl ID #{order_shipment.fishbowl_id}"
        order_shipment.tracking = cartons.first.tracking_num if cartons.length > 0
        puts "  * Tracking number '#{order_shipment.tracking}'"
        order_shipment.save

        puts '- Transitioning to shipped state'
        order_shipment.ship!
      end
    end
  end

end
