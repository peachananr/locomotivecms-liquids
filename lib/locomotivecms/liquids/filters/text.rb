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

        def regex_escape(input)
          Regexp.escape(input)
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
        def no_timestamp(input)
          if input and input.include? "?" and !input.include? "="
            input.split('?')[0]
          end
        end

        def post_img_in_sitemap(input)
          require 'nokogiri'
          html = Nokogiri.HTML(input)
          tags = ""

          #if html.css('.itinerary img').size > 0
          #  html.css('.itinerary img').each do |i|
          #    tags = "#{tags}\n<image:image>\n<image:loc>#{i['data-original']}</image:loc>\n<image:caption>#{i['alt'].to_s.gsub("&", "&amp;")}</image:caption>\n</image:image>"
          #  end
          #end

          #if html.css('h3').size > 0
          #  html.css('h3').each do |i|
          #    if i.next_element.css("img").size > 0
          #      img = i.next_element.css("img").first
          #      tags = "#{tags}\n<image:image>\n<image:loc>#{img['data-original']}</image:loc>\n<image:caption>#{i.text.to_s.gsub("&", "&amp;")} - #{img['alt'].to_s.gsub("&", "&amp;")}</image:caption>\n</image:image>"
          #    end
          #  end
          #end
          if html.css('.lightbox-full img, .itinerary img').size > 0
            html.css('.lightbox-full img, .itinerary img').each do |i|

              tags = "#{tags}\n<image:image>\n<image:loc>#{i['data-original']}</image:loc>\n<image:caption><![CDATA[#{i['alt']}]]></image:caption>\n</image:image>"
            end
          end

          return tags
        end

        def remove_placeholder_img(input)
          require 'nokogiri'
          html = Nokogiri.HTML(input)

          if html.css('.video-block .mediavine-vid').size == 0
            video = '<div id="watch-this"></div>'
            if html.css(".table-of-contents-wrapper").size > 0
              html.at_css(".table-of-contents-wrapper").add_previous_sibling(video)
            elsif html.css("h3").size > 0
              html.at_css("h3").add_previous_sibling(video)
            end
          end

          if html.css('.table-of-contents-wrapper').size > 0
            html.css('.table-of-contents-wrapper').first.inner_html = "#{html.css('.table-of-contents-wrapper').first.inner_html}-xxx"
            string = html.css('body').first.to_s
            string.gsub!("<body>", "<body><div>")
            string.gsub!("-xxx</div>", "</div></div>")

            html = Nokogiri.HTML(string)
          end
          #if html.css('.table-of-contents-wrapper').size > 0
            #html.css("body").first.inner_html = "<div>#{html.css("body").first.inner_html}"
            #html.css(".table-of-contents-wrapper").first.inner_html = "#{html.css(".table-of-contents-wrapper").first.inner_html}</div>"
            #wrap = html.xpath('//div[@id="table-of-contents"]/preceding::p')
            #wrap = "<div>#{wrap}</div>"
            #html.xpath('//div[@id="table-of-contents"]/preceding::p').remove
            #html.css(".table-of-contents-wrapper").first.parent.inner_html = "#{wrap}#{html.css(".table-of-contents-wrapper").first.parent.inner_html}"
          #end

          html.css('img.lazy').each do |i|

            if !i.parent.nil? and i.parent.name == "a"
              if !i.parent.attributes["class"].nil? and i.parent.attributes["class"].value.include? "lightbox"
                i.parent["aria-label"] = "View larger image"
              end
              if !i.parent.attributes["class"].nil? and i.parent.attributes["class"].value.include? "itinerary"
                i.parent["aria-label"] = "View itinerary on Google Maps"
              end
              if !i.parent.attributes["class"].nil? and i.parent.attributes["class"].value.include? "click-to-play"
                i.parent["aria-label"] = "Play video"
              end
              if !i.parent.attributes["class"].nil? and i.parent.attributes["class"].value.include? "image-block"
                i.parent["aria-label"] = "Navigate to external site"
              end
            end

            padding_top = 0
            if !i["src"].nil? and i["src"].include? "assets.bucketlistly.blog"
              unless i["width"].nil? or i["height"].nil? or i["height"] == 0 or i["width"] == 0
                padding_top = (i["height"].to_f/i["width"].to_f) * 100
              end

              i.remove_attribute('src')
              i.remove_attribute('data-size') if !i["data-size"].nil?
              extra_class = ""
              if !i["class"].nil? and i["class"].include? "dark"
                extra_class = "dark"
              end
              i.replace "<span class='img-wrapper #{extra_class}'><i class='img-sizer' style='padding-top: #{padding_top}%;'></i>#{i.to_s}</span>"
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
