Pod::Spec.new do |s|
  s.name         = 'MNWebKit'
  s.version      = '0.0.6'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.summary      = 'MNWebKit is a reimplementation of the interface and feature set of iOS 8\'s WebKit framework to be usable in iOS 7.'
  s.homepage     = 'https://github.com/master-nevi/MNWebKit'
  s.authors      = { 'David Robles' => 'david@applauze.com' }
  s.source       = { :git => 'https://github.com/master-nevi/MNWebKit.git', :tag => s.version.to_s }
  s.source_files = 'Source/*.{h,m}'
  s.resources = ['Source/*.js']
  s.xcconfig     = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2' }
  s.requires_arc = true
  s.platform = :ios, '6.0'
  s.dependency 'GDataXML-HTML', '~> 1.2.0'
  s.frameworks   = 'WebKit'
end