module LocomotiveCMS
  module Liquids
    module Filters
      module Text # :nodoc:
        def handleize(input, divider = '-')
          input.to_str.gsub(%r{[ \_\-\/]}, divider).downcase
        end

        def url_encode(input)
          require "cgi"
          CGI.escape(input) rescue input
        end

        def normalize(input)
          require "i18n"
          I18n.transliterate(input).downcase
        end

        def amp_remove_lightbox_link(input)
          require 'nokogiri'
          html = Nokogiri.HTML(input)
          html.css('.lightbox-full').each do |i|
            i.replace i.inner_html.gsub('<amp-img', '<amp-img role="button" tabindex="0" on="tap:lightbox1" ')
          end
          html.css("body").inner_html
        end

        def squish(input)
          input.gsub("\n", ' ').squeeze(' ')
        end
      end
    end
  end
end
