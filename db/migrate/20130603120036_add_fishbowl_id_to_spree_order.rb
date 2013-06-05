class AddFishbowlIdToSpreeOrder < ActiveRecord::Migration
  def change
    add_column :spree_orders, :fishbowl_id, :string
  end
end
