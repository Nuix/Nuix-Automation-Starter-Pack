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
	config=Config.new(configMap,customArguments,["query"],["Systran"])
rescue Exception => ex
	raise ex.message + " does your automation config have a line for userScriptsLocation=some path? Expected file at: #{filePath}"
end

require 'thread'
require 'json'


systran_config={
	"location"=>$creds['SYSTRAN']['server'],
	"key"=>$creds['SYSTRAN']['apiKey']
}
systran=Systran.new(systran_config['location'],systran_config['key'])
LANGUAGE_SOURCE='nuix-auto'
if(config.customArguments.has_key? 'language')
	LANGUAGE_SOURCE=config.customArguments['language']
end

targetLanguages=systran.languages.select{|languageDetails|((languageDetails["source"]==LANGUAGE_SOURCE) || (LANGUAGE_SOURCE.include? 'auto'))}.map{|languageDetails|languageDetails["target"]}.uniq.sort()
if(targetLanguages.include? ENV_JAVA["user.language"])
	targetLanguages=[ENV_JAVA["user.language"]] + (targetLanguages-[ENV_JAVA["user.language"]]) #put the users language at the top!
end
LANGUAGE_TARGET=targetLanguages[0]

$currentCase.withWriteAccess do
	iu=$utilities.getItemUtility()
	nuixItems=$currentCase.searchUnsorted('NOT custom-metadata:"language-id":* AND (' + config.customArguments['query'] + ')')
	itemIterator=nuixItems.iterator()
	
	
	total=nuixItems.size()
	systran.withBatch() do | batchId |
		puts "Starting Batch: #{batchId}"
		threads=[]
		threads << Thread.new do
			queued=0
			uploadThreads=[]
			itemTracker = Mutex.new
			statTracker = Mutex.new
			0.upto($creds['SYSTRAN']['connections']) do | threadIndex |
				sleep(0.5) #adding a tiny breather here in case cloudfare/DDoS is detected... This seems all that is needed
				uploadThreads << Thread.new do
					item=nil
					itemTracker.synchronize {
						if(itemIterator.hasNext())
							item=itemIterator.next()
						end
					}
					while(!item.nil?)
						statTracker.synchronize {
							queued=queued+1
							#dialog.setTranslateCurrent(queued)
							#dialog.setTranslateMessage("Queued:#{queued} items")
							puts("Queued:#{queued} items")
						}
						sourceLanguage=LANGUAGE_SOURCE
						if(sourceLanguage=='nuix-auto')
							sourceOptions=systran.languages.select{|l|l['source3Letter']==item.getLanguage()}
							if(sourceOptions.length > 0)
								sourceLanguage=sourceOptions.first()['source']
							else
								sourceLanguage='auto' #can't determine appropriate language from the possible options...
								puts "Can't locate translation option for Language:#{item.getLanguage()}"
							end
						end
						if(sourceLanguage == LANGUAGE_TARGET) #no point translating... e.g english to english.
							statTracker.synchronize {
								total=total-1
								#dialog.setTranslateMax(total)
								#dialog.setImportMax(total)
							}
						else
							systran.translate(sourceLanguage,LANGUAGE_TARGET,batchId,item)
						end
						itemTracker.synchronize {
							if(itemIterator.hasNext())
								item=itemIterator.next()
							else
								item=nil
							end
						}
					end
					
				end
			end
			uploadThreads.each(&:join)
			puts "finished queuing items"
			systran.closeBatch(batchId)
		end
		errors=0
		threads << Thread.new do
			translated=0
			systran.withBatchResults(batchId) do | sourceLanguage,item,translationResult,requestId |
				customMetadata=item.getCustomMetadata()
				if(translationResult.has_key? "error")
					errors=errors+1
					begin
						customMetadata.putText("Language-error-status",translationResult["error"]["status"])
						customMetadata.putText("Language-error-message",translationResult["error"]["message"])
						customMetadata.putText("Language-error-details",{"batchId"=>batchId,"requestId"=>requestId,"result"=>translationResult}.to_json)
					rescue Exception => ex
						puts ex
						puts ex.backtrace
					end
				else
					if(!translationResult.has_key? 'info')
						translationResult['info']={}
					end
					if(!(translationResult['info'].has_key? 'lid')) #using the user defined option
						translationResult['info']['lid']={
							'language'=>sourceLanguage,
							'confidence'=>1 #of course we are highly confident in users right? :P
						}
					end
					textBlob=item.getTextObject().toString()
					blob=textBlob + "\n\n============ TRANSLATED (#{translationResult['info']['lid']['language']} #{(translationResult['info']['lid']['confidence'] * 100).round(2)}%) ============\n\n" + translationResult["output"]
					begin
						item.modify do |item_modifier|
							item_modifier.replaceText(textBlob + "\n\n============ TRANSLATED (#{translationResult['info']['lid']['language']} #{(translationResult['info']['lid']['confidence'] * 100).round(2)}%) ============\n\n" + translationResult["output"])
						end
						begin
							customMetadata.putText("Language-id",translationResult['info']['lid']['language'])
							customMetadata.putFloat("Language-confidence",translationResult['info']['lid']['confidence'])
							translationResult['info']['stats'].each do | key, value|
								customMetadata.putInteger("Language-" + key,value)
							end
							customMetadata.remove("Language-error-status")
							customMetadata.remove("Language-error-message")
							customMetadata.remove("Language-error-details")
						rescue Exception => ex
							puts ex
							puts ex.backtrace
						end
						translated=translated+1
					rescue Exception => ex
						puts ex.message
						puts ex.backtrace
						errors=errors+1
						begin
							customMetadata.putText("Language-error-status",-2)
							customMetadata.putText("Language-error-message",ex.message)
							customMetadata.putText("Language-error-details",ex.backtrace)
						rescue Exception => ex
							puts ex
							puts ex.backtrace
						end
					end
				end
				#dialog.setImportCurrent(translated + errors)
				#dialog.setImportMessage("Imported:#{translated} items, #{errors} errors")
				puts("Imported:#{translated} items, #{errors} errors")
			end
			puts "finished importing items"
		end
		threads.each(&:join)
		puts "Finished translating #{total} items with #{errors} errors"
	end
end