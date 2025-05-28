#!/usr/bin/env ruby

require 'xcodeproj'

# Path to the Pods project
project_path = 'macos/Pods/Pods.xcodeproj'

# Open the project
project = Xcodeproj::Project.open(project_path)

# Find the BoringSSL-GRPC target
boringssl_target = project.targets.find { |target| target.name == 'BoringSSL-GRPC' }

if boringssl_target
  boringssl_target.build_configurations.each do |config|
    # Remove the -G flag from OTHER_CFLAGS
    if config.build_settings['OTHER_CFLAGS']
      config.build_settings['OTHER_CFLAGS'].delete('-G')
    end
    
    # Add necessary build settings
    config.build_settings['CLANG_WARN_DOCUMENTATION_COMMENTS'] = 'NO'
    config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
    config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '11.0'
    
    # Add preprocessor definitions
    config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
    config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'BORINGSSL_PREFIX=BoringSSL'
    
    # Add header search paths
    config.build_settings['HEADER_SEARCH_PATHS'] ||= ['$(inherited)']
    config.build_settings['HEADER_SEARCH_PATHS'] << '"${PODS_TARGET_SRCROOT}/src/include"'
  end
  
  # Save the changes
  project.save
  puts "Successfully updated BoringSSL-GRPC build settings"
else
  puts "Could not find BoringSSL-GRPC target"
end 