Pod::Spec.new do |spec|
  spec.name         = 'DTLoupe'
  spec.version      = '1.3.0'
  spec.platform     = :ios, '4.3'
  spec.license      = 'COMMERCIAL'
  spec.source       = { :git => 'git@git.cocoanetics.com:parts/dtloupe.git', :tag => spec.version.to_s }
  spec.source_files = 'Core/Source/*.{h,m}'
  spec.frameworks   = 'QuartzCore'
  spec.requires_arc = true
  spec.homepage     = 'http://www.cocoanetics.com/parts/dtloupeview/'
  spec.summary      = 'A Loupe as used for text selection.'
  spec.author       = { 'Oliver Drobnik' => 'oliver@cocoanetics.com' }
  spec.preserve_paths = 'DTLoupe.xcodeproj', 'Core/Resources'

def spec.post_install(target_installer)
    puts "\nGenerating DTLoupe resources bundle\n".yellow if config.verbose?
    Dir.chdir File.join(config.project_pods_root, 'DTLoupe') do
      command = "xcodebuild -project DTLoupe.xcodeproj -target 'Resource Bundle' CONFIGURATION_BUILD_DIR=../Resources"
      command << " 2>&1 > /dev/null" unless config.verbose?
      unless system(command)
        raise ::Pod::Informative, "Failed to generate DTLoupe resources bundle"
      end
    end
    if Version.new(Pod::VERSION) >= Version.new('0.16.999')
      script_path = target_installer.copy_resources_script_path
    else
      script_path = File.join(config.project_pods_root, target_installer.target_definition.copy_resources_script_name)
    end
    File.open(script_path, 'a') do |file|
      file.puts "install_resource 'Resources/DTLoupe.bundle'"
    end
  end
end
