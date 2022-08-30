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
	config=Config.new(configMap,customArguments,[],["Automation","Discover", "ECC"])
rescue Exception => ex
	raise ex.message + " does your automation config have a line for userScriptsLocation=some path? Expected file at: #{filePath}"
end

begin
	puts "#{$creds.keys.length.to_s} Credentials found"


	$automation=Automation.new($creds['automation']['server'],$creds['automation']['username'],$creds['automation']['password'])

	require 'json'
	#restore missing templates, so things like defaults or existings won't be overridden by accident.
	existingTemplates=$automation.getWorkflows().map{|workflow|workflow['templateMetadata']['name']}
	Dir.glob(userScriptsLocation + '/workflows/*.json').each do | workflowFilePath |
		workflowContents=JSON.parse(File.read(workflowFilePath))
		if(!(existingTemplates.include? workflowContents['templateMetadata']['name']))
			if(customArguments.has_key? "keepImmutable")
				if(customArguments["keepImmutable"]=="false")
					workflowContents['immutable']=false #force imported templates to be false... can change to be true if you want to protect the imported templates.
				end
			else
				workflowContents['immutable']=false #force imported templates to be false... can change to be true if you want to protect the imported templates.
			end
			id=$automation.uploadWorkflow(workflowContents)
			puts "Workflow uploaded:#{id}\n"
		end
	end

	$automation.getProfileTypes().each do | profileType |
		existingProfileNames=$automation.getProfiles(profileType).keys
		puts "$$#{profileType}$$"
		puts "'" + existingProfileNames.join("','") + "'"
		
		Dir.glob(userScriptsLocation + "/profiles/#{profileType}/*.xml").each do | profilePath |
			nameWithoutExtension=File.basename(profilePath,File.extname(profilePath))
			puts "#{profileType} Profile pending:#{profilePath}\n=========\n"
			if(!(existingProfileNames.include? nameWithoutExtension))
				begin
					id=$automation.uploadProfile(profileType,File.open(profilePath))
					puts "#{profileType} Profile uploaded:#{id}\n"
				rescue Exception => ex
					puts "Skipped #{profileType}/#{nameWithoutExtension}"
					puts ex.message
					puts ex.backtrace
				end
			end
		end
	end

	puts "validating credentials:"
	begin
		$discover=Discover.new($creds['discover']['token'])
		puts "Discover validated:#{$discover.getMyId()}"
	rescue Exception => ex
		puts "Discover Credentials could not be validated"
	end

	begin
		$ECC=ECC.new($creds['ecc']["username"], $creds['ecc']["password"],$creds['ecc']['server'])
		caseId=$ECC.getCaseIdFromName("Default")
		puts "ECC validated with Default case:#{caseId}"
	rescue Exception => ex
		puts "ECC Credentials could not be validated"
	end



	return "success"

rescue Exception => ex
	raise Exception.new(ex.message + "\n" + ex.backtrace.to_s)
end