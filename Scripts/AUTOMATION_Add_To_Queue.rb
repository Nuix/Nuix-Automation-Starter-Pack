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
	config=Config.new(configMap,customArguments,["workflowName"],["Automation"])
rescue Exception => ex
	raise ex.message + " does your automation config have a line for userScriptsLocation=some path? Expected file at: #{filePath}"
end

if(!(customArguments.has_key? 'notify'))
	customArguments['notify']=[]
else
	customArguments['notify'].split(',')
end



## Fun begins here

begin
	$automation=Automation.new($creds['automation']['server'],$creds['automation']['username'],$creds['automation']['password'])

	workflow=$automation.getWorkflows().select{| workflow |workflow['templateMetadata']['name']==customArguments['workflowName']}[0]
	cazes=$automation.getCases()
	if(customArguments.has_key? 'caseName')
		cazes=cazes.select{| caze |caze['name']==customArguments['caseName']}
	end
	cazes.each do | caze |
		begin
			confirmation=$automation.scheduleJob(caze,workflow,customArguments["notify"],true) #true=migrate case
			puts "Schedule ID:#{confirmation['value']}\t#{caze['name']} has been scheduled for #{workflow['templateMetadata']['name']}, "
		rescue Exception => ex
			puts "ERROR:" + caze['name'] + ", " + ex.message
		end
	end
	return "all finished"
rescue Exception => ex2
	raise Exception.new(ex2.message + "\n" + ex2.backtrace.to_s)
end