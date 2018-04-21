Pod::Spec.new do |s|
  s.name         = "CSSNetworking"
  s.version      = "0.0.1"
  s.summary      = "一个灵活的网络框架（基于AFNetworking）。"
  s.license      = { :type => 'MIT License', :file => 'LICENSE' }
  s.authors      = { 'Joslyn' => 'cs_joslyn@foxmail.com' }
  s.homepage     = 'https://github.com/JoslynWu/CSSNetworking'
  s.social_media_url   = "http://www.jianshu.com/u/fb676e32e2e9"
  s.ios.deployment_target = '8.0'
  s.source       = { :git => 'https://github.com/JoslynWu/CSSNetworking.git', :tag => s.version.to_s }
  s.requires_arc = true
  s.source_files = 'Sources/**/*.{h,m}'
  s.public_header_files = 'Sources/**/*.{h}'
  s.dependency 'CSSModel', '~> 0.0.3'
  s.dependency 'AFNetworking', '~> 3.1.0'
end
