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
	config=Config.new(configMap,customArguments,["ndf.profileName"],[])
rescue Exception => ex
	raise ex.message + " does your automation config have a line for userScriptsLocation=some path? Expected file at: #{filePath}" + ex.backtrace.join("\n")
end

NdfProfileFile=(config.getConfigKey('userDataDirs') + '/NDF Profiles/' + config.customArguments['ndf.profileName'] + ".json")
if(!File.exists? NdfProfileFile)
	raise Exception.new ("File does not exist:" + NdfProfileFile)
end

config.set('ndf.profile.file',NdfProfileFile)
config.set('ndf.profile.name',config.customArguments['ndf.profileName'])