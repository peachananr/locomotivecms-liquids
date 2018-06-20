module LocomotiveCMS
  module Liquids
    module Filters
      module Text # :nodoc:
        def handleize(input, divider = '-')
          input.to_str.gsub(%r{[ \_\-\/]}, divider).downcase
        end
        def normalize(input)
          require "i18n"
          I18n.transliterate(input).downcase
        end

        def squish(input)
          input.squish
        end
      end
    end
  end
end
