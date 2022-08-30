if(!(customArguments.has_key? 'time'))
	raise Exception.new "'time' paramater was expected but not provided"
end

sleep customArguments['time'].to_i
if(customArguments.has_key? "error")
	if(customArguments['error']=='true')
		raise Exception.new "Oh dear... this is an intentional exception"
	end
end
begin
	puts $currentCase.getName()
rescue Exception => ex
	puts ex.message
end

return "Slept for #{customArguments['time'].to_i} seconds"