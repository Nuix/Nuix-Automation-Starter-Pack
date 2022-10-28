require 'benchmark'
require 'date'
require 'java'
require 'json'
require 'net/http'
require 'pathname'
require 'securerandom'
require 'time'
require 'uri'


$logger=Java::OrgApacheLog4j::Logger.getRootLogger()

$nlpClient=nil

class NLP

	def applyWorkerItem(worker_item)
		@worker_item=worker_item
		@item_properties = worker_item.getSourceItem().getProperties()
		@searchResult=nil
	end
	
	def cleanUp()
		return post("#{@cfg["feed_service"]}/projects/delete?id=#{@cfg["gracie_project_id"]}", @cfg["headers"], "")
	end
	
	def createTask(item_text)
		task= post("#{@cfg["feed_service"]}/process-text-tasks/submit?projectId=#{@cfg["gracie_project_id"]}", @cfg["headers"], item_text)
		if(task.nil?) # had a few oddities coming back... testing for different scenarios for debug purposes.
			raise StandardError.new "#1 Can't connect to Gracie"
		end
		if(!(task.has_key? "response"))
			raise StandardError.new "#2 Can't connect to Gracie"
		end
		if(task["response"].nil?)
			raise StandardError.new "#3 Can't connect to Gracie"
		end
		if(!(task["response"].has_key? 'id'))
			raise StandardError.new "#4 Can't connect to Gracie"
		end
		if(task["response"]['id'].nil?)
			raise StandardError.new "#5 Can't connect to Gracie"
		end
		return task["response"]["id"]
	end
	
	def focusOnResult(seSearchResult)
		@searchResult=seSearchResult
		
		if(@searchResult['warnings'].select{|a|a.include? 'model currently loaded in a system for this language'}.size > 0)
			puts "SKIPPED:#{item.getGuid()}"
			return
		end
		newValues={}
		if(!(@searchResult.nil?))
			prefix="model.defaultModel."
			newValues[prefix + 'indexed']=true
			if(@searchResult.has_key? 'language')
				newValues[prefix + 'language']=@searchResult['language']['name']
			end
			
			if(@searchResult.has_key? 'dictionaryProximities')
				@searchResult['dictionaryProximities'].each do | record |
					newValues[prefix + 'dictionary.' + record['topicDictionaryName'] + '.indexed']=true
					newValues[prefix + 'dictionary.' + record['topicDictionaryName'] + '.proximity']=record['proximity']
					record['topicTypeProximities'].each do | topicRecord |
						newValues[prefix + 'dictionary.' + record['topicDictionaryName'] + '.topic.' + topicRecord['topicTypeName'] + '.indexed']=true
						newValues[prefix + 'dictionary.' + record['topicDictionaryName'] + '.topic.' + topicRecord['topicTypeName'] + '.proximity']=topicRecord['proximity']
					end
				end
			end
			if(@searchResult.has_key? 'skillsetProximities')
				@searchResult['skillsetProximities'].each do | record |
					newValues[prefix + 'skillsets.' + record['skillsetName'] + '.indexed']=true
					record['skills'].each do | topicRecord |
						newValues[prefix + 'skillsets.' + record['skillsetName'] + '.skill.' + topicRecord['skillName'] + '.indexed']=true
						newValues[prefix + 'skillsets.' + record['skillsetName'] + '.skill.' + topicRecord['skillName'] + '.proximity']=topicRecord['proximity']
					end
				end
			end
			if(@searchResult.has_key? 'riskValues')
				@searchResult['riskValues']['summaryRisk'].each do | topicRecord,value |
					newValues[prefix + 'risk.summaryRisk.indexed']=true
					newValues[prefix + 'risk.summaryRisk.' + topicRecord]=value
				end
				if(@searchResult['riskValues'].has_key? 'classifierRisk')
					@searchResult['riskValues']['classifierRisk'].each do | classifierRiskType, records|
						newValues[prefix + 'risk.classifierRisk.indexed']=true
						newValues[prefix + 'risk.classifierRisk.riskType.' + classifierRiskType + '.indexed']=true
						records.each do | record |
							newValues[prefix + 'risk.classifierRisk.riskType.' + classifierRiskType + '.riskName.' + record['classifierName'] + '.classifierGroup']=record['classifierGroup']
							newValues[prefix + 'risk.classifierRisk.riskType.' + classifierRiskType + '.riskName.' + record['classifierName'] + '.indexed']=true
							newValues[prefix + 'risk.classifierRisk.riskType.' + classifierRiskType + '.riskName.' + record['classifierName'] + '.relevanceValue']=record['relevanceValue']
							newValues[prefix + 'risk.classifierRisk.riskType.' + classifierRiskType + '.riskName.' + record['classifierName'] + '.riskValue']=record['riskValue']
						end
					end
				end
				if(@searchResult['riskValues'].has_key? 'entityRisk')
					newValues[prefix + 'risk.entityRisk.indexed']=true
					@searchResult['riskValues']['entityRisk'].each do | entityType, records|
						newValues[prefix + 'risk.entityRisk.riskType.' + entityType + '.indexed']=true
						record=records.first()
						newValues[prefix + 'risk.entityRisk.riskType.' + entityType + '.entityCount']=record['entityCount']
						newValues[prefix + 'risk.entityRisk.riskType.' + entityType + '.riskValue']=record['riskValue']
					end
				end
			end
		end
		
		newValues.each do | fieldName,value |
			type='text'
			if(value.kind_of? Float)
				type='float'
			end
			if(value.kind_of? Integer)
				type='float'
			end
			if([true,false].include? value)
				type='boolean'
			end
			filtered=fieldName.gsub(/[^\w| \&\/\_\-\,\.]/,'')
			safeFieldName=filtered.gsub("\s",'-').strip()
			@worker_item.addCustomMetadata(safeFieldName, value, type,'nlp')
		end
		if(@searchResult.has_key? 'annotationSet')
			#named entities are being ignored for now... only keeping compound lexemes as per chat with John K/Liam
			@searchResult['annotationSet']['Compound Lexemes'].each do | record|
				normalisedName="nlp_" + record['source'].downcase().gsub(/\s/,"-")
				entity=@worker_item.createEntity(normalisedName, record['text'])
				@worker_item.addNamedEntity(entity)
			end
		end
	end
	
	def getTaskStatus(task_id)
		return post("#{@cfg["feed_service"]}/tasks/retrieve?id=#{task_id}", @cfg["headers"], "")
	end
	
	def getToken(base_url)
		uri = URI.parse("#{base_url}/sso/oauth/token")
		https = Net::HTTP.new(uri.host, uri.port)
		https.verify_mode = OpenSSL::SSL::VERIFY_NONE
		https.use_ssl=true
		headers = {"Content-Type" => "Content-Type: multipart/form-data", "Authorization" => "Basic #{@cfg["authorization"]}"}
		begin
			request = Net::HTTP::Post.new(uri.request_uri, headers)
			request.set_form_data("grant_type" => "#{@cfg["grant_type"]}","Gracie_id" => "#{@cfg["Gracie_id"]}","Gracie_secret" => "#{@cfg["Gracie_secret"]}","username" => "#{@cfg["username"]}","password" => "#{@cfg["password"]}")
			response = https.request(request)
			$logger.trace("Call to #{uri} returned #{response.code}.")
			if response.body != nil
				begin
					return JSON.parse(response.body)
				rescue
					$logger.warn("Unable to parse response from translation service or it's blank.")
				end
			end
		rescue => ex
			$logger.warn(ex.message)
			$logger.warn(ex.backtrace.to_s)
		end
	end
	
	def initialize(cfg)
		@available=false
		@cfg=cfg

		
		begin
			gracie_uri = URI::parse(@cfg["feed_service"])
			token = getToken("#{gracie_uri.scheme}://#{gracie_uri.host}")
			access_token = token["access_token"]
			@cfg["gracie_access_token"] = access_token
			token_type = token["token_type"]
			refresh_token = token["refresh_token"]
			expires_in = token["expires_in"]
			scope = token["scope"]
			$logger.info("Acquired Gracie token [access_token=#{access_token},token_type=#{token_type},refresh_token=#{refresh_token},expires_in=#{expires_in},scope=#{scope}]")
			@cfg["headers"] = {"Content-Type" => "plain/text;charset=UTF-8", "authorization" => "Bearer #{access_token}"}
			$logger.debug("Configuration:\n" + @cfg.to_json)
			info = post("#{@cfg["dictionary_service"]}/info/retrieve", @cfg["headers"], "")
			status = info["status"]
			message = info["message"]
			code = info["code"]
			response = info["response"]
			server = response["server"]
			systeminfo = response["system"]
			search = response["search"]

			$logger.info("Gracie Server Info: #{server}")
			$logger.info("Gracie System Info: #{systeminfo}")
			$logger.info("Gracie Search Info: #{search}")

			project = post("#{@cfg["feed_service"]}/projects/add?name=nuix-#{SecureRandom.uuid}", @cfg["headers"], "")
		
			$logger.debug("Project Creation Response: #{project}")
			project_id = project["response"]["id"]
			project_name = project["response"]["name"]
			es_index = project["response"]["elasticsearchIndexName"]

			$logger.info("Gracie Project #{project_name} (ID:#{project_id}) created.")
			@cfg["gracie_project_name"] = project_name
			@cfg["gracie_project_id"] = project_id
			
			
			
			@available=true
		rescue => ex
			$logger.warn(ex.message)
			$logger.warn(ex.backtrace.to_s)
			$logger.warn(@cfg.to_json)
		end
	end
	
	def isAvailable()
		return @available
	end
	
	def post(url, headers, body)
		uri = URI.parse(url)
		$logger.debug("Preparing to post to #{uri}")
		https = Net::HTTP.new(uri.host, uri.port)
		https.verify_mode = OpenSSL::SSL::VERIFY_NONE
		https.use_ssl=true
		begin
			request = Net::HTTP::Post.new(uri.request_uri, headers)
			request.body = body
			response = https.request(request)
			$logger.trace("Call to #{url} returned #{response.code}.")
			if response.body != nil
				begin
					return JSON.parse(response.body)
				rescue
					$logger.warn("Unable to parse response from translation service or it's blank.")
				end
			end
		rescue => ex
			$logger.warn(ex.message)
			$logger.warn(ex.backtrace.to_s)
		end
	end
	
	
	def waitForTask(task_id)
		$logger.info("Waiting for task")
		task_status=$nlpClient.getTaskStatus(task_id)
		
		if(!(task_status.has_key? "response"))
			$logger.warn("Type 1 wait failure:#{task_status.to_json}")
			raise "Expected a 'response' element in the JSON but didn't find one."
		end
		if(!(task_status["response"].has_key? "status"))
			$logger.warn("Type 2 wait failure:#{task_status["response"].to_json}")
			raise "Expected a 'status' element in the JSON but didn't find one."
		end
		if(!(task_status["response"].has_key? "result"))
			$logger.warn("Type 3 wait failure:#{task_status["response"].to_json}")
			raise "Expected a 'result' element in the JSON but didn't find one."
		end
		
		
		status = task_status["response"]["status"]
		$logger.info("Waiting for task: #{status}")

		$logger.debug("Status: #{status}")
		result=nil
		killswitch = 0
		while status == "Running"
			sleep 2
			killswitch = killswitch + 1
			task_status=$nlpClient.getTaskStatus(task_id)
			status = task_status["response"]["status"]

			$logger.debug("Status: #{status}")
			if(killswitch > 10)
				raise StandardError.new "Waiting for Task has timed out."
			end
		end
		
		if(!(task_status["response"]["result"].nil?))
			if(task_status["response"]["result"].has_key? "result")
				result = task_status["response"]["result"]["result"]
			else
				$logger.warn("Type 4 wait warning:#{task_status["response"].to_json}")
				raise "Expected a 'result/result' element in the JSON but didn't find one."
			end
		end
		#@worker_item.addMetadata("gracie-status", status, "text", "api")
		#addCustomMetadata("gracie-result", result, "text", "user")
		
		
		#in my testing this happens in two scenarios, inadequate text OR too much noise.
		if((status=='Completed') && (result.nil?))
			return nil
		end
		
		if(!(result.has_key? "seSearchResult"))
			$logger.warn(task_status["response"].to_json)
			$logger.warn("=====")
			$logger.warn(result.to_json)
			raise "Expected a 'seSearchResult' element in the JSON but didn't find one."
		end
		if(result["seSearchResult"].nil?)
			$logger.warn(task_status["response"].to_json)
			$logger.warn("=====")
			$logger.warn(result.to_json)
			raise "Expected a 'seSearchResult' element in the JSON but didn't find anything there"
		end
		return result["seSearchResult"]
	end
	
