Deface::Override.new(
  :virtual_path => 'spree/admin/products/_form',
  :name => 'add_fishbowl_sync_to_product_edit',
  :surround => "code[erb-loud]:contains('f.field_container :on_demand')",
  :text => "<%= render_original %><%= button_link_to('Fetch', fishbowl_admin_product_url(@product, { :e => 'sync' }), { :icon => 'icon-refresh', :id => 'admin_sync_product_inventory' })  if (SpreeFishbowl.enabled? && @product.sku.present? && !@product.has_variants?) %>",
  :closing_selector => "code[erb-silent]:contains('end')"
)