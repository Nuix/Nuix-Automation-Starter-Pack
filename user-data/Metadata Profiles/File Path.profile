<?xml version="1.0" encoding="UTF-8"?>
<metadata-profile xmlns="http://nuix.com/fbi/metadata-profile">
  <metadata-list>
    <metadata type="SPECIAL" name="Computer">
      <scripted-expression>
        <type>ruby</type>
        <script><![CDATA[require 'socket'

def searchForMicroForensics(item)
	if(item.getType().getName()=='application/vnd.microforensics-filesafe')
		return item
	end
	if(item.getParent().nil?)
		return nil
	else
		return searchForMicroForensics(item.getParent())
	end
end

def getComputer(item)
	if(item.isLooseFile()==false)
		return Socket.gethostname
	end
	container=searchForMicroForensics(item)
	if(container.nil?)
		return Socket.gethostname
	else
		if(container.getPath().length >= item.getPath().length)
			return Socket.gethostname
		end
		return container.getEvidenceMetadata()['computerName']
	end
end

getComputer($current_item).upcase]]></script>
      </scripted-expression>
    </metadata>
    <metadata type="SPECIAL" name="MD5 Digest" />
    <metadata type="SPECIAL" name="Case Name" />
    <metadata type="SPECIAL" name="File Path">
      <scripted-expression>
        <type>ruby</type>
        <script><![CDATA[def searchForMicroForensics(item)
	if(item.getType().getName()=='application/vnd.microforensics-filesafe')
		return item
	end
	if(item.getParent().nil?)
		return nil
	else
		return searchForMicroForensics(item.getParent())
	end
end

def getOriginalPath(item)
	if(item.isLooseFile()==false)
		return ""
	end
	container=searchForMicroForensics(item)
	if(container.nil?)
		require 'cgi'
		if(item.getPath().length == 2)
			return CGI::unescape(item.getPath[1].getUri.gsub('file:///',''))
		end
		if(item.getPath[1].getUri().start_with? "file:///")
			return CGI::unescape("#{item.getPath[1].getUri.gsub(/file:\/+/,'')}#{item.getPathNames()[2..-1].join("/")}").gsub('/',"\\")
		end
		if(item.getPath[1].getUri().start_with? "file://")
			return CGI::unescape("#{item.getPath[1].getUri.gsub(/file:\/+/,'//')}#{item.getPathNames()[2..-1].join("/")}").gsub('/',"\\")
		end
	else
		if(container.getPath().length >= item.getPath().length)
			return ''
		end
		remainingPath=item.getPath().to_a - container.getPath().to_a
		return remainingPath.map{|pathItem|pathItem.getName()}.join("/")
	end
end

getOriginalPath($current_item)]]></script>
      </scripted-expression>
    </metadata>
  </metadata-list>
</metadata-profile>
