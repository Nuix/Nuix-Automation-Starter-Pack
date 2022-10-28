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
	config=Config.new(configMap,customArguments,["query","entities","markup.name","is.redaction"],[])
rescue Exception => ex
	raise ex.message + " does your automation config have a line for userScriptsLocation=some path? Expected file at: #{filePath}"
end


## Fun begins here

items=[]
begin
	
	#Based on https://github.com/Nuix/SuperUtilities/blob/master/RubyTests/BulkRedactor.rb
	# requires the SuperUtilities.jar to be in the lib directory
	
	
	# Initialize super utilities
	temp_directory = "C:\\Temp\\BulkRedactorTemp"
	markup_set_name = config.customArguments["markup.name"]
	expressions = []
	entity_types = config.customArguments["entities"].split(';')

	items = $currentCase.search(config.customArguments["query"])
	puts "Operating on:#{items.size()} items"

	require File.join(userScriptsLocation + "/lib/","SuperUtilities.jar")
	java_import com.nuix.superutilities.annotations.BulkRedactor
	java_import com.nuix.superutilities.annotations.BulkRedactorSettings
	java_import com.nuix.superutilities.SuperUtilities
	puts "Using version:#{config.getNUIX_VERSION()}"
	$su = SuperUtilities.init($utilities,config.getNUIX_VERSION())
	# Create settings object and then configure settings
	brs = BulkRedactorSettings.new
	brs.setMarkupSetName(markup_set_name)
	brs.setTempDirectory(temp_directory)
	brs.setExpressions(expressions)
	brs.setNamedEntityTypes(entity_types)
	if(config.customArguments["is.redaction"])
		brs.setApplyRedactions(true)
	else
		brs.setApplyHighLights(false)
	end

	# Create bulk redactor
	br = BulkRedactor.new

	# Add callback for messages it logs
	br.whenMessageLogged do |message|
		puts message
	end

	# Find and markup expressions based on settings, this then returns
	# NuixImageAnnotationRegion objects for each match found
	regions = br.findAndMarkup($currentCase,brs,items,4)

	# Iterate each found region and print summary about it
	regions.each do |region|
		puts region.toString
	end

	
rescue Exception => ex
	raise Exception.new("Items: #{items.size}\n" + ex.message.to_s + "\n" +  ex.backtrace.to_s)
end

