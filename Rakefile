require "xctasks"

XCTasks::TestTask.new(:spec) do |t|
  t.workspace = "iOSBuyer.xcworkspace"
  t.runner = :xctool

  t.subtask :IOS71iPhone4s_acceptance_tests do |s|
  	s.output_log = "test-reports/IOS71iPhone4s.xml"
  	s.runner = :xctool
    s.scheme = "AcceptanceTests"
    s.actions = %w{run-tests -reporter junit}
    s.destination("platform=iOS Simulator,OS=7.1,name=iPhone 4s")
  end

  t.subtask :IOS81iPhone4s_acceptance_tests do |s|
  	s.output_log = "test-reports/IOS81iPhone4s.xml"
  	s.runner = :xctool
    s.scheme = "AcceptanceTests"
    s.actions = %w{run-tests -reporter junit}
    s.destination("platform=iOS Simulator,OS=8.1,name=iPhone 4s")
  end

  t.subtask :IOS71iPhone5s_acceptance_tests do |s|
  	s.output_log = "test-reports/IOS71iPhone5s.xml"
  	s.runner = :xctool
    s.scheme = "AcceptanceTests"
    s.actions = %w{run-tests -reporter junit}
    s.destination("platform=iOS Simulator,OS=7.1,name=iPhone 5s")
  end

  t.subtask :IOS81iPhone5s_acceptance_tests do |s|
  	s.output_log = "test-reports/IOS81iPhone5s.xml"
  	s.runner = :xctool
    s.scheme = "AcceptanceTests"
    s.actions = %w{run-tests -reporter junit}
    s.destination("platform=iOS Simulator,OS=8.1,name=iPhone 5s")
  end

  t.subtask :IOS81iPhone6_acceptance_tests do |s|
  	s.output_log = "test-reports/IOS81iPhone6.xml"
  	s.runner = :xctool
    s.scheme = "AcceptanceTests"
    s.actions = %w{run-tests -reporter junit}
    s.destination("platform=iOS Simulator,OS=8.1,name=iPhone 6")
  end

  t.subtask :IOS81iPhone6Plus_acceptance_tests do |s|
  	s.output_log = "test-reports/IOS81iPhone6Plus.xml"
  	s.runner = :xctool
    s.scheme = "AcceptanceTests"
    s.actions = %w{run-tests -reporter junit}
    s.destination("platform=iOS Simulator,OS=8.1,name=iPhone 6 Plus")
  end
end

task :default => :spec