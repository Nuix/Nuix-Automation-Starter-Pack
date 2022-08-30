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
	config=Config.new(configMap,customArguments,[],["Discover"])
rescue Exception => ex
	raise ex.message + " does your automation config have a line for userScriptsLocation=some path? Expected file at: #{filePath}"
end

## Fun begins here

begin
	$discover=Discover.new($creds['discover']['token'])

	userCategory="Administrator"
	if(config.customArguments.has_key? "user.category")
		userCategory=config.customArguments["user.category"]
	end
	userIds=[]
	if(config.customArguments.has_key? "user.names")
		if(config.customArguments.has_key? 'discover.orgName')
			userIds=$discover.convertUserListToIds(config.customArguments['user.names'].split(';'),config.customArguments['discover.orgName'])
		else
			userIds=$discover.convertUserListToIds(config.customArguments['user.names'].split(';'),config.get('discover.orgName'))
		end
	else
		userIds=[$discover.getMyId()]
	end

	if(userIds.length == 0)
		raise Exception.new "No users are found to assign?\n#{userDump.to_json}"
	end

	assignResult=$discover.assignUsersToCase(config.get('discover.ClonedCaseId'),userIds,userCategory)

	puts "Finished #{assignResult['successCount']} successful of #{assignResult['totalCount']}, No Change: #{assignResult['notChangedCount']}"
rescue Exception => ex
	raise Exception.new(ex.message + "\n" + ex.backtrace.to_s)
end