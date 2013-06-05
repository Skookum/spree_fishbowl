class Spree::FishbowlLog < ActiveRecord::Base
  attr_accessible :message, :order_id, :request_xml, :response_xml
  belongs_to :order
end
