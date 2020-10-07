require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name           = package['name']
  s.version        = package['version']
  s.summary        = package['summary']
  s.description    = package['description']
  s.author         = package['author']['name']
  s.license        = package['license']
  s.homepage       = package['homepage']
  s.source         = { :git => 'https://github.com/wonday/react-native-pdf.git', :tag => "v#{s.version}" }
  s.requires_arc   = true
  s.platform       = :ios, '8.0'
  s.source_files   = 'ios/**/*.{h,m}'
  s.dependency     'React-Core'
end
