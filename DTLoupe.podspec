Pod::Spec.new do |spec|
  spec.name         = 'DTLoupe'
  spec.version      = '1.5.1'
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
  spec.resource     = 'Core/Resources/DTLoupe.bundle'

  # Pre Install: generate the 'DTLoupe.bundle' resource bundle
  spec.pre_install do |pod_representation, library_representation|
    Dir.chdir(pod_representation.root) do
      command = "xcodebuild -project DTLoupe.xcodeproj -target 'Resource Bundle' CONFIGURATION_BUILD_DIR=Core/Resources"
      command << " 2>&1 > /dev/null"
      unless system(command)
        raise ::Pod::Informative, "Failed to generate DTLoupe resources bundle"
      end
    end
  end
end
