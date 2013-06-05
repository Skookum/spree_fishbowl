require 'fishbowl'

module SpreeFishbowl

  class StateAdapter

    def self.adapt(state)
      Fishbowl::Objects::State.from_hash({
        :code => state.abbr
        #:name => state.name
      })
    end

  end

end
