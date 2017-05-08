Pod::Spec.new do |s|
  s.name         = 'iLog'
  s.version      = '1.1.0'
  s.license      = { :type => 'MIT' }
  s.homepage     = 'https://github.com/leoneparise/iLog'
  s.authors      = { 'Leone Parise' => 'leone.parise@gmail.com' }
  s.summary      = 'iOS Log Manager'
  s.source       = { :git => 'https://github.com/leoneparise/iLog.git', :tag => s.version }
  s.platform     = :ios
  s.default_subspec = 'Core'
  s.ios.deployment_target = '8.2'

  s.subspec 'Core' do |core|
    core.source_files = 'iLog/*.swift'

    core.dependency 'SQLite.swift'
    core.dependency 'SwiftDate'
    core.framework  = "Foundation"
  end

  s.subspec 'UI' do |ui|    
  	ui.ios.deployment_target = '9.0'
    ui.source_files = 'iLogUI/*.swift'    
    ui.resource = ['iLogUI/**/*.xib']
    ui.framework  = "UIKit"

    ui.dependency 'iLog/Core'
  end  
end
