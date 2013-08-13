module SpreeFishbowl
  class SkuInFishbowlValidator < ActiveModel::EachValidator

    def validate_each(record, attribute, value)
      record.errors[attribute] << 'is not a valid product in Fishbowl' if (
        SpreeFishbowl.enabled? &&
        value.present? &&
        SpreeFishbowl.client_from_config.product(value).nil?
      )
    end

  end
end
