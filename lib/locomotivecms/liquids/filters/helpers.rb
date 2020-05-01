module LocomotiveCMS
  module Liquids
    module Filters
      module Helpers # :nodoc:
        def url_for(url)
          url.chomp '/'
        end
        def env_variables (name)
          if name.blank?
            return ""
          else
            env = ENV["#{name}"] || ''
            return env
          end
        end


        def post_img_in_sitemap(input)
          require 'nokogiri'
          html = Nokogiri.HTML(input)
          tags = ""
          if html.css('img').size > 0
            html.css('img').each do |i|
              tags = "#{tags}\n<image:image>\n<image:loc>#{i['data-original']}</image:loc>\n<image:caption>#{i['alt']}</image:caption>\n</image:image>"
            end
          end
          input = tags
        end


        def getty_images (terms = nil, page = 1, size = 5, sort_order = "most_popular")
          if terms.blank?
            return ""
          else
            require 'json'
            require 'gettyimages-api'

            api_key = ENV['GETTY_KEY']
            api_secret = ENV['GETTY_SECRET']

            # create instance of the SDK
            apiClient = ApiClient.new(api_key, api_secret)
            require 'timeout'
            begin
              complete_results = Timeout.timeout(5) do
                result = apiClient
                    .search_images()
                    .with_phrase("#{terms}")
                    .with_graphical_styles(["photography"])
                    .with_fields(["referral_destinations", "preview", "title", "id"])
                    .with_exclude_nudity("true")
                    .with_page(page.to_i)
                    .with_page_size(size.to_i)
                    .with_sort_order("#{sort_order}")
                    .execute()
                return result.to_json
              end
            rescue Timeout::Error
              puts 'Error, 3rd Party API took too long.'
              return "Error Code 500, there might be something wrong with the third party plugin."
            end

          end

        end
      end
    end
  end
end
