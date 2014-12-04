Pod::Spec.new do |s|
  s.name         = "BMXSwipableCell"
  s.version      = "1.2.5"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.summary      = "A custom UITableViewCell that supports swipe to reveal"
  s.homepage     = "https://github.com/mbigatti/BMXSwipableCell"
  s.author       = { "Massimiliano Bigatti" => "@mbigatti" }
  s.source       = { :git => "https://github.com/mbigatti/BMXSwipableCell.git", :tag => "1.2.5" }
  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.frameworks   = 'UIKit'
  s.source_files = 'BMXSwipableCell', 'BMXSwipableCell/**/*.{h,m}'
end
