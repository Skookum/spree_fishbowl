class MarkOrdersWithShippedInventoryAsShipped < ActiveRecord::Migration
  def up
  	Spree::InventoryUnit.shipped.reject do |inventory_unit|
      inventory_unit.shipment.blank? ||
      inventory_unit.shipment.state == 'shipped'
  	end.each do |inventory_unit|
      inventory_unit.shipment.state = 'shipped'
      inventory_unit.shipment.save
  	end
  end

  def down
  	raise ActiveRecord::IrreversibleMigration
  end
end
