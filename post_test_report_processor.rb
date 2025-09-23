#!/usr/bin/ruby
require "nokogiri"

class PostTestReportProcessor
	def self.process
		workspace_path = File.expand_path(File.dirname(__FILE__))
		test_reports_directory_path = (workspace_path + "/test-reports/*")
		test_files = Dir.glob(test_reports_directory_path).select{ |e| File.file? e }
		puts "TEST FILES: " + test_files.join(", ")
		test_files.each do |filename|
			self.update_test_xml_for_file(filename)
		end
	end

	def self.update_test_xml_for_file(filename)
		document = Nokogiri::XML(File.read(filename))
		document.xpath("//testcase").each do |node|
			node["classname"] = ( File.basename(filename, ".xml") + "." + node["classname"])
		end
		File.open(filename, "w+") do |file|
			file.write document.to_xml
		end
	end
end

if __FILE__ == $0
	PostTestReportProcessor.process
end