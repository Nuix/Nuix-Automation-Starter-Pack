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
	config=Config.new(configMap,customArguments,["organisation","caseToClone"],["Discover"])
rescue Exception => ex
	raise ex.message + " does your automation config have a line for userScriptsLocation=some path? Expected file at: #{filePath}"
end

## Fun begins here

begin
	$discover=Discover.new($creds['discover']['token'])
	
	caseDetails=$discover.getCasesByNameInOrg(config.customArguments['caseToClone'],config.customArguments['organisation'])
	caseId=caseDetails['id']
	orgId=caseDetails['organization']['id']
	
	clonedCase=$discover.cloneCase('auto-' + $currentCase.getGuid().to_s.split('-').first(),$currentCase.getName(),orgId,caseId)

	puts "Case Cloned, new Name:#{clonedCase['name']} with ID:#{clonedCase['id'].to_s}"
	
	rpfJobId=clonedCase['rpfJobId']
	clonedCaseId=clonedCase['id']
	
	dateFinished=nil
	while(dateFinished==nil)
		sleep 5
		status=$discover.checkRpfStatus(orgId,clonedCaseId,rpfJobId)
		dateFinished=status['dateFinished']
		puts "Current Status... #{status['status']}"
		if(status['status']=='Failed')
			raise Exception.new "Failed to clone case"
		end
	end
	
	config.set('discover.orgName',config.customArguments['organisation'])
	config.set('discover.orgId',orgId)
	config.set('discover.ClonedCaseId',clonedCase['id'])
	puts "Finished"
	return clonedCase.to_json()
rescue Exception => ex
	raise Exception.new(ex.message + "\n" + ex.backtrace.to_s)
end