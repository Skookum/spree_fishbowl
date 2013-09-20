Spree::Admin::ShipmentsController.class_eval do
  def fishbowl
    e = params[:e]
    case e
    when 'sync'
      sync_fishbowl_shipments
    end
  rescue => e
    flash[:error] = "#{e.message}"
  ensure
    respond_with(@order.shipments) { |format| format.html { redirect_to :back } }
  end

private
  def sync_fishbowl_shipments
    if !@order.shipments
      flash[:error] = 'No shipment records defined for this order'
      return false
    else
      return @order.sync_fishbowl_shipments
    end
  end

end