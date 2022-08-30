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
	config=Config.new(configMap,customArguments,["query","exportFolderName","imagingProfile","regenerateStored"],[])
rescue Exception => ex
	raise ex.message + " does your automation config have a line for userScriptsLocation=some path? Expected file at: #{filePath}"
end

exportLocation=config.getConfigKey('ims.export.path.internal') + "\\" + config.customArguments['exportFolderName']
allItems=currentCase.searchUnsorted(config.customArguments['query'])
items=$utilities.getItemUtility().deduplicate(allItems)
be=$utilities.createBatchExporter(exportLocation)
be.setImagingProfile(config.customArguments['imagingProfile'])
options={
	"regenerateStored"=>config.customArguments['regenerateStored'],
	"naming"=>"md5"
}
be.addProduct('pdf',options)
be.exportItems(items)
require 'fileutils'
FileUtils.rm_rf(exportLocation + '/NATIVE')


return "Items exported to: #{exportLocation}"
