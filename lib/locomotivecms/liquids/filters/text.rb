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

        def utf_encode(input)
          input.unicode_normalize(:nfkd).encode('ASCII', replace: '')
        end

        def capitalize_all(input)
          input.split(' ').map(&:capitalize).join(' ')
        end

        def regex_escape(input)
          Regexp.escape(input)
        end

        def sanitize_this(input, t = "", att = "")
          
          ts = t.to_s.split(",")
          atts = att.to_s.split(",")

          ActionController::Base.helpers.sanitize(input, :tags=> ts, :attributes => atts).to_s

        end
        def normalize(input)
          require "i18n"
          I18n.transliterate(input).downcase
        end
        
        def get_html_attr(input, css = 'img', att = 'src')
          require 'nokogiri'
          html = Nokogiri.HTML(input)
          e = html.at_css(css)
          e[att].to_s
        end

        def limit_ads(input, freq = '3', limit = '50', placeholder = '<div class="content_hint"></div>' )
          require 'nokogiri'
          html = Nokogiri.HTML(input)
          if html.xpath("//body/p[text()]").length > 150
            spread = html.xpath("//body/p[text()]").length.to_i/50
            spread = spread.floor
          else
            spread = freq
          end
          html.xpath("//body/p[text()]").each_with_index do |i, index|
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
          if html.css('.lightbox-full img, .itinerary img, .image-block img').size > 0
            html.css('.lightbox-full img, .itinerary img, .image-block img').each do |i|

              tags = "#{tags}\n<image:image>\n<image:loc>#{i['data-original']}</image:loc>\n<image:caption><![CDATA[#{i['alt']}]]></image:caption>\n</image:image>"
            end
          end

          return tags
        end

        def remove_placeholder_img(input)
          require 'nokogiri'
          html = Nokogiri.HTML(input)
          if html.css('#insurance').size > 0
            html.at_css("#insurance").remove()
            insurance = '<div id="insurance"></div>'
            if !html.css("h3:eq(1) ~ p:not(:empty):not(:has(img))").nil? and !html.css("h3:eq(1) ~ p:not(:empty):not(:has(img))")[1].nil?
              html.css("h3:eq(1) ~ p:not(:empty):not(:has(img))")[1].add_next_sibling(insurance)
            else
              html.css("h2:eq(1) ~ p:not(:empty):not(:has(img))")[1].add_next_sibling(insurance)
            end
          end

          #if html.css('h2, h3').size > 4
          #  newsletter = '<div id="small-newsletter"></div>'
          #  html.at_css("h2:eq(4), h3:not(.adj-header):eq(4)").add_previous_sibling(newsletter)
          #end

          if html.css('.video-block .mediavine-vid').size == 0
            video = '<div id="watch-this"></div>'
            if html.css(".table-of-contents-wrapper").size > 0
              html.at_css(".table-of-contents-wrapper").add_previous_sibling(video)
            elsif html.css("h2").size > 0
              html.at_css("h2").add_previous_sibling(video)
            end
          end

          if html.css('.table-of-contents-wrapper').size > 0
            html.css('.table-of-contents-wrapper').first.inner_html = "#{html.css('.table-of-contents-wrapper').first.inner_html}-xxx"
            string = html.css('body').first.to_s
            string.gsub!("<body>", "<body><div>")
            string.gsub!("-xxx</div>", "</div></div>")
            html = Nokogiri.HTML(string)
          end

          if html.css('h2').size > 0
            # Adding numbering on h3
            h2_elements = html.css('h2')

            # Initialize a counter for the h3 elements
            h3_counter = 1

            # Iterate through the h2 elements
            h2_elements.each do |h2|
              # Check if the h2 text starts with a number
              if h2.text.strip.match?(/^\d(?!.*itinerary)/i) or h2.text.strip.match?(/^(?![0-9])(?!.*\bmap\b)(?=.*(?:things to do|what to eat|best places to)).*$/i)
                # Find adjacent h3 elements until the next h2 is encountered
                next_element = h2.next_element
                while next_element && next_element.name != 'h2'
                  if next_element.name == 'h3'
                    # Add the number counter to the h3 element's text
                    if !next_element.text.match?(/^\d+\./)
                      next_element.inner_html = "#{h3_counter}. #{next_element.inner_html.strip}"
                      h3_counter += 1
                    end
                  end
                  next_element = next_element.next_element
                end

                # Reset the counter for the next group of h3 elements
                h3_counter = 1
              end
            end
          end
          if html.css('div.product-summary:not(.accommodation)').size > 0
            
            # Find all elements with class="product-summary"
            product_summaries = html.css('.product-summary')

            # Iterate through each .product-summary element
            product_summaries.each do |product_summary|
              # Create a new <table> element and copy attributes
              table = Nokogiri::XML::Node.new('table', html)
              product_summary.attributes.each { |name, value| table[name] = value.value }

              # Find all <a> elements inside .product-summary
              links = product_summary.css('a')
              new_link = Nokogiri::XML::Node.new('a', html)
              new_link.inner_html = "Check Price"

              # Iterate through each <a> element
              links.each do |link|
                # Create a new <tr> element and copy attributes
                tr = Nokogiri::XML::Node.new('tr', html)
                tr["class"] = "ps-row"
                link.attributes.each { |name, value| new_link[name] = value.value }
                new_link["class"] = "btn btn-primary"

                link.at_css(".btn.btn-primary").replace(new_link)
                l = "<a href=\"#{new_link["href"]}\" target=\"#{new_link["target"]}\" rel=\"#{new_link["rel"]}\">"
                link.css(".ps-image, .ps-names").each do |i|
                  i.inner_html = "#{l}#{i.inner_html}</a>"
                end


                # Find all <div> elements with class="col-md" inside the <a> element
                col_md_divs = link.css('div.col-md')

                # Iterate through each <div class="col-md"> element
                col_md_divs.each do |div|
                  # Create a new <td> element and copy attributes
                  td = Nokogiri::XML::Node.new('td', html)
                  div.attributes.each { |name, value| td[name] = value.value }

                  # Move the content of the <div class="col-md"> to the <td>
                  td.inner_html = div.inner_html

                  # Append the <td> to the <tr>
                  tr.add_child(td)
                end

                # Append the <tr> to the <table>
                table.add_child(tr)

               
              end
              table.add_child("<thead><tr class=\"ps-row\"><th class=\"col-md hidden-xs\">Image</th><th class=\"col-md\">Product</th><th class=\"col-md  hidden-xs\">Features</th><th class=\"col-md  hidden-xs\"></th></tr></thead>")

              # Replace the .product-summary with the new <table>
              product_summary.replace(table)
            end
          end
          

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

              no_script_image = "<noscript><img width=\"#{i["width"]}\" height=\"#{i["height"]}\" src=\"#{i["data-original"]}\" alt=\"#{i["alt"]}\"></noscript>"
              i["src"] = "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxIiBoZWlnaHQ9IjEiPjwvc3ZnPg=="
              #i.remove_attribute('src')
              i.remove_attribute('data-size') if !i["data-size"].nil?
              i["data-sizes"] = i["sizes"]
              i.remove_attribute('sizes')

              extra_class = ""
              if !i["class"].nil? and i["class"].include? "dark"
                extra_class = "dark"
              end
              if i["height"].to_f > i["width"].to_f
                extra_class = "landscape #{extra_class}"
              end
              i.replace "<span class=\"img-wrapper #{extra_class}\"><i class=\"img-sizer\" style=\"padding-top: #{padding_top}%;\"></i>#{i.to_s}#{no_script_image}</span>"

            elsif !i["data-original"].nil? and i["data-original"].include? "assets.bucketlistly.blog"
              i["src"] = "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxIiBoZWlnaHQ9IjEiPjwvc3ZnPg=="
              
            end

          end
          html.css('source[data-srcset]').each do |i|
            i["srcset"] = "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxIiBoZWlnaHQ9IjEiPjwvc3ZnPg=="
            #i.remove_attribute('data-srcset') 
          end
          html.css("body").inner_html
        end

        def convert_to_article(input)
          require 'nokogiri'
          html = Nokogiri.HTML(input)

          if html.css('.video-block .mediavine-vid').size == 0
            video = '<div id="watch-this"></div>'
            if html.css(".table-of-contents-wrapper").size > 0
              html.at_css(".table-of-contents-wrapper").add_previous_sibling(video)
            elsif html.css("h2").size > 0
              html.at_css("h2").add_previous_sibling(video)
            end
          end

          #if html.css('.table-of-contents-wrapper').size > 0
          #  html.css('.table-of-contents-wrapper').first.inner_html = "#{html.css('.table-of-contents-wrapper').first.inner_html}-xxx"
          #  string = html.css('body').first.to_s
          #  string.gsub!("<body>", "<body><div>")
          #  string.gsub!("-xxx</div>", "</div></div>")
          #  html = Nokogiri.HTML(string)
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

            aspect_ratio = 'auto'

            if !i["src"].nil? and i["src"].include? "assets.bucketlistly.blog"
              unless i["width"].nil? or i["height"].nil? or i["height"] == 0 or i["width"] == 0
                aspect_ratio = "#{i["width"]}/#{i["height"]}"
              end

              no_script_image = "<noscript><img src='#{i["data-original"]}' alt='#{i["alt"]}'></noscript>"
              i.add_next_sibling(no_script_image)

              i.remove_attribute('src')
              i.remove_attribute('data-size') if !i["data-size"].nil?
              extra_class = ""
              if !i["class"].nil? and i["class"].include? "dark"
                extra_class = "dark"
              end
              i["style"] = "-webkit-aspect-ratio:#{aspect_ratio};aspect-ratio:#{aspect_ratio};"
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
