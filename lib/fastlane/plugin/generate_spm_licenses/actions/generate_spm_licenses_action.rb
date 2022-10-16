require 'fastlane/action'
require_relative '../helper/generate_spm_licenses_helper'

module Fastlane
  module Actions
    License = Struct.new(:name, :text)

    class GenerateSpmLicensesAction < Action
      def self.run(params)
        require 'plist'
        require 'json'
        require 'uri'

        begin
          expanded_path = File.expand_path(params[:workspace])
          workspace_path = File.join(expanded_path, 'xcshareddata', 'swiftpm', 'Package.resolved')
          file = File.read(workspace_path)
          json = JSON.parse(file)

          json['pins']

          derived_data_path = File.expand_path(params[:derived_data_path])
          workspace_name = File.basename(expanded_path, File.extname(expanded_path))
          workspace_derived_data_folder = Dir["#{derived_data_path}/#{workspace_name}**"].first
          checkout_folder = File.join(workspace_derived_data_folder, 'SourcePackages', 'checkouts', '/**')
          checkout_folders = Dir[checkout_folder]

          if checkout_folders.empty?
            UI.user_error!("No checked out folders at '#{checkout_folder}'")
          end

          # Grab licenses
          licenses = checkout_folders
                     .filter_map do |path|
                       name = URI(path).path.split('/').last

                       UI.message("Found license for #{name}")
                       raw_license = File.join(path, 'LICENSE')
                       md_license = File.join(path, 'LICENSE.md')
                       txt_license = File.join(path, 'LICENSE.txt')
                       if File.exist?(raw_license)
                         License.new(name, File.read(raw_license))
                       elsif File.exist?(md_license)
                         License.new(name, File.read(md_license))
                       elsif File.exist?(txt_license)
                         License.new(name, File.read(txt_license))
                       end
                     end
                     .filter_map do |license|
            { 'Title' => license.name, 'Type' => 'PSGroupSpecifier', 'FooterText' => license.text }
          end
          wrapped_settings = { 'StringsTable' => 'Acknowledgements', 'PreferenceSpecifiers' => licenses }
          destination_path = File.expand_path(params[:destination])
          File.write(destination_path, wrapped_settings.to_plist)
        rescue StandardError => e
          UI.user_error!(e)
        end
      end

      # Helper Methods
      def self.xcode_preferences
        file = File.expand_path('~/Library/Preferences/com.apple.dt.Xcode.plist')
        if File.exist?(file)
          plist = CFPropertyList::List.new(file: file).value
          return CFPropertyList.native_types(plist) unless plist.nil?
        end
        nil
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'A short description with <= 80 characters of what this action does'
      end

      def self.details
        'You can use this action to do cool things...'
      end

      def self.available_options
        path = xcode_preferences ? xcode_preferences['IDECustomDerivedDataLocation'] : nil
        path ||= '~/Library/Developer/Xcode/DerivedData'
        [
          FastlaneCore::ConfigItem.new(key: :workspace,
                                       env_name: 'FL_LICENSES_WORKSPACE_PATH',
                                       description: 'Path for workspace',
                                       is_string: true,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :destination,
                                       env_name: 'FL_LICENSES_OUTPUT_PATH',
                                       description: 'Create a path to output to',
                                       is_string: true,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :derived_data_path,
                                       env_name: 'FL_LICENSES_DERIVED_DATA_PATH',
                                       description: 'Custom path for derivedData',
                                       default_value_dynamic: true,
                                       default_value: path)
        ]
      end

      def self.authors
        ['sammcewan']
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
