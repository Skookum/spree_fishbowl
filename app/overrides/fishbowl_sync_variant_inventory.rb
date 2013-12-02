Deface::Override.new(
  :virtual_path => 'spree/admin/variants/_form',
  :name => 'add_fishbowl_sync_to_variant_edit',
  :surround_contents => "erb[silent]:contains('if Spree::Config[:track_inventory_levels]')",
  :text => "<%= render_original %><%= button_link_to('Fetch from Fishbowl', fishbowl_admin_product_variant_url(@product, @variant, { :e => 'sync' }), { :icon => 'icon-refresh', :id => 'admin_sync_variant_inventory' }) if (SpreeFishbowl.enabled? && @variant.sku.present?) %>",
  :closing_selector => "erb[silent]:contains('end')"
)
