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
	config=Config.new(configMap,customArguments,["directory"],[])
rescue Exception => ex
	raise ex.message + " does your automation config have a line for userScriptsLocation=some path? Expected file at: #{filePath}"
end

begin
	bugMessage=""
	somedir='//fsx.Nuixdemo.local/share/Nuix/exports/Automation/' + config.customArguments['directory']
	if(!(File.exists? somedir)) # BUG!! #@&^%$
		isWhatExpected=Dir["//fsx.Nuixdemo.local/share/Nuix/exports/Automation/" + currentCase.getName() + "/*"].select{|dir|Dir.exist? dir}.select{|dir|File.basename(dir).start_with? ("item_" + config.customArguments['directory'])}
		if(isWhatExpected.length > 0)
			somedir='//fsx.Nuixdemo.local/share/Nuix/exports/Automation/' + currentCase.getName()
			bugMessage=" Automation Bug... the export directory is wrong"
		end
	end
	require 'fileutils'
	FileUtils.remove_dir(somedir)
rescue Exception => ex
	raise Exception.new(ex.message + "\n" + ex.backtrace.to_s)
end

puts "Deleted Directory: #{somedir}" + bugMessage