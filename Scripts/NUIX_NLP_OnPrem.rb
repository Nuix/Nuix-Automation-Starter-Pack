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
	config=Config.new(configMap,customArguments,["query"],[]) #,"includeFamilies","updateDuplicates"
rescue Exception => ex
	raise ex.message + " does your automation config have a line for userScriptsLocation=some path? Expected file at: #{filePath}"
end

## Fun begins here

begin

	items = currentCase.searchUnsorted(config.customArguments['query'])
	puts "item count = #{items.size}"
	if(items.size == 0)
		raise Exception.new("No items matched the query")
	end
	puts 'Analyzing (on Prem)...'

	require 'json'
	script = File.read(userScriptsLocation + "/shared/nlp_on_prem_wss.rb")
	config.set('nlp.config',$creds['NLPONPREM'])
	processor = $current_case.create_processor()
	processor.parallel_processing_settings = {
		"worker_count"=> 8,
		"worker_memory"=>2000
	}
	processor.processing_settings = {
		"worker_item_callback"=>"ruby:#{script}"
	}
	processor.reload_items_from_source_data(items)

	start = Time.now
	puts "starting NLP processing... #{start}"
	processor.process
	finish = Time.now
	puts "finished NLP processing... #{finish}"

	puts "Creating Search Macros"
	require 'fileutils'
	$macroStoreLocation=$currentCase.getLocation().to_s + '/Stores/User Data/Search Macros/'
	puts "building macros"

	$breakoutHash=nil
	$caseSummaryHash=nil
	def getVisualisationPath(path)
		while(path != File.dirname(path))
			target_path= File.dirname(path)
			puts (target_path + ";")
			if(File.directory? target_path + '/visualizationConfig')
				puts (";success! " + target_path + '/visualizationConfig')
				return target_path + '/visualizationConfig'
			else
				path=target_path
			end
		end
		puts (";Fail... not found")
		puts ("userScriptsLocation:#{userScriptsLocation}")
		return nil
	end


	$visualisationPath=getVisualisationPath(userScriptsLocation.gsub("\\","/"))

	if(!($visualisationPath.nil?))
		begin
			require 'json'
			file = File.read($visualisationPath + '/breakout.json')
			breakouts = JSON.parse(file)
			$breakoutHash={}
			breakouts.each do | breakout |
				$breakoutHash[breakout['name']]=breakout
			end
			file = File.read($visualisationPath + '/caseSummary.json')
			summaries=JSON.parse(file)
			$caseSummaryHash={}
			summaries.each do | summary |
				$caseSummaryHash[summary['name']]=summary
			end
		rescue Exception => ex
			#more than likely the file doesn't exist... currently Investigate and Automation are not compatible... so this file needs to be on a shared resource in order to access it.
		end
	end


	def buildMacro(path,name,query)
		#validating query
		#puts "Validating query\n#{query}"
		#can't validate query in on Prem because... the nlp cache hasn't been initialised yet (is done on the next open close case).
		#$currentCase.search(query,{'limit'=>0})
		FileUtils.mkdir_p $macroStoreLocation + path
		macroPath=$macroStoreLocation.gsub("\\","/") + path + '/' + name.strip() + '.macro'
		begin
			File.open(macroPath, 'w') { |file| file.write(query) }
		rescue Exception => ex
			puts "Could not write to:#{macroPath}"
		end
		if(!($breakoutHash.nil?))
			if(!($breakoutHash.has_key? path))
				$breakoutHash[path]={
					"name"=>path,
					"breakoutQueries"=>[]
				}
			end

			if($breakoutHash[path]["breakoutQueries"].select{|existing|existing['name']==name}.size() == 0)
				blob={
					"name"=>name,
					"icon"=>"Nuix_Icon_8.png",
					"query"=>query,
					"metadataProfile"=>"",
					"view"=>"grid"
				}
				$breakoutHash[path]["breakoutQueries"].push(blob)
			end
		end
		if(!($caseSummaryHash.nil?))
			if(!($caseSummaryHash.has_key? path))
				$caseSummaryHash[path]={
					"name"=>path,
					"caseSummaryQueries"=>[]
				}
			end

			if($caseSummaryHash[path]["caseSummaryQueries"].select{|existing|existing['name']==name}.size() == 0)
				blob={
					"name"=>name,
					"query"=>query,
					"metadataProfile"=>"",
					"view"=>"grid"
				}
				$caseSummaryHash[path]["caseSummaryQueries"].push(blob)
			end
		end
	end

	currentCase.getCustomMetadataFields().select{|field|field.include? 'Doctypes'}.select{|field|field.include? 'proximity'}.each do | docType|
		query='nlp:"' + docType + '":[0.7 TO *]'
		parts=docType.split('.').reverse()
		docTypeName=parts[1]
		begin
			buildMacro('Document Type/' + parts[3].split('-').last().strip(),docTypeName,query)
		rescue Exception => ex
			puts("something wrong with docTypes? #{docType}")
		end
	end

	currentCase.getCustomMetadataFields().select{|field|field.include? 'dictionary'}.select{|field|field.include? 'proximity'}.each do | docType|
		query='nlp:"' + docType + '":[0.7 TO *]'
		parts=docType.split('.').reverse()
		docTypeName=parts[1]
		buildMacro('Dictionary/' + parts[3].split('-').last().strip(),docTypeName,query)
	end

	currentCase.getCustomMetadataFields().select{|field|field.include? 'skillset'}.select{|field|field.include? 'proximity'}.each do | docType|
		query='nlp:"' + docType + '":[0.7 TO *]'
		parts=docType.split('.').reverse()
		docTypeName=parts[1]
		buildMacro('Dictionary/' + parts[3].split('-').last().strip(),docTypeName,query)
	end

	currentCase.getCustomMetadataFields().select{|field|field.include? "riskName"}.select{|field|field.include? "indexed"}.each do | riskType|
		query='nlp:"' + riskType + '":true'
		riskName=riskType.split('.').reverse()[1]
		buildMacro('Risk Type',riskName,query)
	end

	currentCase.getCustomMetadataFields().select{|field|field.include? "summaryRisk"}.reject{|field|field.include? "indexed"}.each do | riskType|
		riskName=riskType.split('.').reverse()[0]
		query='nlp:"' + riskType + '":'
		buildMacro('Risk/' + riskName,"High " + riskName,query + '[0.75 TO *]')
		buildMacro('Risk/' + riskName,"Medium " + riskName,query + '[0.25 TO 0.75}')
		buildMacro('Risk/' + riskName,"Low " + riskName,query + '[0 TO 0.25}')
	end

	currentCase.getAllEntityTypes().reject{|entity|entity.start_with? "nlp_"}.each do | entity |
		buildMacro('Entities/Default',entity.split(/[-_]+/).map{|a|a.capitalize()}.join(' '),'named-entities:"' + entity + ';*"')
	end

	currentCase.getAllEntityTypes().select{|entity|entity.start_with? "nlp_"}.each do | entity |
		buildMacro('Entities/Contextual',entity.gsub('nlp_','').split(/[-_]+/).map{|a|a.capitalize()}.join(' '),'named-entities:"' + entity + ';*"')
	end



	topDocTypes={}
	topRiskTypes={}
	currentCase.searchUnsorted('custom-metadata:"model.defaultModel.indexed":true').each do | item |
		meta=item.getCustomMetadata()
		docType=meta.keys.select{|key|key.include? "Doctypes"}.select{|key|key.include? '.skill.'}.select{|key|key.end_with? 'proximity'}.sort_by{|key|-meta[key]}.first()
		if(!(docType.nil?))
			docTypeName=docType.split('.').reverse()[1]
			if(!(topDocTypes.has_key? docTypeName))
				topDocTypes[docTypeName]=[]
			end
			
			topDocTypes[docTypeName].push(item)
		end
		
		risk=meta.keys.select{|key|key.end_with? "riskValue"}.sort_by{|key|-meta[key]}.first()
		if(!(risk.nil?))
			riskName=risk.split('.').reverse()[1]
			if(!(topRiskTypes.has_key? riskName))
				topRiskTypes[riskName]=[]
			end
			topRiskTypes[riskName].push(item)
		end
	end

	ba=$utilities.getBulkAnnotater()
	topDocTypes.each do | key,items|
		#puts "'nlp.topDocType', #{key}, #{items.size()}"
		ba.putCustomMetadata('nlp.topDocType', key, items, nil)
		buildMacro("Document Type/Top Types",key,"custom-metadata:\"nlp.topDocType\":\"#{key}\"")
	end

	topRiskTypes.each do | key,items|
		#puts "'nlp.topRiskType', #{key}, #{items.size()}"
		ba.putCustomMetadata('nlp.topRiskType', key, items, nil)
		buildMacro("Risk Types/Top Types",key,"custom-metadata:\"nlp.topRiskType\":\"#{key}\"")
	end

	if(!($visualisationPath.nil?))
		File.write($visualisationPath + '/breakout.json',JSON.pretty_generate($breakoutHash.values))
		File.write($visualisationPath + '/caseSummary.json',JSON.pretty_generate($caseSummaryHash.values))
	end
	
rescue Exception => ex
	raise Exception.new("Items: #{items.size}\n" + ex.message.to_s + "\n" +  ex.backtrace.to_s)
end























