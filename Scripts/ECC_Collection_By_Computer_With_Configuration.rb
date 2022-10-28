
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
	config=Config.new(configMap,customArguments,["case.name","configuration.name","computer.name"],["ECC"])
rescue Exception => ex
	raise ex.message + " does your automation config have a line for userScriptsLocation=some path? Expected file at: #{filePath}"
end

if(!(config.customArguments.has_key? 'collection.name'))
	#puts "collection.name is an expected key for this function"
	#raise Exception.new  "collection.name is an expected key for this function"
	#if missing take the case name
	config.customArguments['collection.name']=$currentCase.getName()
end


## Fun begins here

begin
	$ECC=ECC.new($creds['ecc']["username"], $creds['ecc']["password"],$creds['ecc']['server'])
	# setup
	caseId=$ECC.getCaseIdFromName(config.customArguments["case.name"])
	config.set('ecc.case.id',caseId)
	configurationId=$ECC.getConfigurationIdFromName(config.customArguments["configuration.name"])
	config.set('ecc.configuration.id',configurationId)
	collectionJobs=[]
	collectionIds=[]
	computerUUIDs=$ECC.getComputerUUIdsFromNames(config.customArguments["computer.name"])

	threads = []
	singleProcessingLock = Mutex.new
	computerUUIDs.each do | computerUUID |
		thread=Thread.new(computerUUID) { | thisComputerUUID |
			
			#collect by Computer name
			collectionId=$ECC.runCollectionByComputer($currentCase.getName() + "_" + thisComputerUUID,caseId,configurationId,thisComputerUUID)
			collectionIds.push(collectionId)
				
			#wait it out
			jobs=$ECC.waitForCollection(collectionId)
			jobs.each do | job |
				collectionJobs.push(job)
			end

			singleProcessingLock.synchronize {
				#add it to the nuix case, note: not all jobs are collection (launch etc) so this step will not always produce items in a case
				$ECC.addECCResultsToNuixCase(jobs)
			}
		}
		threads.push thread
	end
	puts "waiting for #{threads.length} collections"
	threads.each(&:join)

	config.set('ecc.computer.uuids',computerUUIDs)
	config.set('ecc.collection.id',collectionIds)
	config.set('ecc.collection.jobs',collectionJobs)
	
rescue Exception => ex
	raise Exception.new(ex.message.to_s + "\n" +  ex.backtrace.to_s)
end