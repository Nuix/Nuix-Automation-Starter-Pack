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
	config=Config.new(configMap,customArguments,["apply_results_to_custom_metadata","apply_named_entities","apply_results_to_properties","apply_tags"],["NLP"])
rescue Exception => ex
	raise ex.message + " does your automation config have a line for userScriptsLocation=some path? Expected file at: #{filePath}"
end

## Fun begins here

begin
	nlpConfig=$creds['NLP']
	config.customArguments.each do |key,value|
		if(key=='apply')
			nlpConfig=value.split(';') # full options: "languages;sentiments;dictionaries;skillSets;geos;topics;profiles;annotations;risks;logging;documentvectors;imageprocessing;persons"
		else
			if(['true','false'].include? value.downcase())
				trueFalseValue=(value.downcase == 'true')
				nlpConfig[key]=trueFalseValue
			else
				puts "ERROR:#{value} is not a true/false"
				raise Exception.new("ERROR:#{value} is not a true/false")
			end
		end
	end
	
	$nlpClient=NLP.new(nlpConfig)
	if(!($nlpClient.isAvailable()))
		raise StandardError.new "Can't connect to NLP. Check Credentials and access"
	end
	
	config.set('nlp.config',nlpConfig)
	
rescue Exception => ex
	raise Exception.new(ex.message.to_s + "\n" +  ex.backtrace.to_s)
end