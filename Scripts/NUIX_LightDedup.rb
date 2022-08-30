itemSetName="LightDedup"
query="flag:loose_file"

include_name=true
include_file_size=true
include_file_modified=true
include_item_date=true
include_content_text=false
date_format="yyyyMMddHHmmssSSS"


item_set = $current_case.createItemSet(itemSetName,"deduplication" => "Scripted")



add_items_check_callback = Proc.new do |item|
	pieces = []
	if include_name
		pieces << item.getLocalisedName
	end

	if include_file_size
		file_size = item.getFileSize
		file_size = "" if file_size.nil?
		pieces << file_size.to_s
	end

	if include_file_modified
		if(item.getProperties().has_key? "File Modified")
			modified_time = item.getProperties["File Modified"]
			# Make sure we are using a consistent time zone
			modified_time = modified_time.withZone(org.joda.time.DateTimeZone::UTC)
			if modified_time.nil?
				modified_time = ""
			else
				modified_time = modified_time.toString(date_format)
			end
		else
			modified_time = ""
		end
		pieces << modified_time
	end

	if include_item_date
		item_date = item.getDate
		if item_date.nil?
			item_date = ""
		else
			# Make sure we are using a consistent time zone
			item_date = item_date.withZone(org.joda.time.DateTimeZone::UTC).toString(date_format)
		end
		pieces << item_date
	end

	if include_content_text
		cleaned_text = item.getTextObject.toString
		cleaned_text = cleaned_text.gsub(/\s/,"")
		pieces << cleaned_text
	end

	result = pieces.join
	if result.strip.empty?
		next nil
	else
		next result.strip()
	end
end

# Define settings Hash
batch_settings = {
	  :expression=>add_items_check_callback
}
items=currentCase.searchUnsorted(query)
item_set.addItems(items,batch_settings)