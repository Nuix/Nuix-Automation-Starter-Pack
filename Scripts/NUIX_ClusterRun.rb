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
	config=Config.new(configMap,customArguments,["name","query","resemblanceThreshold","useNearDuplicates","useEmailThreads"],[])
rescue Exception => ex
	raise ex.message + " does your automation config have a line for userScriptsLocation=some path? Expected file at: #{filePath}" + ex.backtrace.join("\n")
end

$name=customArguments['name']
$query=customArguments['query']
$resemblanceThreshold=customArguments['resemblanceThreshold'].to_f
$useNearDuplicates=(customArguments['useNearDuplicates'].downcase == "true")
$useEmailThreads=(customArguments['useEmailThreads'].downcase == "true")
 
items=currentCase.searchUnsorted($query)
 
options={
    "resemblanceThreshold"=>$resemblanceThreshold,
    "useNearDuplicates"=>$useNearDuplicates,
    "useEmailThreads"=>$useEmailThreads
}
 
puts "generating Cluster Run #{$name}"
currentCase.generateClusterRun($name, items, options)
puts "finished"