Pod::Spec.new do |spec|
  spec.name         = 'DTLoupe'
  spec.version      = '1.5.5'
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
  spec.resource_bundles = { 'DTLoupe' => ['Core/Resources/*.png'] } 
end
