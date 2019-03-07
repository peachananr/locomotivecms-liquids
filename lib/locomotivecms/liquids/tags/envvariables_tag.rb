module LocomotiveCMS
  module Liquids
    module Tags # :nodoc:
      # Gettyimages Tags
      class EnvVariables < Solid::Tag
        tag_name :env_variables

        def display(name = nil)
            if name.blank?
              return ""
            else
              env = ENV["#{name}"] || ''
              return env
            end
        end
      end
    end
  end
end
