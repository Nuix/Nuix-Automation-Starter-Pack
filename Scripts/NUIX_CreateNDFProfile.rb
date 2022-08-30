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
	config=Config.new(configMap,customArguments,["responsiveReturn","responsiveContent","encryptedItemsResponsive","personNameExtraction","identifyEntities","entityExtractionScope","ocrItems","processNonResponsive"],[])
rescue Exception => ex
	raise ex.message + " does your automation config have a line for userScriptsLocation=some path? Expected file at: #{filePath}" + ex.backtrace.join("\n")
end

validation={
	#Select what items to return as responsive
	"responsiveReturn"=>["RESPONSIVE_ITEM_FAMILY","RESPONSIVE_ITEM_ONLY"],
	#Control whether a Responsive Item's Binary and/or Text can be preserved
	"responsiveContent"=>["NO_CONTENT","TEXT_ONLY","BINARY_ONLY","TEXT_AND_BINARY"],
	#During processing items may be encountered that can be corrupted or encrypted. If detected should these be kept
	"encryptedItemsResponsive"=>[true,false],
	#Select whether to identify person names from within the Metadata and Text of Responsive Items.
	"personNameExtraction"=>[true,false],
	#Select whether to identify the defined Entities from within the Metadata and Text of Responsive Items
	"identifyEntities"=>[true,false],
	#Perform OCR Processing
	"ocrItems"=>[true,false],
	#OCR Profile Name,
	"ocrProfile"=>nil,
	#Select whether to identify the below defined Entities from within the Metadata nd Text of Responsive Items
	"entityExtractionScope"=>["PROPERTIES_ONLY","TEXT_ONLY","PROPERTIES_AND_TEXT"],
	#Control if non-responsive items will be processed and kept in the case
	"entity.name"=>nil,
	"entity.pattern"=>nil,
	"entity.group"=>nil,
	"entity.description"=>nil,
	"processNonResponsive"=>[true,false],
	#Define the Criteria to determine which processed items are Responsive
	"responsiveCriteria.field"=>["filePath","itemDate","itemDate","keyword","regex","itemKind","itemMimeType","md5","to","from","cc","bcc","deleted","encrypted","file_data","toplevelitem","file_size","binary_length","query"],
	#Define an operator to work on the field
	"responsiveCriteria.operator"=>["begins_with","between","contains","ends_with","equal","greater","greater_or_equal","in","less","less_or_equal","matches","not_between","not_contains","not_equal","not_in","not_matches"],

	"responsiveCriteria.value"=>nil
}


template={
	"nonResponsiveTag"=> "NDF|Non-Responsive",
	"responsiveTag"=> "NDF|Responsive",
	"responsiveFamilyTag"=> "NDF|Responsive|Responsive-Family-Item",
	"personNameNamedEntity"=> "person",
	"responsiveCriteria"=> [
		{
			"condition"=> "AND",
			"rules"=> []
		}
	],
	"responsiveReturn"=> "RESPONSIVE_ITEM_ONLY",
	"responsiveContent"=> "TEXT_AND_BINARY",
	"encryptedItemsResponsive"=> false,
	"personNameExtraction"=> true,
	"identifyEntities"=> true,
	"ocrItems"=> false,
	"ocrProfile"=> "Default",
	"entityExtractionScope"=> "PROPERTIES_AND_TEXT",
	"entities"=> [],
	"processNonResponsive"=> true
}


result={}
template.keys.sort().each do | key|
	result[key]=template[key]
end

$criteriaBlobs={}
$entityBlobs={}

config.customArguments.each do | key,value|
	removeIndex=key.gsub(/\.[0-9]\./,'.')
	if(validation.has_key? removeIndex)
		if(!(validation[removeIndex].nil?))
			if(value.downcase()=='true')
				value=true
			elsif(value.downcase()=='false')
				value=false
			end
			if(!(validation[removeIndex].include? value))
				if(validation[removeIndex].include? value.to_s.downcase())
					value=value.to_s.downcase()
				else
					if(validation[removeIndex].include? value.to_s.upcase())
						value=value.to_s.upcase()
					else
						raise Exception.new "Invalid Field value for #{key}:#{value}\n\tPossible Values:#{validation[removeIndex].join(',')}"
					end
				end
			end
		end
		config.customArguments[key]=value
		if(key==removeIndex) 
			result[key]=value
		else # has an index
			type,index,subKey=key.split('.')
			if(type=="responsiveCriteria")
				if(!($criteriaBlobs.has_key? index))
					$criteriaBlobs[index]={
						"id"=> nil,
						"field"=> nil,
						"operator"=> nil,
						"value"=> nil
					}
				end
				$criteriaBlobs[index][subKey]=value
				if(subKey=='field')
					$criteriaBlobs[index]['id']=value
				end
			elsif(type=="entity")
				if(!($entityBlobs.has_key? index))
					$entityBlobs[index]={
							"instruction"=>"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\r\n<RegularExpression name=\"@@NAME@@\" pattern=\"@@PATTERN@@\" validationOperator=\"or\"/>\r\n",
							"name"=>nil,
							"description"=>nil,
							"createdBy"=>"Nuix Automation",
							"createdOn"=>0,
							"readOnly"=>true,
							"group"=>nil
						}
				end
				case(subKey)
				when 'name'
					$entityBlobs[index]['instruction']=$entityBlobs[index]['instruction'].gsub('@@NAME@@',value)
					$entityBlobs[index][subKey]=value
				when 'pattern'
					$entityBlobs[index]['instruction']=$entityBlobs[index]['instruction'].gsub('@@PATTERN@@',value.to_json()[1..-2] )
				else
					$entityBlobs[index][subKey]=value
				end
			end
		end
	else
		raise Exception.new "#{key} is not valid #{removeIndex}"
	end
end


$criteriaBlobs.each do | index,blob|
	if(blob.values.include? nil)
		missing=blob.keys.select{|key|blob[key].nil?}.reject{|key|key=='id'}.join(',')
		raise Exception.new "Criteria index #{index} not added because of a missing value for:#{missing}"
	else
		if(blob['field']=='regex')
			value="<?xml version=\"1.0\" encoding=\"UTF-8\"?>\r\n<RegularExpression name=\"criteria\" pattern=\"@@PATTERN@@\" validationOperator=\"or\"/>\r\n"
			value=value.gsub('@@PATTERN@@',blob['value'].to_json()[1..-2] )
			blob['value']=value
		end
		result['responsiveCriteria'][0]['rules'].push(blob)
	end
end

$entityBlobs.each do | index,blob|
	if(blob.values.include? nil)
		missing=blob.keys.select{|key|blob[key].nil?}.reject{|key|key=='id'}.join(',')
		raise Exception.new "Entity index #{index} not added because of a missing value for:#{missing}"
	else
		result['entities'].push(blob)
	end
end

config.set('ndf.profile.generated',result)
config.set('ndf.profile.file',config.generateFilePathFromKey('ndf.profile.generated'))
config.set('ndf.profile.name','Nuix Automation')