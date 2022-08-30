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
	config=Config.new(configMap,customArguments,["to","subject","body"],[])
rescue Exception => ex
	raise ex.message + " does your automation config have a line for userScriptsLocation=some path? Expected file at: #{filePath}"
end


begin
	$body=config.customArguments['body'] + config.evaluate($creds['mail']['footer'])

	require 'net/smtp'

	message_body = 	"From: " + $creds['mail']['from'] + "\n" + 
					"To: " + config.customArguments['to'] + "\n" +  #to:comma separated email addresses
					"Subject: " + config.customArguments['subject'] + "\n"+
					"\n" + #required!!!
					$body + 
					"\n"
					
	smtp = Net::SMTP.new($creds['mail']['server'], $creds['mail']['port'])
	smtp.enable_starttls_auto
	smtp.start($creds['mail']['server'],$creds['mail']['username'],$creds['mail']['password'], :login)
	smtp.send_message(message_body, $creds['mail']['username'], config.customArguments['to'].split(','))
	return "Email sent to:#{config.customArguments['to']}"
rescue Exception => ex
	raise Exception.new(ex.message.to_s + "\n" +  ex.backtrace.to_s + "\n" + config.customArguments.to_s)
end