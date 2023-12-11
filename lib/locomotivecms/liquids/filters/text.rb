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

        def amp_story(input, slug = '') 
          require 'nokogiri'
          html = Nokogiri.HTML(input)
          result = []
          # PRODUCT SUMMARY WEB STORY
          if  html.css('.product-summary:not(.accommodation)').size > 0
            html.css('.product-summary:not(.accommodation) .ps-row').each_with_index do |p, index|
              break if index == 7;              
              name = p.at_css(".ps-name").text
              name2 = p.at_css(".ps-title").text
              shop_link = p["href"]
              thumb_img = p.at_css(".ps-image img")["data-original"]
              main_img = html.at_css(".image-block[href='#{shop_link}'] img")["data-original"]

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
                                  <svg width=\"35\" height=\"35\" viewBox=\"0 0 48.57 48.57\" xmlns=\"http://www.w3.org/2000/svg\" role=\"img\"><title>BucketListly Logo</title><path d=\"m48.56 24.28a24.28 24.28 0 1 0 -24.28 24.29 24.28 24.28 0 0 0 24.28-24.29z\" fill=\"#eebf25\"></path><path d=\"m12.506 19.144 1.258-.871 14.231 20.567-1.258.871zm20.844 1.626-7.78 5.38-1.29-1.87-3.32 2.3-6.22-8.99 5.91-4.09 2.24 3.24 7.54-5.21.61 5.21 4.66 2.4z\" fill=\"#231f20\"></path></svg> <span>BucketListly Blog</span>
                                </div>
                              </amp-story-grid-layer>"
                              img = "<amp-story-grid-layer template=\"fill\" class=\"poster\"><amp-img translate-x=\"80px\" scale-start=\"1\"
                              scale-end=\"1.1\" animate-in=\"zoom-in\" animate-in-duration=\"7s\" src=\"#{main_img}\" width=\"1280\" height=\"853\" layout=\"fill\" alt=\"{{post.title}}\" srcset=\"#{main_img} 640w, #{thumb_img} 320w\"></amp-img></amp-story-grid-layer>"

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
                  break if h3_counter == 8;

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
                                <svg width=\"35\" height=\"35\" viewBox=\"0 0 48.57 48.57\" xmlns=\"http://www.w3.org/2000/svg\" role=\"img\"><title>BucketListly Logo</title><path d=\"m48.56 24.28a24.28 24.28 0 1 0 -24.28 24.29 24.28 24.28 0 0 0 24.28-24.29z\" fill=\"#eebf25\"></path><path d=\"m12.506 19.144 1.258-.871 14.231 20.567-1.258.871zm20.844 1.626-7.78 5.38-1.29-1.87-3.32 2.3-6.22-8.99 5.91-4.09 2.24 3.24 7.54-5.21.61 5.21 4.66 2.4z\" fill=\"#231f20\"></path></svg> <span>BucketListly Blog</span>
                              </div>
                            </amp-story-grid-layer>"
                      if next_element.next_element.name == 'p' or next_element.next_element.name == 'div'
                        if next_element.next_element.css(".lightbox-full").length > 0 or next_element.next_element.css(".image-block").length > 0
                          get_img = next_element.next_element.at_css("img")
                          begin
                          img = "<amp-story-grid-layer template=\"fill\" class=\"poster\"><amp-img translate-x=\"80px\" scale-start=\"1\"
                          scale-end=\"1.1\" animate-in=\"zoom-in\" animate-in-duration=\"7s\" src=\"#{get_img["data-original"]}\" width=\"1280\" height=\"853\" layout=\"fill\" alt=\"{{post.title}}\" srcset=\"#{get_img["data-original"]} 640w, #{get_img["data-srcset"].split(",")[0].gsub(" 500w","")} 320w\"></amp-img></amp-story-grid-layer>"
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
                break if h3_counter == 7;
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
                  break if h3_counter == 8;              
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
                        scale-end=\"1.1\" animate-in=\"zoom-in\" animate-in-duration=\"7s\" src=\"#{get_img["data-original"]}\" width=\"1280\" height=\"853\" layout=\"fill\" alt=\"{{post.title}}\" srcset=\"#{get_img["data-original"]} 640w, #{get_img["data-srcset"].split(",")[0].gsub(" 500w","")} 320w\"></amp-img></amp-story-grid-layer>"
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
                                      <svg width=\"35\" height=\"35\" viewBox=\"0 0 48.57 48.57\" xmlns=\"http://www.w3.org/2000/svg\" role=\"img\"><title>BucketListly Logo</title><path d=\"m48.56 24.28a24.28 24.28 0 1 0 -24.28 24.29 24.28 24.28 0 0 0 24.28-24.29z\" fill=\"#eebf25\"></path><path d=\"m12.506 19.144 1.258-.871 14.231 20.567-1.258.871zm20.844 1.626-7.78 5.38-1.29-1.87-3.32 2.3-6.22-8.99 5.91-4.09 2.24 3.24 7.54-5.21.61 5.21 4.66 2.4z\" fill=\"#231f20\"></path></svg> <span>BucketListly Blog</span>
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

                    h3_limit = 8
                    if html.css("h3").length > 15
                      h3_limit = 10
                    end

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
                                    <svg width=\"35\" height=\"35\" viewBox=\"0 0 48.57 48.57\" xmlns=\"http://www.w3.org/2000/svg\" role=\"img\"><title>BucketListly Logo</title><path d=\"m48.56 24.28a24.28 24.28 0 1 0 -24.28 24.29 24.28 24.28 0 0 0 24.28-24.29z\" fill=\"#eebf25\"></path><path d=\"m12.506 19.144 1.258-.871 14.231 20.567-1.258.871zm20.844 1.626-7.78 5.38-1.29-1.87-3.32 2.3-6.22-8.99 5.91-4.09 2.24 3.24 7.54-5.21.61 5.21 4.66 2.4z\" fill=\"#231f20\"></path></svg> <span>BucketListly Blog</span>
                                  </div>
                                </amp-story-grid-layer>"
                          if next_element.next_element.name == 'p' or next_element.next_element.name == 'div'
                            if next_element.next_element.css(".lightbox-full").length > 0 or next_element.next_element.css(".image-block").length > 0
                              get_img = next_element.next_element.at_css("img")
                              begin
                              img = "<amp-story-grid-layer template=\"fill\" class=\"poster\"><amp-img translate-x=\"80px\" scale-start=\"1\"
                              scale-end=\"1.1\" animate-in=\"zoom-in\" animate-in-duration=\"7s\" src=\"#{get_img["data-original"]}\" width=\"1280\" height=\"853\" layout=\"fill\" alt=\"{{post.title}}\" srcset=\"#{get_img["data-original"]} 640w, #{get_img["data-srcset"].split(",")[0].gsub(" 500w","")} 320w\"></amp-img></amp-story-grid-layer>"
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


        def remove_placeholder_img(input)
          require 'nokogiri'
          html = Nokogiri.HTML(input)
          if html.css('#insurance').size > 0
            html.at_css("#insurance").remove()
            insurance = '<div id="insurance"></div>'
            if !html.css("h3:eq(2) ~ p:not(:empty):not(:has(img)):not(.tips-block)").nil? and !html.css("h3:eq(1) ~ p:not(:empty):not(:has(img)):not(.tips-block)")[1].nil?
              html.css("h3:eq(1) ~ p:not(:empty):not(:has(img)):not(.tips-block)")[1].add_next_sibling(insurance)
            else
              html.css("h2:eq(1) ~ p:not(:empty):not(:has(img)):not(.tips-block)")[1].add_next_sibling(insurance)
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
          
          if html.css('.accommodation-block').size == 1
            el = html.at_css('.accommodation-block')
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
              
                 if h2.text.strip.match?(/^(?![0-9])(?!.*\bmap\b)(?=.*(?:things to do|what to eat|best places to)).*$/i)
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
