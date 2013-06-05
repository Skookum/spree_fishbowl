module Spree
  Variant.class_eval do
    has_many :fishbowl_logs
    attr_accessible :fishbowl_id, :so_number
  end
end
