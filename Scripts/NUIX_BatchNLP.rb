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
	config=Config.new(configMap,customArguments,["productionSetName","investigate_url"],["NLP"]) #"metadataProfile" is optional, "uploadThreads" is defaulted to 10 but you can change it here too.
rescue Exception => ex
	raise ex.message + " does your automation config have a line for userScriptsLocation=some path? Expected file at: #{filePath}" + ex.backtrace.join("\n")
end

productionSet=$currentCase.findProductionSetByName(config.customArguments['productionSetName'])
if(!(productionSet))
	raise StandardError.new "Production Set not found: #{config.customArguments['productionSetName']}"
end

mps=$utilities.getMetadataProfileStore()
metadataProfile=mps.createMetadataProfile() #empty profile, intentional... don't change it
if(!(config.customArguments["metadataProfile"].to_s.empty?))
	metadataProfile=mps.getMetadataProfile(config.customArguments["metadataProfile"])
end
#always add investigate url field, this is for graphana, later this will be removed as it's not required?
metadataProfile=metadataProfile.addMetadata("inv-url") do | currentItem |
	next config.customArguments['investigate_url'].to_s + "/cases/" + $currentCase.getGuid().to_s + "/search/grid?guids=" + currentItem.getGuid().to_s
end

uploadThreads=10
if(!(config.customArguments["uploadThreads"].to_s.empty?))
	uploadThreads=config.customArguments["uploadThreads"].to_i
end

$nlpClient=NLP.new($creds['NLP'])

if(!($nlpClient.isAvailable()))
	raise StandardError.new "#0 Can't connect to Gracie"
end

$nlpClient.batchNLP(productionSet,metadataProfile,uploadThreads)

cleanup = $nlpClient.cleanUp()
if(cleanup.nil?)
	$logger.error("Deletion of project failed")
else
	if(cleanup["response"].nil?)
		$logger.warn("Deletion of project might have worked but we are not sure.")
	else
		$logger.info("Deleted project #{cleanup["response"]["name"]}.")
	end
end