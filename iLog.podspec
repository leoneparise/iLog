Pod::Spec.new do |s|
  s.name         = 'iLog'
  s.version      = '1.4.0'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage     = 'https://github.com/leoneparise/iLog'
  s.authors      = { 'Leone Parise' => 'leone.parise@gmail.com' }
  s.summary      = 'iLog log manager. Check you logs in your phone'
  s.description  = <<-EOS
  iLog is a drop in replacement to NSLog that allows to log using different strategies. 
  iLog offers two drivers by default, a nice log viewer interface and external storage helpers.
  EOS
  s.source       = { :git => 'https://github.com/leoneparise/iLog.git', :tag => s.version }
  s.platform     = :ios
  s.default_subspec = 'Core'
  s.ios.deployment_target = '9.0'

  s.subspec 'Core' do |core|
    core.source_files = 'iLog/*.swift'

    core.dependency 'SQLite.swift', '0.11.3'
    core.dependency 'SwiftDate', '~> 4.3.0'
    core.framework  = "Foundation"
    core.framework  = "UIKit"
  end

  s.subspec 'UI' do |ui|    
    ui.source_files = 'iLogUI/*.swift'    
    ui.resource = ['iLogUI/**/*.xib']
    ui.framework  = "UIKit"

    ui.dependency 'iLog/Core'
  end  
end
