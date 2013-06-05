class AddSoNumberToSpreeOrder < ActiveRecord::Migration
  def change
    add_column :spree_orders, :so_number, :string
  end
end
