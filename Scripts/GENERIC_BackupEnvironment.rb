#Unfortunately __FILE__ and Dir.pwd don't return useful location to require or load a rb file directory...
begin
	configMap={}
	filePath=(Dir.pwd + "/settings/application.properties")
	File.readlines(filePath).select{|line|(!(line.start_with? "#"))}.reject{|line|line.strip().length == 0}.each do |line|
		key,value=line.split('=',2)
		configMap[key]=value
	end
	userScriptsLocation=('"' + configMap['userScriptsLocation'] + '"').undump.strip()
	load userScriptsLocation + "/shared/Config.rb_"
	config=Config.new(configMap,customArguments,[],["Automation"])
rescue Exception => ex
	raise ex.message + " does your automation config have a line for userScriptsLocation=some path? Expected file at: #{filePath}"
end

require 'json'
require 'fileutils'

FileUtils.mkdir_p(userScriptsLocation + "/workflows")
$automation=Automation.new($creds['automation']['server'],$creds['automation']['username'],$creds['automation']['password'])
$automation.getWorkflows().each do | workflow |
	keep=true
	if(workflow['templateMetadata']['name'].include? "Default")
		if(customArguments["includeDefault"]!="true")
			keep=false
		end
	end
	if(keep)
		File.open(userScriptsLocation + "/workflows/" + workflow['templateMetadata']['name'] + ".json", 'w') { |file| file.write(JSON.pretty_generate(workflow)) }
	end
end

$automation.getProfileTypes().each do | profileType |
	$automation.getProfiles(profileType).each do | profileName,data |
		keep=true
		if(customArguments["includeDefault"]=="false")
			if(profileName.include? "Default")
				keep=false
			end
		end
		if(keep)
			FileUtils.mkdir_p(userScriptsLocation + "/profiles/#{profileType}")
			File.open(userScriptsLocation + "/profiles/#{profileType}/#{profileName}.xml", 'w') { |file| file.write(data) }
		end
	end
end

return "success"