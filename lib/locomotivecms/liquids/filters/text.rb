module LocomotiveCMS
  module Liquids
    module Filters
      module Text # :nodoc:
        def handleize(input, divider = '-')
          input.to_str.gsub(%r{[ \_\-\/]}, divider).downcase
        end

        def url_encode(input)
          require "cgi"
          ERB::Util.url_encode(input)
        end

        def normalize(input)
          require "i18n"
          I18n.transliterate(input).downcase
        end

        def limit_ads(input, freq = '3', limit = '50', placeholder = '<div class="content_hint"></div>' )
          require 'nokogiri'
          html = Nokogiri.HTML(input)
          if html.css('body > p').length > 150
            spread = html.css('body > p').length.to_i/50
            spread = spread.floor
          else
            spread = freq
          end
          html.css('body > p').each_with_index do |i, index|
            if (index + 1) % spread == 0
              i.replace i.to_s.gsub("</p>", "</p>#{placeholder}")
            end
          end

          html.css("body").inner_html
        end

        def amp_optimize(input, freq = '2')
          require 'nokogiri'
          html = Nokogiri.HTML(input)
          html.css('.lightbox-full').each do |i|
            i.replace i.inner_html.gsub('<amp-img', '<amp-img role="button" tabindex="0" lightbox="posts" on="tap:lightbox1" ')
          end

          html.css('body > p').each_with_index do |i, index|
            if (index + 1) % freq == 0
              ads = '<div class="center"><amp-ad data-site="bucketlistly" height="250" type="mediavine" width="300"></amp-ad></div>'

              i.replace i.to_s.gsub("</p>", "</p>#{ads}")
            end

          end

          html.css("body").inner_html
        end

        def rss_optimize(input, freq = '2')
          require 'nokogiri'
          require 'htmlcompressor'
          doc = Nokogiri.HTML(input)
          doc.xpath('.//@data-placeholder').remove
          doc.xpath('.//@src').remove
          doc.xpath('.//@data-size').remove
          doc.xpath('.//@sizes').remove
          doc.xpath('.//@style').remove
          doc.xpath('.//@class').remove
          doc.xpath('.//@data-srcset').remove
          doc.search('#table-of-contents').remove
          doc.search('a').each do |i|
            if !i["href"].nil? and !i["href"].include? "http" and !i["href"].include? "data:"
              i["href"] = "https://www.bucketlistly.blog#{i["href"]}"
            end
          end
          text = ""
          doc.css("body > p").take(5).each do |i|
            text = "#{text}#{i.to_s}"
          end

          compressor = HtmlCompressor::Compressor.new

          compressor.compress(text)
        end

        def remove_placeholder_img(input)
          require 'nokogiri'
          html = Nokogiri.HTML(input)
          html.css('img.lazy').each do |i|
            padding_top = 0
            if !i["src"].nil? and i["src"].include? "placeholder"
              unless i["width"].nil? or i["height"].nil? or i["height"] == 0 or i["width"] == 0
                padding_top = (i["height"].to_f/i["width"].to_f) * 100
              end

              i.remove_attribute('src')
              i.remove_attribute('data-size') if !i["data-size"].nil?

              i.replace "<span role='presentation' class='img-wrapper'><i class='img-sizer' style='padding-top: #{padding_top}%;'></i>#{i.to_s}</span>"
            end
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
