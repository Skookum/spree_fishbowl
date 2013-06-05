class CreateSpreeFishbowlLogs < ActiveRecord::Migration
  def change
    create_table :spree_fishbowl_logs do |t|
      t.integer :order_id
      t.string :message
      t.text :request_xml
      t.text :response_xml

      t.timestamps
    end
  end
end
