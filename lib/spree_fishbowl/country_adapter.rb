require 'fishbowl'

module SpreeFishbowl

  class CountryAdapter

    def self.adapt(country)
      Fishbowl::Objects::Country.from_hash({
        :code => country.iso,
        :name => country.name
      })
    end

  end

end
