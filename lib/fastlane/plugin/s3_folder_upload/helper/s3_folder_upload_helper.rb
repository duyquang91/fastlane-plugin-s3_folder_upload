require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class S3FolderUploadHelper
      # class methods that you define here become available in your action
      # as `Helper::S3FolderUploadHelper.your_method`
      #
      def self.show_message
        UI.message("Hello from the s3_folder_upload plugin helper!")
      end
    end
  end
end
