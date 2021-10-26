require 'fastlane/action'
require 'aws-sdk-s3'
require_relative '../helper/s3_folder_upload_helper'

module Fastlane
  module Actions
    class S3FolderUploadAction < Action
      def self.run(params)

        # AWS authentication
        region            = params[:region]
        Aws.config.update({
          region: region,
          credentials: Aws::Credentials.new(params[:aws_key] || ENV['AWS_ACCESS_KEY_ID'], params[:aws_secret] || ENV['AWS_SECRET_ACCESS_KEY'])
        })

        # Validating buckets
        create_bucket     = params[:create_bucket] || true
        bucket            = params[:bucket]
        connection        = Aws::S3::Resource.new(region: region)
        buckets           = connection.buckets
        buckets.each { |found_bucket|
          puts "Available bucket: #{found_bucket.name}"
        }

        # Creating bucket if needed
        if buckets.map { |e| e.name  }.include?(bucket)
          puts "Bucket: #{bucket} is found. Continue uploading files ..."
        elsif create_bucket
          puts "Creating new bucket: #{bucket} with region: #{region} ..."
          connection.create_bucket(bucket: bucket)
        else
          puts "No bucket found! Please run with option create_bucket is true to create a new bucket!"
        end

        # Variables
        folder_path       = params[:folder_path]
        files             = Dir.glob("#{folder_path}/**/*")
        total_files       = files.length
        s3_bucket         = connection.bucket(bucket)
        include_folder    = params[:include_folder] || true
        thread_count      = params[:thread_count] || 5
        simulate          = false
        verbose           = params[:verbose] || true
        file_number        = 0
        mutex              = Mutex.new
        threads            = []

        puts "Total files: #{total_files}... uploading (folder #{folder_path} #{include_folder ? '' : 'not '}included)"

        thread_count.times do |i|
          threads[i] = Thread.new {
            until files.empty?
              mutex.synchronize do
                file_number += 1
                Thread.current["file_number"] = file_number
              end
              file = files.pop rescue nil
              next unless file

              # Define destination path
              if include_folder
                path = file
              else
                path = file.sub(/^#{folder_path}\//, '')
              end

              puts "[#{Thread.current["file_number"]}/#{total_files}] Uploading: #{path} ..." if verbose

              data = File.open(file)

              unless File.directory?(data) || simulate
                obj = s3_bucket.object(path)
                obj.put({ acl: "public-read", body: data, content_type: params[:content_type] })
              end

              data.close
            end
          }
        end
        threads.each { |t| t.join }
      end

      def self.description
        "Upload all files inside a folder to AWS S3"
      end

      def self.authors
        ["Steve"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "AWS S3 sdk only allow uploading a single file. This plugin was born to help uploading all files of a folder & its sub folders with multi-thread support"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :folder_path,
                               description: "Folder path to upload",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :content_type,
                               description: "Content type while uploading the file",
                                  optional: true,
                                      type: String),                            
          FastlaneCore::ConfigItem.new(key: :bucket,
                               description: "AWS S3 Bucket to upload",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :region,
                               description: "AWS S3 Region of Bucket to upload",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :aws_key,
                                  env_name: "AWS_ACCESS_KEY_ID",
                               description: "AWS Access key for authentication",
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :aws_secret,
                                  env_name: "AWS_SECRET_ACCESS_KEY",
                               description: "AWS Access secret for authentication",
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :create_bucket,
                               description: "Create a new bucket with given region in case the given bucket is not found",
                                  optional: true,
                                      type: Boolean,
                             default_value: true),
          FastlaneCore::ConfigItem.new(key: :include_folder,
                               description: "Upload files in sub-folder or not",
                                  optional: true,
                                      type: Boolean,
                             default_value: true),
          FastlaneCore::ConfigItem.new(key: :thread_count,
                               description: "Number of thread to upload files",
                                  optional: true,
                                      type: String,
                             default_value: 5),
          FastlaneCore::ConfigItem.new(key: :verbose,
                               description: "Puts message while uploading files",
                                  optional: true,
                                      type: Boolean,
                             default_value: true)
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        # [:ios, :mac, :android].include?(platform)
        true
      end
    end
  end
end
