Pod::Spec.new do |s|
  s.name         = "STGT"
  s.version      = "0.0.1"
  s.summary      = "STGT is Sys-Team GeoTracker."
  s.homepage     = "https://github.com/gogbajbobo/geotracking"

  s.license      = 'MIT'
  s.author       = { "Grigoriev Maxim" => "grigoriev.maxim@gmail.com" }
  s.source       = { :git => "https://github.com/gogbajbobo/geotracking.git", :branch => 'master'}
  s.platform     = :ios, '5.0'

  s.source_files = 'geotracking/*.lproj/STGT*.storyboard', 'geotracking/*.lproj/Localizable.strings', 'geotracking/Classes/STGT*.{h,m}', 'geotracking/DataModel/STGT*.{h,m,xcdatamodel,xcdatamodeld}'
  s.resources = 'geotracking/Resources/STGT*.{png,html,xml,js}', 'geotracking/DataModel/STGT*.{xcdatamodel,xcdatamodeld}'

  s.frameworks = 'SystemConfiguration', 'CoreData', 'MapKit', 'CoreLocation', 'UIKit', 'Foundation', 'CoreGraphics'
  s.library   = 'xml2'

  s.requires_arc = true

  s.dependency 'GData', '~> 1.9.1'
end
