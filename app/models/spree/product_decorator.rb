# from http://stackoverflow.com/questions/16803413/spree-custom-error-how-to-trigger-error-in-related-model

module Spree
  Product.class_eval do
    validates_associated :variants, :variants_including_master, :master
    after_validation :merge_master_errors

    def merge_master_errors
      self.master.errors.each do |attribute, message|
        self.errors.add(attribute, message)
      end
    end
  end
end
