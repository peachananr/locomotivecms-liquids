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
            spread = html.xpath("//body/p[text()]").length.to_i/limit
            spread = spread.floor
          else
            spread = freq
          end
          html.xpath("//body/p[text()]").each_with_index do |i, index|
            if (index + 1) % spread == 0
              if i.next_element and !i.next_element['class'].nil? and i.next_element['class'].include? "readmore"
                i.next_element.add_next_sibling(placeholder)
              else
                i.add_next_sibling(placeholder)
              end
              #i.replace i.to_s.gsub("</p>", "</p>#{placeholder}")
            end
          end
          
          #el = html.css(".itinerary-summary-wrapper")

          #if el.size > 0
             #if html.css(".itinerary-summary-wrapper .last-minute-section").size > 0
            #  html.at_css(".itinerary-summary-wrapper .last-minute-section").add_previous_sibling(placeholder)
            #end
            #el.first.add_next_sibling(placeholder.gsub('content_hint', 'content_hint'))
            
          #  items = el.first.css(".ps-row")
          #  if items.size == 4 or items.size > 5
              #midpoint = (items.size / 2.0).ceil
          #    ad_placeholder = '<div class="ads"><div class="content_hint"></div></div>'
          #    items[3].add_next_sibling(ad_placeholder)
              #if items.size == 10 or items.size > 13
              #  #midpoint = (items.size / 2.0).ceil
              #  ad_placeholder = '<div class="ads"><div class="content_hint"></div></div>'
              #  items[9].add_next_sibling(ad_placeholder)
              #end
          #  else
          #    el.first.add_next_sibling(placeholder.gsub('content_hint', 'content_hint'))
          #  end
          #end
          
          #html.css(".itinerary-summary").each_with_index do |i, index|
          #  if (index + 1) % spread == 0
          #    i.replace i.to_s.gsub("</p>", "</p>#{placeholder}")
          #  end
          #end
          

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
          #    tags = "#{tags}\n<image:image>\n<image:loc>#{i['data-original']}</image:loc>\n</image:image>"
          #  end
          #end

          #if html.css('h3').size > 0
          #  html.css('h3').each do |i|
          #    if i.next_element.css("img").size > 0
          #      img = i.next_element.css("img").first
          #      tags = "#{tags}\n<image:image>\n<image:loc>#{img['data-original']}</image:loc>\n</image:image>"
          #    end
          #  end
          #end
          if html.css('.lightbox-full img, .itinerary img, .image-block img').size > 0
            html.css('.lightbox-full img, .itinerary img, .image-block img').each do |i|

              tags = "#{tags}\n<image:image>\n<image:loc>#{i['data-original']}</image:loc>\n</image:image>"
            end
          end

          return tags
        end
        def about_metadata(input, title, desc, slug, location)
          require 'nokogiri'
          html = Nokogiri.HTML(input)

          if html.css(".product-summary.itinerary-summary:not(.day-to-day)").size == 1
            list = html.css(".product-summary.itinerary-summary:not(.day-to-day) .ps-row:not(:empty)")
            list_count = list.size
            list_items = ""
            list.each_with_index do |i, index| 
              l_name = i.at_css(".ps-title").text.sub(/\b\d+\.\s*/, '').strip
              l_image = i.at_css(".ps-image img")["data-original"]
              l_image_full = ""
              if !l_image.include? "data:image/svg+xml;base6"
                l_image_full = "\"image\": \"#{l_image}\","
              end
              
              l_pos = index + 1
              l_url = "https://www.bucketlistly.blog/posts/#{slug}#{i["href"].gsub("https://www.bucketlistly.blog/posts/#{slug}","")}"

              list_items << " {
                \"@type\": \"ListItem\",
                \"position\": #{l_pos},
                \"name\": \"#{l_name.gsub('"', '\"')}\",
                #{l_image_full}                
                \"url\": \"#{l_url}\"
                },"
            end

            if list_items != ""
              list_final = "[#{list_items.chomp(',')}]"
              result = "\"about\": [
              {
                \"@context\": \"http://schema.org\",
                \"@type\": \"ItemList\",
                \"name\": \"#{title.gsub('"', '\"')}\",
                \"description\": \"#{desc.gsub('"', '\"')}\",
                \"itemListOrder\": \"http://schema.org/ItemListOrderAscending\",
                \"numberOfItems\": \"#{list_count}\",
                \"itemListElement\": #{list_final}
              }
            ],"

              return result
            end
            
          elsif html.css(".product-summary.itinerary-summary.day-to-day").size == 1
            list = html.css(".product-summary.itinerary-summary.day-to-day .ps-row:not(:empty) > a:not(.small-link)")
            list_items = ""
            list.each_with_index do |i, index| 
              l_country = location.split(",").last.strip
              l_name = i.at_css(".ps-title").text.sub(/\b\d+\.\s*/, '').strip
              l_image = i.at_css(".ps-image img")["data-original"]
              l_image_full = ""
              if !l_image.include? "data:image/svg+xml;base6"
                l_image_full = "\"image\": \"#{l_image}\","
              end
              l_description = i.at_css(".ps-desc").text
              l_url = "https://www.bucketlistly.blog/posts/#{slug}#{i["href"].gsub("https://www.bucketlistly.blog/posts/#{slug}","")}"

              list_items << " {
                \"@type\": \"TouristAttraction\",
                \"name\": \"#{l_name.sub(/.*?:\s*/, '')}\",
                \"url\": \"#{l_url}\",
                #{l_image_full}                
                \"description\": \"#{l_description.gsub('"', '\"')}\",
                \"address\": \"#{l_name.sub(/.*?:\s*/, '')}, #{l_country}\"
                },"
            end

            if list_items != ""
              list_final = "[#{list_items.chomp(',')}]"
              result = "\"about\": [
              {
                \"@type\": \"Trip\",
                \"name\": \"#{title.gsub('"', '\"')}\",
                \"description\": \"#{desc.gsub('"', '\"')}\",
                \"itinerary\": #{list_final}
              }
            ],"

              return result
            end
          end
        end

        def amp_story(input, slug = '') 
          require 'nokogiri'
          html = Nokogiri.HTML(input)
          result = []
          # PRODUCT SUMMARY WEB STORY
          if  html.css('.product-summary:not(.accommodation):not(.itinerary-summary)').size > 0
            html.css('.product-summary:not(.accommodation):not(.itinerary-summary) .ps-row').each_with_index do |p, index|
              break if index == 20;              
              name = p.at_css(".ps-name").text
              name2 = p.at_css(".ps-title").text
              shop_link = p["href"]
              thumb_img = p.at_css(".ps-image img")["data-original"]
              main_img = html.at_css(".image-block[href='#{shop_link}'] img")["data-original"]
              main_alt = html.at_css(".image-block[href='#{shop_link}'] img")["alt"]

              if !slug.nil?
                link = "<amp-story-page-outlink layout=\"nodisplay\">
                <a href=\"https://www.bucketlistly.blog/posts/#{slug}\" title=\"Go to Blog\">Go to Blog</a>
                </amp-story-page-outlink>"
              end

              if !shop_link.blank?
                link = "<amp-story-page-outlink layout=\"nodisplay\">
                <a href=\"#{shop_link}\" title=\"Check Price\">Check Price</a>
                </amp-story-page-outlink>"
              end

              content = "<amp-story-grid-layer template=\"vertical\" class=\"vertical_full\">
                        <div class=\"title safe_area\">
                        

                        <div class='header'><span class='number'>#{index+1}</span> <h2><span class=\"bold\">#{name2}</span> <span class='text'>#{name}</span></h2></div>
                      

                                </div>
                                <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"mask\" xml:space=\"preserve\" fill-rule=\"evenodd\" stroke-linejoin=\"round\" stroke-miterlimit=\"2\" clip-rule=\"evenodd\" viewBox=\"0 0 1183 43\"><path fill=\"#f8f3f3\" fill-rule=\"nonzero\" d=\"M1183 42S648-36 0 42V0h1183v42Z\"/></svg>
                                <div  class=\"logo\">
                                  <amp-img layout=\"fixed\" alt=\"BucketListly Blog Logo\" src=\"https://assets.bucketlistly.blog/sites/5adf778b6eabcc00190b75b1/theme/images/favicon.png\" width=\"35\" height=\"35\"></amp-img> <span>BucketListly Blog</span>
                                </div>
                              </amp-story-grid-layer>"
                              img = "<amp-story-grid-layer template=\"fill\" class=\"poster\"><amp-img translate-x=\"80px\" scale-start=\"1\"
                              scale-end=\"1.1\" animate-in=\"zoom-in\" animate-in-duration=\"7s\" src=\"#{main_img}\" width=\"1280\" height=\"853\" layout=\"fill\" alt=\"#{main_alt}\"></amp-img></amp-story-grid-layer>"

              content = <<~EOS
              <amp-story-page id="page_#{index + 1}" class="normal-page" auto-advance-after="7s">
                #{img}#{content}#{link}                        
              </amp-story-page>
              EOS

              result << content
            end
            

           

          # PRODUCT REVIEW WEB STORY
          elsif html.css('.pros-n-cons').length == 1
            h3_counter = 1
            html.css('h2').each do |h2|
              # Check if the h2 text starts with a number
              if h2.text.strip.match?(/^(?=.*(?:what i love|drawbacks|what i hate)).*$/i)
                # Find adjacent h3 elements until the next h2 is encountered
                next_element = h2.next_element
                while next_element && next_element.name != 'h2'
                  break if h3_counter == 21;

                  if next_element.name == 'h3'
                    # Add the number counter to the h3 element's text
                    name = next_element.text.strip
                    label = ""
                    if h2.text.downcase.include? "what i love"
                      label = "What I love about this:"
                    elsif h2.text.downcase.include? "what i hate" or h2.text.downcase.include? "drawbacks"
                      label = "What I hate about this:"
                    end
                    if !next_element.text.match?(/^\d+\./)
                      name = "<span class='number'>#{h3_counter}</span> <h2><span class=\"bold\">#{label}</span> <span class='text'>#{name}</span></h2>"
                    else 
                      name = "<span class='number'>#{h3_counter}</span> <h2><span class=\"bold\">#{label}</span> <span class='text'>#{name.split(".")[1].strip}ame}</span></h2>"
                    end
                      img = ""
                      link = ""
                      content = ""

                      if !slug.nil?
                        link = "<amp-story-page-outlink layout=\"nodisplay\">
                        <a href=\"https://www.bucketlistly.blog/posts/#{slug}\" title=\"Go to Blog\">Go to Blog</a>
                        </amp-story-page-outlink>"
                      end
                      content = "<amp-story-grid-layer template=\"vertical\" class=\"vertical_full\">
                      <div class=\"title safe_area\">
                      
                      <div class='header'>#{name}</div>
                              </div>
                              <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"mask\" xml:space=\"preserve\" fill-rule=\"evenodd\" stroke-linejoin=\"round\" stroke-miterlimit=\"2\" clip-rule=\"evenodd\" viewBox=\"0 0 1183 43\"><path fill=\"#f8f3f3\" fill-rule=\"nonzero\" d=\"M1183 42S648-36 0 42V0h1183v42Z\"/></svg>
                              <div  class=\"logo\">
                                  <amp-img layout=\"fixed\" alt=\"BucketListly Blog Logo\" src=\"https://assets.bucketlistly.blog/sites/5adf778b6eabcc00190b75b1/theme/images/favicon.png\" width=\"35\" height=\"35\"></amp-img> <span>BucketListly Blog</span>
                                </div>
                            </amp-story-grid-layer>"
                      if next_element.next_element.name == 'p' or next_element.next_element.name == 'div'
                        if next_element.next_element.css(".lightbox-full").length > 0 or next_element.next_element.css(".image-block").length > 0
                          get_img = next_element.next_element.at_css("img")
                          begin
                          img = "<amp-story-grid-layer template=\"fill\" class=\"poster\"><amp-img translate-x=\"80px\" scale-start=\"1\"
                          scale-end=\"1.1\" animate-in=\"zoom-in\" animate-in-duration=\"7s\" src=\"#{get_img["data-original"]}\" width=\"1280\" height=\"853\" layout=\"fill\" alt=\"#{get_img["alt"]}\"></amp-img></amp-story-grid-layer>"
                          rescue => error
                          end
                        end
                      end


                      content = <<~EOS
                      <amp-story-page id="page_#{h3_counter + 1}" class="normal-page" auto-advance-after="7s">
                        #{img}#{content}#{link}                        
                      </amp-story-page>
                      EOS

                      result << content
                      h3_counter += 1
                  end
                  next_element = next_element.next_element
                end
                break if h3_counter == 20;
              end
            end

          else
          # H2 ONLY WEB STORY
            if html.css('h2').size > 0
              # Adding numbering on h3
              h2_elements = html.css('h2')

              # Initialize a counter for the h3 elements
              h3_counter = 1

              if html.css('h3').size == 0
                html.css('h2').each do |p|
                  break if h3_counter == 21;              
                  name = p.text
                  if !name.match?(/^\d+\./)
                    name = "<span class='number'>#{h3_counter}</span> <h2><span class='text'>#{name}</span></h2>"
                  else 
                    name = "<span class='number'>#{h3_counter}</span> <h2><span class='text'>#{name.split(".")[1].strip}</span></h2>"
                  end
                  img = ""
                  if p.next_element.name == 'p' or p.next_element.name == 'div'
                    if p.next_element.css(".lightbox-full").length > 0 or p.next_element.css(".image-block").length > 0
                      get_img = p.next_element.at_css("img")
                      begin
                        img = "<amp-story-grid-layer template=\"fill\" class=\"poster\"><amp-img translate-x=\"80px\" scale-start=\"1\"
                        scale-end=\"1.1\" animate-in=\"zoom-in\" animate-in-duration=\"7s\" src=\"#{get_img["data-original"]}\" width=\"1280\" height=\"853\" layout=\"fill\" alt=\"#{get_img["alt"]}\"></amp-img></amp-story-grid-layer>"
                      rescue => error
                      end
                    end
                  end

                  next if img.blank?
                  
                  if !slug.nil?
                    link = "<amp-story-page-outlink layout=\"nodisplay\">
                    <a href=\"https://www.bucketlistly.blog/posts/#{slug}\" title=\"Go to Blog\">Go to Blog</a>
                    </amp-story-page-outlink>"
                  end
                  
                  content = "<amp-story-grid-layer template=\"vertical\" class=\"vertical_full\">
                            <div class=\"title safe_area\">
                          <div class='header'>#{name}</div>
                                    </div>
                                    <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"mask\" xml:space=\"preserve\" fill-rule=\"evenodd\" stroke-linejoin=\"round\" stroke-miterlimit=\"2\" clip-rule=\"evenodd\" viewBox=\"0 0 1183 43\"><path fill=\"#f8f3f3\" fill-rule=\"nonzero\" d=\"M1183 42S648-36 0 42V0h1183v42Z\"/></svg>
                                    <div  class=\"logo\">
                                      <amp-img layout=\"fixed\" alt=\"BucketListly Blog Logo\" src=\"https://assets.bucketlistly.blog/sites/5adf778b6eabcc00190b75b1/theme/images/favicon.png\" width=\"35\" height=\"35\"></amp-img> <span>BucketListly Blog</span>
                                    </div>
                                  </amp-story-grid-layer>"
                  
                  
                  content = <<~EOS
                  <amp-story-page id="page_#{h3_counter}" class="normal-page" auto-advance-after="7s">
                    #{img}#{content}#{link}                        
                  </amp-story-page>
                  EOS
    
                  result << content
                  h3_counter += 1
                end
              else
                # THINGS TO DO WEB STORY
                # Iterate through the h2 elements
                h2_elements.each do |h2|
                  # Check if the h2 text starts with a number
                  if h2.text.strip.match?(/^\d/i) or h2.text.strip.match?(/^(?![0-9])(?!.*\bmap\b)(?=.*(?:things to do|best places to|itinerary)).*$/i)
                    # Find adjacent h3 elements until the next h2 is encountered
                    next_element = h2.next_element

                    h3_limit = 21
                    #if html.css("h3").length > 15
                    #  h3_limit = 10
                    #end

                    while next_element && next_element.name != 'h2'
                      break if h3_counter == h3_limit;
                      img = ""
                      if next_element.name == 'h3'
                        # Add the number counter to the h3 element's text
                        name = next_element.text.strip
                        if !next_element.text.match?(/^\d+\./)
                          name = "<span class='number'>#{h3_counter}</span> <h2><span class='text'>#{name}</span></h2>"
                        else 
                          name = "<span class='number'>#{h3_counter}</span> <h2><span class='text'>#{name.split(".")[1].strip}</span></h2>"
                        end
                          img = ""
                          link = ""
                          content = ""

                          if !slug.nil?
                            link = "<amp-story-page-outlink layout=\"nodisplay\">
                            <a href=\"https://www.bucketlistly.blog/posts/#{slug}\" title=\"Go to Blog\">Go to Blog</a>
                            </amp-story-page-outlink>"
                          end
                          content = "<amp-story-grid-layer template=\"vertical\" class=\"vertical_full\">
                          <div class=\"title safe_area\">
                          <div class='header'>#{name}</div>
                                  </div>
                                  <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"mask\" xml:space=\"preserve\" fill-rule=\"evenodd\" stroke-linejoin=\"round\" stroke-miterlimit=\"2\" clip-rule=\"evenodd\" viewBox=\"0 0 1183 43\"><path fill=\"#f8f3f3\" fill-rule=\"nonzero\" d=\"M1183 42S648-36 0 42V0h1183v42Z\"/></svg>
                                  <div  class=\"logo\">
                                  <amp-img layout=\"fixed\" alt=\"BucketListly Blog Logo\" src=\"https://assets.bucketlistly.blog/sites/5adf778b6eabcc00190b75b1/theme/images/favicon.png\" width=\"35\" height=\"35\"></amp-img> <span>BucketListly Blog</span>
                                </div>
                                </amp-story-grid-layer>"
                          if next_element.next_element.name == 'p' or next_element.next_element.name == 'div'
                            if next_element.next_element.css(".lightbox-full").length > 0 or next_element.next_element.css(".image-block").length > 0
                              get_img = next_element.next_element.at_css("img")
                              begin
                              img = "<amp-story-grid-layer template=\"fill\" class=\"poster\"><amp-img translate-x=\"80px\" scale-start=\"1\"
                              scale-end=\"1.1\" animate-in=\"zoom-in\" animate-in-duration=\"7s\" src=\"#{get_img["data-original"]}\" width=\"1280\" height=\"853\" layout=\"fill\" alt=\"#{get_img["alt"]}\"></amp-img></amp-story-grid-layer>"
                              rescue => error
                              end
                              
                            end
                          end

                          
                          
                          content = <<~EOS
                          <amp-story-page id="page_#{h3_counter + 1}" class="normal-page" auto-advance-after="7s">
                            #{img}#{content}#{link}                        
                          </amp-story-page>
                          EOS
                          if !img.blank?
                            result << content
                            h3_counter += 1
                          end
                      end
                      next_element = next_element.next_element
                    end
                    break if h3_counter == h3_limit - 1;
                  end
                end
              end

              
            end
          end
          if !result.blank?
            return result
          else
            return "false"
          end
        end

        def generate_structured_data(input)
          require 'nokogiri'
          html = Nokogiri.HTML(input)
          result = ""

          if html.css('.pros-n-cons').size == 1
            i = html.at_css('.pros-n-cons')
            product_name = i.parent.previous_element.at_css('a').text
            pros = i.css('.pros li')
            pros_result = ""
            pros.each_with_index do |j, index|
              pros_result << "{
                \"@type\": \"ListItem\",
                \"position\": #{index + 1},
                \"name\": \"#{j.text}\"
              },"
            end

            cons = i.css('.cons li')
            cons_result = ""
            cons.each_with_index do |j, index|
              cons_result << "{
                \"@type\": \"ListItem\",
                \"position\": #{index + 1},
                \"name\": \"#{j.text}\"
              },"
            end

            result = "<script type=\"application/ld+json\">
              {
                \"@context\": \"https://schema.org\",
                \"@type\": \"Product\",
                \"name\": \"#{product_name}\",
                \"review\": {
                  \"@type\": \"Review\",
                  \"name\": \"#{product_name} review\",
                  \"author\": {
                    \"@type\": \"Person\",
                    \"name\": \"Pete Rojwongsuriya\"
                  },
                  \"positiveNotes\": {
                    \"@type\": \"ItemList\",
                    \"itemListElement\": [
                      #{pros_result.chomp(",")}
                    ]
                  },
                  \"negativeNotes\": {
                    \"@type\": \"ItemList\",
                    \"itemListElement\": [
                      #{cons_result.chomp(",")}
                    ]
                  }
                }
              }
            </script>"
          end

          selected_h2_elements = html.xpath('//h2[substring(., string-length(.) - 0) = "?"]')
          if selected_h2_elements.size > 1
            qa = ""
            selected_h2_elements.each do |h2|
              question = h2.text
              answer = ""

              adjacent_elements = []
              current_element = h2.next_element

              while current_element && (current_element.name == 'ul' || current_element.name == 'p' || (current_element.name == 'div' && current_element.css(".product-summary.accommodation").size > 0 ) || (current_element.name == 'h3'))
                if current_element.css('.product-summary.accommodation').size > 0
                  element = "<p>The best place to stay are"
                  current_element.css('.product-summary.accommodation a').each do |i|
                    hotel = "<a href=\"#{i["href"]}\" target=\"_blank\" rel=\"nofollow noopener\">#{i.at_css(".ps-name").text}</a>"
                    budget = i.at_css(".ps-title").text
                    element << " #{hotel} (#{budget}),"
                  end
                  element = "#{element.chomp(",")}."
                  adjacent_elements << element
                elsif current_element.name == 'h3'
                  adjacent_elements << "<strong>#{current_element.text}: </strong>"
                else
                  # Check if the current element doesn't have children with "lightbox-full" or "image-block" class
                  if current_element.css('.lightbox-full, .image-block').empty?
                    if !current_element["class"].nil?
                      if !current_element["class"].include? "readmore" and !current_element["class"].include? "credit" and !current_element["class"].include? "tips-block"
                        adjacent_elements << current_element
                      end
                    else 
                      adjacent_elements << current_element
                    end
                    
                  end
                end
                current_element = current_element.next_element
              end

              # Display the adjacent ul and p elements
              adjacent_elements.each do |element|
                answer << element.to_html
              end
              if !answer.empty?
                qa << "{
                  \"@type\": \"Question\",
                  \"name\": \"#{question}\",
                  \"acceptedAnswer\": {
                    \"@type\": \"Answer\",
                    \"text\": #{JSON.generate(answer)}
                  }
                },"
              end
            end
            if !qa.chomp(",").empty?
              result << "<script type=\"application/ld+json\">
              {
                \"@context\": \"https://schema.org\",
                \"@type\": \"FAQPage\",
                \"mainEntity\": [#{qa.chomp(",")}]
              }
              </script>"
            end
          end

          

          result
        end

        def list_tour_hotel(input)
          require 'nokogiri'
          html = Nokogiri.HTML(input)
          if html.css('.hotel-list').size > 0
            autopick = true
            if html.css('.product-summary.accommodation.tripple .editor-choice').size != 0
              autopick = false
            end

            if html.css('.hotel-list').size > 0 and html.css('.product-summary.accommodation.tripple').size == 1
              hotel_list = ""
              html.css('.product-summary.accommodation.tripple a').each do |a|
                ext = ""
                if autopick == true and a.at_css(".ps-title").text.downcase.strip.include? "mid-range"
                  ext = '<span class="editor-choice">👍 Top Pick</span>'
                end
                if autopick == false and a.css(".editor-choice").size > 0
                  ext = '<span class="editor-choice">👍 Top Pick</span>'
                end
                new_hotel = "<li><a href=\"#{a["href"]}\" target=\"_blank\" rel=\"nofollow noopener\">#{a.at_css(".ps-name").text.strip}</a> (#{a.at_css(".ps-title").text.strip}) #{ext}</li>"
                hotel_list << new_hotel
              end
              hotel_list = "<ol class='hotel-list-loaded item-list'>#{hotel_list}</ol>"
              html.at_css(".hotel-list").replace(hotel_list)              
            end
          end
          html.css("body").inner_html
        end

        def pdf_render(input)
          require 'nokogiri'
          html = Nokogiri.HTML(input)
          if html.css('.product-summary.accommodation').size > 0
            html.css('.product-summary.accommodation a').each do |a|
              new_a = "<a class='btn btn-primary' style='display: block;olor: inherit;background: #f0c029;' href='#{a["href"]}' rel='#{a["rel"]}' target='#{a["target"]}'>#{a.at_css(".ps-price span").inner_html}</a>"

              a.at_css(".ps-price span").replace(new_a)

              new_e = "<div style='display: contents;color: inherit;background: 0 0;'>#{a.inner_html}</div>"
              a.replace(new_e)
            end
          end

          amzn_links = html.css('a[href*="amzn.to"]')

          # Replace each link with its text content
          amzn_links.each do |link|
            link.replace("<strong>#{link.text}</strong>")
          end

          html.css("body").inner_html.gsub(/\p{Emoji_Presentation}/, '')
        end


        def remove_placeholder_img(input)
          require 'nokogiri'
          html = Nokogiri.HTML(input)
          if html.css('#insurance').size > 0
            html.at_css("#insurance").remove()
            
            insurance = '<div id="insurance"></div>'
            

            #remove unused html
            if html.css(".post-summary-wrapper.hide").size > 0
              html.css(".post-summary-wrapper.hide").remove
            end
            if html.css("article p.temp").size > 0
              html.css("article p.temp").remove
            end
            if html.css(".btn-wrap.hide").size > 0
              html.css(".btn-wrap.hide").remove
            end
            if html.css(".viator-extra.hide").size > 0
              html.css(".viator-extra.hide").remove
            end

             

            if html.css('.itinerary-summary-wrapper').size > 0    
              html.at_css('.itinerary-summary-wrapper').add_child(insurance)
            else
              if !html.css("h3:eq(2) ~ p:not(:empty):not(:has(img)):not(.tips-block)").nil? and !html.css("h3:eq(1) ~ p:not(:empty):not(:has(img)):not(.tips-block)")[2].nil?
                html.css("h3:eq(1) ~ p:not(:empty):not(:has(img)):not(.tips-block)")[2].add_next_sibling(insurance)
              elsif !html.css("h2:eq(1) ~ p:not(:empty):not(:has(img)):not(.tips-block)").nil?
                html.css("h2:eq(1) ~ p:not(:empty):not(:has(img)):not(.tips-block)")[2].add_next_sibling(insurance)
              else
                if html.css(".table-of-contents-wrapper").size > 0
                  if !html.at_css(".table-of-contents-wrapper").previous_element.attributes["class"].nil? and html.at_css(".table-of-contents-wrapper").previous_element["class"].include? "readmore-block"
                    html.at_css(".table-of-contents-wrapper").previous_element.add_previous_sibling(insurance)
                  else
                    html.at_css(".table-of-contents-wrapper").add_previous_sibling(insurance)
                  end
                elsif html.css("h2").size > 0
                  if !html.at_css("h2").previous_element.attributes["class"].nil? and html.at_css("h2").previous_element["class"].include? "readmore-block"
                    html.at_css("h2").previous_element.add_previous_sibling(insurance)
                  else
                    html.at_css("h2").add_previous_sibling(insurance)
                  end
                end
              end
            end
          end
          html.css('p:has(a[href*="goo.gl"],a[href*="g.page"],a[href*="google.com/maps"])').each do |i|
            maps_links = i.css('a[href*="goo.gl"]:not(.itinerary):not(.lightbox-full):not(.image-block):not(.itinerary):not(.video-block):not(.iframe-block), a[href*="g.page"]:not(.itinerary):not(.lightbox-full):not(.image-block):not(.itinerary):not(.video-block):not(.iframe-block), a[href*="google.com/maps"]:not(.itinerary):not(.lightbox-full):not(.image-block):not(.itinerary):not(.video-block):not(.iframe-block)')
            if maps_links.size > 0
              maps_links[0]["class"] = "first-of-type #{maps_links[0]["class"]}"
            end
          end
          
          if html.css('#pinterest').size > 0

            target_p = 'body > h2 ~ p:not(:empty):not(:has(img)):not(.tips-block), body > h3 ~ p:not(:empty):not(:has(img)):not(.tips-block)'
            if !html.css(target_p).nil? and !html.css(target_p)[2].nil?
              pinterest = "<div class=\"pin-it-section\" id=\"pinterest\">#{html.at_css("#pinterest").inner_html}</div>"
              html.at_css("#pinterest").remove()
              html.css(target_p)[2].add_next_sibling(pinterest)
            end

            target_p = 'body > h2 ~ p:not(:empty):not(:has(img)):not(.tips-block), body > h3 ~ p:not(:empty):not(:has(img)):not(.tips-block)'
            if !html.css(target_p).nil? and !html.css(target_p)[2].nil?
              pinterest = "<div class=\"pin-it-section\" id=\"pinterest\">#{html.at_css("#pinterest").inner_html}</div>"
              html.at_css("#pinterest").remove()
              html.css(target_p)[2].add_next_sibling(pinterest)
            end
          end
          
          if html.css('.accommodation-block:not(.dont-move)').size == 1
            el = html.at_css('.accommodation-block:not(.dont-move)')
            h2 = el.at_css('h2')["id"]
            if html.css(".pin-img-tag a img").length > 0 and (html.at_css(".pin-img-tag a img")["alt"].downcase.include? "things to do" or html.at_css(".pin-img-tag a img")["alt"].downcase.include? "itinerary") and html.css("body h2[id*='things-to-do'] ~ h3:eq(2)").length > 0 and html.css(".product-summary.accommodation").length == 1   
              html.at_css("body h2[id*='things-to-do'] ~ h3:eq(2)").add_previous_sibling(el)     
              h2 = html.at_css('.accommodation-block h2')
              new_h2 = "<h4 id='#{h2["id"]}'>#{h2.inner_html}</h4>"
              h2.replace(new_h2)
                       
              #el.remove
            elsif html.css('.activity-block').size == 1 and html.css('.activity-block h2').length > 0
              block = html.at_css('.activity-block h2')["id"]

              html.at_css('.activity-block').add_next_sibling(el)
              if html.css(".toc-list").size > 0
                el2 = html.at_css(".toc-list .toc-l1 a[href*='#{h2.downcase}']")
                html.at_css(".toc-list .toc-l1 a[href*='#{block.downcase}']").parent.add_next_sibling(el2.parent) 
              end
              #el.remove
            elsif html.css('.video-block-wrapper').size == 1
              block = html.at_css('.video-block-wrapper h2')["id"]

              html.at_css('.video-block-wrapper').add_next_sibling(el)
              if html.css(".toc-list").size > 0
                el2 = html.at_css(".toc-list .toc-l1 a[href*='#{h2.downcase}']")
                html.at_css(".toc-list .toc-l1 a[href*='#{block.downcase}']").parent.add_next_sibling(el2.parent)
              end
              #el.remove
            end
          end

          if html.css('.activity-block').size == 1
            
            if html.css(".pin-img-tag a img").length > 0 and (html.at_css(".pin-img-tag a img")["alt"].downcase.include? "things to do" or html.at_css(".pin-img-tag a img")["alt"].downcase.include? "itinerary")

                
                
                if html.css("body h2[id*='things-to-do'] ~ h3:eq(4)").length > 0
                  el = html.at_css('.activity-block')
                  h2 = html.at_css('.activity-block h2')
                  new_h2 = "<h4 id='#{h2["id"]}'>Tours & Tickets You Might Like</h4>"
                  h2.replace(new_h2)
                  html.at_css("body h2[id*='things-to-do'] ~ h3:eq(4)").add_previous_sibling(el)
                end
              
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

          if html.css('.product-summary.itinerary-summary').size > 0          
            html.css('.product-summary.itinerary-summary').each do |i|
              if i.css(".editor-choice").size > 0
                i.css(".editor-choice").each do |i|
                  id_el = i.xpath('ancestor::a').first["href"]

                  if html.css(id_el).size > 0
                    iduplicate = i.dup
                    iduplicate["aria-hidden"] = "true"
                    html.at_css(id_el).add_child(" #{iduplicate.to_html}")
                  end
                end
              end
              
          #    items = i.css(".ps-row")
          #    midpoint = (items.size / 2.0).ceil
          #    items[midpoint - 1].add_next_sibling('<div id="xxxxx"></div>')
              
          #    string = html.css('body').first.to_s
          #    string.gsub!('<div id="xxxxx"></div>', '</div><div class="mod product-summary itinerary-summary">')
          #    html = Nokogiri.HTML(string)
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
              edit = false
              if h2.text.strip.match?(/^\d(?!.*itinerary)/i) or h2.text.strip.match?(/^(?![0-9])(?!.*\bmap\b)(?=.*(?:things to do|what to eat|best places to)).*$/i)
                edit = true
              else
                if h2.text.downcase.include? "things to do"
                  edit = true
                end
              end

              if edit == true
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
          if html.css('.post-summary.day-to-day').size > 0
            if html.css('.post-summary.day-to-day td:contains("Day ")').size > 0
              html.css('.post-summary.day-to-day tr:not(:empty)').each do |a|
                label = a.at_css("td:first-child").text.strip
                name = a.at_css("td:last-child").text.strip
                
                if html.css("h3:contains(\"#{name}\")").length > 0 and !html.at_css("h3:contains(\"#{name}\")").text.match(/Day (\d+)/i)
                  html.at_css("h3:contains(\"#{name}\")").inner_html = "#{label.gsub("☀️ ","").gsub("-", " - ")} #{html.at_css("h3:contains(\"#{name}\")").inner_html}" 
                end
              end
            end
          end
          if html.css('div.product-summary:not(.accommodation):not(.itinerary-summary)').size > 0
            
            # Find all elements with class="product-summary"
            product_summaries = html.css('.product-summary:not(.accommodation):not(.itinerary-summary)')

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
              # Find all small-link 
              if table.css('span.small-link').size > 0
                table.css('span.small-link').each do |i|
                  begin
                    
                    new_element = "<a class=\"small-link\" href=\"#{i["data-href"]}\" target=\"_blank\">#{i.inner_html}</a>"
                    if i["class"].include? "learn-more"
                      new_element = "<a class=\"small-link learn-more\" href=\"#{i["data-href"]}\">#{i.inner_html}</a>"
                    end
                    i.replace(new_element)
                  rescue
                  end
                end
              end
              table.prepend_child("<thead><tr class=\"ps-row\"><th class=\"col-md hidden-xs\">Image</th><th class=\"col-md\">Product</th><th class=\"col-md  hidden-xs\">Features</th><th class=\"col-md  hidden-xs\"></th></tr></thead>")

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
              ## testing lazyload native
              #i["src"] = "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxIiBoZWlnaHQ9IjEiPjwvc3ZnPg=="
              i["src"] = "#{i["data-original"]}"  # testing lazyload native
              i["loading"] = "lazy"  # testing lazyload native

              #i.remove_attribute('src')

              ## testing lazyload native
              #i.remove_attribute('data-size') if !i["data-size"].nil?              
              #i["data-sizes"] = i["sizes"]
              #i.remove_attribute('sizes')
              
              ## testing lazyload native
              if !i["data-srcset"].nil?    
                i["srcset"] = i["data-srcset"]
                i.remove_attribute('data-srcset')
              end
              extra_class = ""
              if !i["class"].nil? and i["class"].include? "dark"
                extra_class = "dark"
              end
              if i["height"].to_f > i["width"].to_f
                extra_class = "landscape #{extra_class}"
              end
              i.replace "<span class=\"img-wrapper #{extra_class}\"><i class=\"img-sizer\" style=\"padding-top: #{padding_top}%;\"></i>#{i.to_s}#{no_script_image}</span>"

            elsif !i["data-original"].nil? and i["data-original"].include? "assets.bucketlistly.blog"
              ## testing lazyload native
              #i["src"] = "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxIiBoZWlnaHQ9IjEiPjwvc3ZnPg=="
              i["src"] = "#{i["data-original"]}"  # testing lazyload native
              i["loading"] = "lazy"  # testing lazyload native
              
            end

          end
          html.css('source[data-srcset]').each do |i|
            # testing lazyload native
            #i["srcset"] = "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxIiBoZWlnaHQ9IjEiPjwvc3ZnPg=="
            i["srcset"] = "#{i["data-srcset"]}"  # testing lazyload native
            i["loading"] = "lazy"  # testing lazyload native
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
