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
	config=Config.new(configMap,customArguments,['name','query','metadataProfileName'],["Xlsx"])
rescue Exception => ex
	raise ex.message + " does your automation config have a line for userScriptsLocation=some path? Expected file at: #{filePath}"
end

begin
	require 'fileutils'
	items=$currentCase.searchUnsorted(customArguments['query'])

	profile=$utilities.getMetadataProfileStore().getMetadataProfile(customArguments['metadataProfileName'])
	exportLocation=$currentCase.getLocation().to_s.gsub("\\","/") + "/reports/"
	require 'json'
	if(customArguments.has_key? 'exportFolderName')
		exportLocation=config.getConfigKey('ims.export.path.internal') + "/" + config.customArguments['exportFolderName']
	end
	if(exportLocation.include? "nvetory")
		puts customArguments.to_json() 
		return "oh dear type 2"
	end
	extension='xlsx'
	if(customArguments.has_key? 'extension')
		extension=customArguments['extension']
	end
	FileUtils.mkdir_p exportLocation
	
	reportLocation=exportLocation + "/" + customArguments['name'] + "." + extension
	reportLocation=reportLocation.gsub("/","\\")
	if(File.exist?(reportLocation))
		puts "Previous report deleted"
		File.delete(reportLocation) 
	end
	xlsx = Xlsx.new(reportLocation)
	sheet = xlsx.get_sheet(currentCase.getName()[0, 31])
	errorSheet=nil
	puts reportLocation
	#headers
	profile.getMetadata().each_with_index do | field,colIndex |
		sheet[0,colIndex]=field.getName()
	end

	#rows
	items.each_with_index do | item,rowIndex |
		profile.getMetadata().each_with_index do | field,colIndex |
			begin
				fieldValue=field.evaluate(item)[0, 32000] #first 32KB, actually.. in testing I found it fits 32700 characters but let's not push our limits hey
				sheet[rowIndex+1,colIndex]=fieldValue
			rescue => ex
				if(errorSheet.nil?)
					errorSheet=xlsx.get_sheet("Errors2")
					errorSheet[0,0]="Guid"
					errorSheet[0,1]="Error"
					errorSheet[0,2]="Full Trace"
				end
				thisRow=errorSheet.last_row() + 1
				errorSheet[thisRow,0]=item.getGuid()
				errorSheet[thisRow,1]=ex.message
				errorSheet[thisRow,2]=ex.backtrace.join("\n")
			end
		end
	end
	xlsx.save(nil,extension)
	return reportLocation
rescue Exception => ex
	
	begin
		errorStates=[]
		while(!ex.nil?)
			errorStates.push(ex.class.to_s + "\t" + ex.message)
			
			if(ex.respond_to? getCause)
				ex=ex.getCause()
			else
				ex=nil
			end
		end
		puts ex.backtrace
		return (ex.message + "\n" + reportLocation + "\n" + errorStates.join("\n"))
	rescue Exception => ex2
		puts ex2.backtrace
		return (ex.message + "\n" + reportLocation + "\n" + errorStates.join("\n"))
	end
end