module SpreeFishbowl
  class FishbowlCarrierValidator < ActiveModel::EachValidator

    def validate_each(record, attribute, value)
      record.errors[attribute] << 'is not a valid carrier in Fishbowl' if (
        SpreeFishbowl.enabled? &&
        SpreeFishbowl.client_from_config.carriers.include?(params[:name])
      )
    end

  end
end
