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
	config=Config.new(configMap,customArguments,[],["Automation"])
rescue Exception => ex
	raise ex.message + " does your automation config have a line for userScriptsLocation=some path? Expected file at: #{filePath}"
end

begin
	puts "#{$creds.keys.length.to_s} Credentials found"


	$automation=Automation.new($creds['automation']['server'],$creds['automation']['username'],$creds['automation']['password'])


	$gapSizeX=200
	$gapSizeY=100
	if(customArguments.has_key? "x")
		$gapSizeX=customArguments['x'].to_i
	end
	if(customArguments.has_key? "y")
		$gapSizeY=customArguments['y'].to_i
	end
	require 'json'

	def getStepById(id,steps)
		return steps.select{|step|step['id']==id}[0]
	end

	def adjustLayout(originX,originY,currentItem,steps,parent=nil)
		distanceX=0
		distanceY=0
		if(parent!=nil)
			#rootItem = nil
			parentX=parent['uiMetadata']['graph']['x']
			parentY=parent['uiMetadata']['graph']['y']
			currentItemX=currentItem['uiMetadata']['graph']['x']
			currentItemY=currentItem['uiMetadata']['graph']['y']
			distanceX=((currentItemX - parentX) / $gapSizeX).round() * $gapSizeX
			distanceY=((currentItemY - parentY) / $gapSizeY).round() * $gapSizeY
			if((distanceX==0) && (distanceY==0))
				if((currentItemX - parentX) > (currentItemY - parentY))
					distanceX=$gapSizeX
				else
					distanceY=$gapSizeY
				end
			end
			if(distanceY < 0)
				distanceY=0
			end
			if(distanceX < $gapSizeX)
				distanceX=$gapSizeX
			end
			#puts parent['id'] + "=>" + currentItem['id'] + ": #{originX},#{originY}=>#{currentItemX},#{currentItemY}\n\t#{distanceX},#{distanceY}"
		end
		currentItem['nextSteps'].map{|id|getStepById(id,steps)}.each do | child |
			adjustLayout(originX+distanceX,originY+distanceY,child,steps,currentItem)
		end
		currentItem['uiMetadata']['graph']['x']=originX + distanceX
		currentItem['uiMetadata']['graph']['y']=originY + distanceY
	end
	
	workflows=$automation.getWorkflows()
	
	if(customArguments.has_key? "workflowName")
		workflows=workflows.select{|workflow|workflow['templateMetadata']['name']==customArguments['workflowName']}
	end
	
	workflows.each do | workflow |
		if(workflow['immutable']==false)
			puts "Working on:#{workflow['templateMetadata']['name']}"
			workflow['immutable']=false
			old=workflow['workflowDefinition'].to_json()
			steps=workflow['workflowDefinition']
			rootItem=steps.select{|step|step['activity']['activityType']=='caseCreation'}[0]
			minY=steps.map{|step|step['uiMetadata']['graph']['y']}.min
			if(rootItem['uiMetadata']['graph']['y'] > minY)
				steps.each do | step|
					step['uiMetadata']['graph']['y']=step['uiMetadata']['graph']['y']-minY
				end
				rootItem['uiMetadata']['graph']['y']=0
			end
			minX=steps.map{|step|step['uiMetadata']['graph']['x']}.min
			if(rootItem['uiMetadata']['graph']['x'] > minX)
				steps.each do | step|
					step['uiMetadata']['graph']['x']=step['uiMetadata']['graph']['x']-minX
				end
				rootItem['uiMetadata']['graph']['x']=0
			end
			rootItemX=rootItem['uiMetadata']['graph']['x']
			rootItemY=rootItem['uiMetadata']['graph']['y']
			steps.each do | step|
				step['uiMetadata']['graph']['x']=step['uiMetadata']['graph']['x']-rootItemX
				step['uiMetadata']['graph']['y']=step['uiMetadata']['graph']['y']-rootItemY
			end
			
			
			adjustLayout(0,0,rootItem,steps,nil)

			#pushUp, this can have some interesting results... but it's aim is to get the first row as consistent as possible.
			maxX=steps.map{|step|step['uiMetadata']['graph']['x']}.max
			column=0
			while(column <= maxX)
				columnSteps=steps.select{|step|step['uiMetadata']['graph']['x']==column}
				minY=columnSteps.map{|step|step['uiMetadata']['graph']['y']}.min
				if(minY.nil?)
					minY=0
				end
				while(minY > 0)
					columnSteps.each do | columnStep |
						columnStep['uiMetadata']['graph']['y']=columnStep['uiMetadata']['graph']['y']-$gapSizeY
					end
					minY=columnSteps.map{|step|step['uiMetadata']['graph']['y']}.min
					if(minY.nil?)
						minY=0
					end
				end
				column=column + $gapSizeX
			end

			# re-adjust because the push up can create an inbalance where a child activity is higher than a parent, essentially this will push it back down if that happens.
			adjustLayout(0,0,rootItem,steps,nil)
			
			#collisionDetection, go down if clash
			changeMade=true
			while(changeMade)
				changeMade=false
				steps.each do | existingStep |
					x=existingStep['uiMetadata']['graph']['x']
					y=existingStep['uiMetadata']['graph']['y']
					samePlacements=(steps-[existingStep]).select{|otherStep|(otherStep['uiMetadata']['graph']['x']==x) && (otherStep['uiMetadata']['graph']['y']==y)}
					samePlacements.each do | samePlacement|
						samePlacement['uiMetadata']['graph']['y']=samePlacement['uiMetadata']['graph']['y']+$gapSizeY
						changeMade=true
					end
				end
			end
			
			workflow['workflowDefinition']=([rootItem] | steps.sort_by{|stepA|[stepA['uiMetadata']['graph']['y'],stepA['uiMetadata']['graph']['x'],]}).uniq
			new=workflow['workflowDefinition'].to_json
			puts "=========="
			if(new!=old)
				#workflow['workflowDefinition'].each do | step|
				#	x=step['uiMetadata']['graph']['x']
				#	y=step['uiMetadata']['graph']['y']
				#	puts "#{x},#{y}\t#{step['id']}=> #{step['nextSteps'].join(';')}"
				#end
				id=$automation.uploadWorkflow(workflow)
				puts "\tWorkflow updated:#{id}\n"
			else
				puts "skipped existing, no changed"
			end
		end
	end


rescue Exception => ex
	raise Exception.new(ex.message + "\n" + ex.backtrace.to_s)
end