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
	config=Config.new(configMap,customArguments,[],[])
rescue Exception => ex
	raise ex.message + " does your automation config have a line for userScriptsLocation=some path? Expected file at: #{filePath}"
end



context={}


begin
	if(!(defined?(NUIX_VERSION)))
		NUIX_VERSION=$currentCase.getBatchLoads().last().getDataSettings()['Software version']
	end
	if(!(config.customArguments.has_key? 'reportName'))
		config.customArguments['reportUser']='Case Summary Report from Nuix Automation'
	end
	
	require 'fileutils'
	exportLocation=$currentCase.getLocation().to_s.gsub("\\","/") + "/reports/Case Summary/"
	$rg=$utilities.getReportGenerator()
	FileUtils.mkdir_p exportLocation
	nrt = config.getConfigKey('userDataDirs') + "/Reports/Case Summary.nrt"
	context = {
		"NUIX_USER" => $currentCase.getInvestigator(),
		"NUIX_APP_NAME" => "Nuix",
		"NUIX_REPORT_TITLE" => config.customArguments['reportName'],
		"NUIX_APP_VERSION" => NUIX_VERSION,
		"LOCAL_RESOURCES_URL" => config.getConfigKey('userDataDirs') + "/Reports/Case Summary/resources/", #unzipped version of the nrt
		"currentCase"=>$currentCase,
		"utilities"=>$utilities,
		"dedupeEnabled" => true
	}
	if(config.customArguments.has_key? 'reportUser')
		context['NUIX_USER']=config.customArguments['reportUser']
	end
	if(context['NUIX_USER'].nil?)
		context['NUIX_USER']='Automation User'
	end
	outputFormat = "PDF"
	outputPath = exportLocation + "#{config.customArguments['reportName']}.pdf"
	counter=0
	success=false
	while((!success) && (counter < 10))
		begin
			$rg.generateReport(nrt, context.to_java, outputFormat, outputPath)
			success=true
			puts "Success on Attempt #{counter}"
		rescue Exception => ex
			sleep 1
			counter=counter + 1
		end
	end
	if(!success)
		#one last attempt to catch the error.
		$rg.generateReport(nrt, context.to_java, outputFormat, outputPath)
		puts "Success on Attempt #{counter}"
	end
	
rescue Exception => ex
	
	errorStates=[]
	while(!ex.nil?)
		errorStates.push(ex.class.to_s + "\t" + ex.message)
		ex=ex.getCause()
	end
	raise Exception.new(outputPath + "\n" + errorStates.join("\n"))
end