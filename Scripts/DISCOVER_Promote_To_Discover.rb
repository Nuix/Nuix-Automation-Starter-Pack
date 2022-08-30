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
	config=Config.new(configMap,customArguments,["productionSet.name"],[])
rescue Exception => ex
	raise ex.message + " does your automation config have a line for userScriptsLocation=some path? Expected file at: #{filePath}"
end

## Fun begins here

begin

	if(config.customArguments.has_key? "discover.caseId")
		config.set('discover.ClonedCaseId',config.customArguments['discover.caseId'])
	end
	if(!(config.has_key? "discover.ClonedCaseId"))
		puts "discover.caseId is an expected key for this function or a previously cloned case"
		raise Exception.new "discover.caseId is an expected key for this function or a previously cloned case: #{config.customArguments}"
	end

	productionItems=$currentCase.findProductionSetByName(config.customArguments['productionSet.name']).getProductionSetItems()

	require 'securerandom'
	$uuid=SecureRandom.uuid
	promoteToDiscoverOptions={
		'caseId'=> config.get('discover.ClonedCaseId'),
		'token'=>$creds['discover']['token'],
		'jobId'=>"Promote to Discover - " + $currentCase.getName() + " (" + $uuid + ")",
		'deduplication'=>false
	}
	exportPath='c:/temp/discover/#{$uuid}'
	productionSet=$currentCase.findProductionSetByName(config.customArguments['productionSet.name'])
	batchExporter=utilities.createBatchExporter(exportPath)
	batchExporter.setPromoteToDiscoverOptions(promoteToDiscoverOptions.to_java)
	$lastStage=nil
	batchExporter.whenItemEventOccurs do |callback |
		if(callback.getStage()!=$lastStage)
			$lastStage=callback.getStage()
			puts "Exporting Stage=#{callback.getStage()}"
		end
	end
	batchExporter.exportItems(productionSet)
	puts "Finished importing"
	begin
		FileUtils.remove_dir(exportPath)
	rescue Exception => ex
		puts (ex.message + "\n" + ex.backtrace.to_s)
	end
rescue Exception => ex
	raise Exception.new(ex.message + "\n" + ex.backtrace.to_s)
end


