class AddFishbowlIdToSpreeShipment < ActiveRecord::Migration
  def change
    add_column :spree_shipments, :fishbowl_id, :integer
  end
end
