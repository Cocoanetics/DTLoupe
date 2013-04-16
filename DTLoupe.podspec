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
end
