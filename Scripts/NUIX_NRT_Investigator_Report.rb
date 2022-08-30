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

require 'json'
begin
	$startingLicence=$utilities.getLicence()
	if(!(defined?(NUIX_VERSION)))
		NUIX_VERSION=$currentCase.getBatchLoads().last().getDataSettings()['Software version']
	end
	if(!(config.customArguments.has_key? 'reportName'))
		config.customArguments['reportUser']='Investigator Report from Nuix Automation'
	end
	exportLocation=$currentCase.getLocation().to_s + "/reports/Investigator Report/"
	$rg=$utilities.getReportGenerator()
	
	nrt = config.getConfigKey('userDataDirs') + "/Reports/Investigator Report.nrt"

	settings={
		"report_directories": {
			"html_resources": "resources",
			"exported_files": "products",
			"item_licenceDetails": "items"
		},
		"products": [
			{
				"type": "native"
			},
			{
				"type": "text"
			},
			{
				"type": "pdf",
				"regenerateStored": false
			},
			{
				"type": "thumbnail"
			}
		],
		"case_information": {
			"Name": "priv1.edb",
			"Investigator": "Cameron Stiller"
		},
		"imaging_settings": {
			"imageExcelSpreadsheets": false
		},
		"additional_files": [],
		"parallel_export_settings": {
			"worker_count": "2",
			"worker_memory": "2048"
		},
		"summary_reports": [
			{
				"idx": 0,
				"selected": true,
				"title": "NDF",
				"tag": "NDF",
				"disable_export": false,
				"sort": "Item Position",
				"profile": "Default"
			}
		],
		"output_directory": exportLocation,
		"item_licenceDetails": {
			"include_profile": "Default",
			"include_tags": true,
			"include_text": true,
			"include_custom_metadata": true,
			"include_properties": true,
			"include_comments": true
		},
		"add_on": {
			"selectedCV": "",
			"selectedDefinition": ""
		},
	}

	
	context = {
		"NUIX_USER" => $currentCase.getInvestigator(),
		"NUIX_APP_NAME" => 'Nuix',
		"NUIX_REPORT_TITLE" => config.customArguments['reportName'],
		"NUIX_APP_VERSION" => NUIX_VERSION,
		"LOCAL_RESOURCES_URL" => config.getConfigKey('userDataDirs') + "/Reports/Investigator Report/resources/",
		"currentCase"=> $currentCase,
		"utilities"=> $utilities,
		"reportSettings" => JSON.pretty_generate(settings)
	}
	if(config.customArguments.has_key? 'reportUser')
		context['NUIX_USER']=config.customArguments['reportUser']
	end
	if(context['NUIX_USER'].nil?)
		context['NUIX_USER']='Automation User'
	end
	outputFormat = 'HTML'
	outputPath = exportLocation + "report.html"
	$utilities.getReportGenerator.generateReport(nrt, context.to_java, outputFormat, outputPath)
rescue Exception => ex
	errorStates=[]
	while(!ex.nil?)
		errorStates.push(ex.class.to_s + "\t" + ex.message)
		ex=ex.getCause()
	end
	raise Exception.new(outputPath + "\n" + errorStates.join("\n"))
end