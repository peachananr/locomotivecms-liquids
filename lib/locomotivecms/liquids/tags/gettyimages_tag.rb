module LocomotiveCMS
  module Liquids
    module Tags # :nodoc:
      # Gettyimages Tags
      class GettyImages < Solid::Tag
        tag_name :getty_images

        def display(terms = nil, page = 1, size = 5)
            if terms.blank?
              return ""
            else
              require 'json'
              init_gi(terms, page, size).to_json
            end
          end

          private

          def init_gi(terms, page, size)
            require 'gettyimages-api'

            api_key = ENV['GETTY_KEY']
            api_secret = ENV['GETTY_SECRET']

            # create instance of the SDK
            apiClient = ApiClient.new(api_key, api_secret)
            begin
              return result = apiClient
                  .search_images()
                  .with_phrase(terms)
                  .with_graphical_styles(["photography"])
                  .with_fields(["referral_destinations", "preview", "title", "id"])
                  .with_exclude_nudity("true")
                  .with_page(page)
                  .with_page_size(size)
                  .execute()

            rescue => error
              return result = apiClient
                  .search_images()
                  .with_phrase(terms)
                  .with_graphical_styles(["photography"])
                  .with_fields(["referral_destinations", "preview", "title", "id"])
                  .with_exclude_nudity("true")
                  .with_page(1)
                  .with_page_size(6)
                  .execute()
            end
          end
      end
    end
  end
end
