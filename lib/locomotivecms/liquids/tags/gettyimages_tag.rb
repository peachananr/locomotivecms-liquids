module LocomotiveCMS
  module Liquids
    module Tags # :nodoc:
      # Gettyimages Tags
      class GettyImages < Solid::Tag
        tag_name :getty_images

        def display(terms = nil, page = 1, size = 5, sort_order = "most_popular")
            if terms.blank?
              return ""
            else
              require 'json'
              init_gi(terms, page, size, sort_order).to_json
            end
          end

          private

          def init_gi(terms, page, size, sort_order)
            require 'gettyimages-api'

            api_key = ENV['GETTY_KEY']
            api_secret = ENV['GETTY_SECRET']

            # create instance of the SDK
            apiClient = ApiClient.new(api_key, api_secret)
            require 'timeout'
            begin
              complete_results = Timeout.timeout(5) do
                return result = apiClient
                    .search_images()
                    .with_phrase("#{terms}")
                    .with_graphical_styles(["photography"])
                    .with_fields(["referral_destinations", "preview", "title", "id"])
                    .with_exclude_nudity("true")
                    .with_page(page.to_i)
                    .with_page_size(size.to_i)
                    .with_sort_order("#{sort_order}")
                    .execute()
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
