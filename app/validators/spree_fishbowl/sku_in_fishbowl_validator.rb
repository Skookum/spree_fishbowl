module SpreeFishbowl
  class SkuInFishbowlValidator < ActiveModel::EachValidator

    def validate_each(record, attribute, value)
      record.errors[attribute] << 'is not a valid product in Fishbowl' if (
        SpreeFishbowl.enabled? &&
        SpreeFishbowl.client_from_config.part(value).nil?
      )
    end

  end
end
