module Spree
  ShippingMethod.class_eval do
    include ActiveModel::Validations

    validates :name, :presence => true, 'spree_fishbowl/fishbowl_carrier' => true
  end
end
