Pod::Spec.new do |s|
  s.name         = "CSSNetworking"
  s.version      = "0.0.7"
  s.summary      = "一个灵活的网络框架（基于AFNetworking）。"
  s.license      = { :type => 'MIT License', :file => 'LICENSE' }
  s.authors      = { 'Joslyn' => 'cs_joslyn@foxmail.com' }
  s.homepage     = 'https://github.com/JoslynWu/CSSNetworking'
  s.social_media_url   = "http://www.jianshu.com/u/fb676e32e2e9"
  s.ios.deployment_target = '8.0'
  s.source       = { :git => 'https://github.com/JoslynWu/CSSNetworking.git', :tag => s.version.to_s }
  s.requires_arc = true

  s.public_header_files = 'CSSNetworking/CSSNetworking.h'
  s.source_files = 'CSSNetworking/CSSNetworking.h'


  s.subspec 'Core' do |ss|
    ss.dependency 'AFNetworking', '~> 3.1.0'
    ss.dependency 'CSSModel', '~> 0.0.5'
    ss.dependency 'CSSPrettyPrinted', '~> 0.1.2'
    ss.public_header_files = 'CSSNetworking/Core/*.{h}'
    ss.source_files = 'CSSNetworking/Core/*.{h,m}'
  end

  s.subspec 'ViewModel' do |ss|
    ss.dependency 'CSSOperation', '~> 0.0.3'
    ss.dependency "CSSNetworking/Core"
    ss.public_header_files = 'CSSNetworking/ViewModel/*.{h}'
    ss.source_files = 'CSSNetworking/ViewModel/*.{h,m}'
  end

end
