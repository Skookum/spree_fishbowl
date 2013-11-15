Spree::Admin::OrdersController.class_eval do
  def fishbowl
    e = params[:e]
    case e
    when 'create'
      create_fishbowl_sales_order(params[:force].present?)
    when 'fetch'
      fetch_fishbowl_sales_order
    end
  rescue => e
    flash[:error] = "#{e.message}"
  ensure
    respond_with(@order) { |format| format.html { redirect_to :back } }
  end

private
  def create_fishbowl_sales_order(force = false)
    @order.reset_fishbowl_sales_order if force

    if !force && @order.fishbowl_sales_order_created?
      flash[:error] = 'The specified order already has a Fishbowl ID'
      return false
    else
      @order.create_fishbowl_sales_order
      return @order.save
    end
  end

  def fetch_fishbowl_sales_order
    if @order.fishbowl_sales_order_created?
      flash[:error] = 'The specified order already has a Fishbowl ID'
      return false
    end

    @order.update_from_fishbowl
    @order.save
  end
end