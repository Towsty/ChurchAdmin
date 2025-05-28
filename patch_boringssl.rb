#!/usr/bin/env ruby

require 'xcodeproj'

def patch_boringssl_settings
  # Path to the Pods project
  pods_project_path = 'macos/Pods/Pods.xcodeproj'
  
  # Open the project
  project = Xcodeproj::Project.open(pods_project_path)
  
  # Find the BoringSSL-GRPC target
  boringssl_target = project.targets.find { |target| target.name == 'BoringSSL-GRPC' }
  
  if boringssl_target
    boringssl_target.build_configurations.each do |config|
      # Remove the -G flag from OTHER_CFLAGS
      if config.build_settings['OTHER_CFLAGS']
        config.build_settings['OTHER_CFLAGS'] = config.build_settings['OTHER_CFLAGS'].reject { |flag| flag == '-G' }
      end
      
      # Add necessary build settings
      config.build_settings['CLANG_WARN_DOCUMENTATION_COMMENTS'] = 'NO'
      config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
      config.build_settings['SWIFT_SUPPRESS_WARNINGS'] = 'YES'
      config.build_settings['COMPILER_INDEX_STORE_ENABLE'] = 'NO'
      config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
      config.build_settings['GCC_OPTIMIZATION_LEVEL'] = '0'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
      config.build_settings['ENABLE_TESTABILITY'] = 'YES'
      config.build_settings['DEAD_CODE_STRIPPING'] = 'YES'
      
      # Update preprocessor definitions
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = ['$(inherited)', 'BORINGSSL_PREFIX=BoringSSL', 'OPENSSL_NO_ASM']
    end
    
    # Save changes
    project.save
    puts "Successfully patched BoringSSL-GRPC build settings"
  else
    puts "Could not find BoringSSL-GRPC target"
  end
end

# Execute the patch
patch_boringssl_settings 