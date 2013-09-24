Spree::Admin::ProductsController.class_eval do
  def fishbowl
    e = params[:e]
    case e
    when 'sync'
      sync_fishbowl_inventory
    end
  rescue => e
    flash[:error] = "#{e.message}"
  ensure
    respond_with(@product) { |format| format.html { redirect_to :back } }
  end

private
  def sync_fishbowl_inventory
    if !@product.sku
      flash[:error] = 'No SKU defined for this product'
      return false
    else
      return @product.update_inventory_from_fishbowl
    end
  end

end