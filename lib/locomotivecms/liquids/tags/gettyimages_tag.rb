module LocomotiveCMS
  module Liquids
    module Tags # :nodoc:
      # Gettyimages Tags
      class GettyImages < Solid::Tag
        tag_name :getty_images

        def display(terms = nil)
            if terms.blank?
              return ""
            else
              result = ""
               init_gi(terms)["images"].each do | image |
                 result << %{
                  <a href="#{image["referral_destinations"][0].values[1]}" target="_blank" id="gettyimage-#{image["id"]}" class="getty_image col-md-2" style="background: url(#{image["display_sizes"][0]["uri"]}) no-repeat center center; background-size: cover;" title="title="#{image["title"]}"">
                  <img src="#{image["display_sizes"][0]["uri"]}" alt="#{image["title"]}">
                  </a>
                }

              end
              return result
            end
          end

          private

          def init_gi(terms)
            require 'gettyimages-api'

            api_key = ENV['GETTY_KEY']
            api_secret = ENV['GETTY_SECRET']

            # create instance of the SDK
            apiClient = ApiClient.new(api_key, api_secret)
            return result = apiClient
                .search_images()
                .with_phrase(terms)
                .with_fields(["referral_destinations", "preview", "title", "id"])
                .with_exclude_nudity("true")
                .with_page(1)
                .with_page_size(5)
                .execute()

          end
      end
    end
  end
end