end

def initNLP(workerItem)
	if($nlpClient.nil?)
		# Read from the config file in the case directory.
		# Allows for headless, i.e. Nuix Automation!
		caseRoot=workerItem.getWorkerStoreDir().getParent().getParent().to_s
		configPath=caseRoot + "/config_nlp.config.json"
		cfg=JSON.parse(File.read(configPath))
		$nlpClient=NLP.new(cfg)
	end
end


def nuix_worker_item_callback_init()
	# to not break existing GUI implementation
	cfg={}
	
	if(!(cfg=={}))
		$nlpClient=NLP.new(cfg)
	end
end

def nuix_worker_item_callback(worker_item)
	begin
	
		# Init is only called if gracie isn't already available. This is for configuration read from a case directory (Nuix Automation)
		initNLP(worker_item)
		$nlpClient.applyWorkerItem(worker_item)
		if(!($nlpClient.isAvailable()))
			raise StandardError.new "#0 Can't connect to Gracie"
		end
		
		source_item = worker_item.source_item
		$logger.trace("WSS Callback fired for #{source_item.name} (guid:#{worker_item.get_item_guid})")
		sourceText=source_item.getText()
		if(sourceText.isAvailable())
			item_text = sourceText.toString()
			if !item_text.nil? && !item_text.empty?
				$logger.debug("Asking my girl Gracie about this #{source_item.type.name} named '#{source_item.name}'.")
				task_id = $nlpClient.createTask(item_text)
				$logger.info("Submitted text processing task. (Task ID: #{task_id})")

				seSearchResult=$nlpClient.waitForTask(task_id)
				if(!(seSearchResult.nil?))
					$nlpClient.focusOnResult(seSearchResult)
				end
			end
		
		else
			$logger.warn("Source Item Text is not available:#{worker_item.getItemGuid()}")
		end
	rescue => ex
		worker_item.addTag("NLP|ERROR") # This isn't going through gracie client to ensure these are tagged regardless of config
		$logger.warn(ex.message)
		worker_item.addTag("NLP|ERROR|#{ex.message}")
		$logger.warn(ex.backtrace.to_s)
		worker_item.addMetadata("nlp-error-message", ex.message, "text", "user")
		worker_item.addMetadata("nlp-error-backtrace", ex.backtrace, "text", "user")
	end
end

def nuix_worker_item_callback_close()
	begin
		if(!($nlpClient.nil?))
			cleanup = $nlpClient.cleanUp()
			$logger.info("Deleted project #{cleanup["response"]["name"]}.")
		end
	rescue => ex
		$logger.warn(ex.message)
		$logger.warn(ex.backtrace.to_s)
	end
end