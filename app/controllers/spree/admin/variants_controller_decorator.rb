Spree::Admin::VariantsController.class_eval do
  def fishbowl
    e = params[:e]
    case e
    when 'sync'
      sync_fishbowl_inventory
    end
  rescue => e
    flash[:error] = "#{e.message}"
  ensure
    respond_with(@variant) { |format| format.html { redirect_to :back } }
  end

private
  def sync_fishbowl_inventory
    if !@variant.sku
      flash[:error] = 'No SKU defined for this variant'
      return false
    else
      return @variant.update_inventory_from_fishbowl
    end
  end

end