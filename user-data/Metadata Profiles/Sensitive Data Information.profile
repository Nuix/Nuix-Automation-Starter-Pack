<?xml version="1.0" encoding="UTF-8"?>
<metadata-profile xmlns="http://nuix.com/fbi/metadata-profile">
  <metadata-list>
    <metadata type="SPECIAL" name="Kind" />
    <metadata type="SPECIAL" name="Name" />
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
		if(item.getPath[1].getUri().start_with? "file:///")
			return CGI::unescape("#{item.getPath[1].getUri.gsub('file:///','')}#{item.getPathNames[2..-1].join("/")}")
		end
	else
		if(container.getPath().length >= item.getPath().length)
			return ""
		end
		remainingPath=item.getPath().to_a - container.getPath().to_a
		return remainingPath.map{|pathItem|pathItem.getName()}.join("/")
	end
end

getOriginalPath($current_item)]]></script>
      </scripted-expression>
    </metadata>
    <metadata type="SPECIAL" name="Item Date" />
    <metadata type="SPECIAL" name="From" />
    <metadata type="SPECIAL" name="To" />
    <metadata type="SPECIAL" name="Cc" />
    <metadata type="SPECIAL" name="Bcc" />
    <metadata type="DERIVED" name="Attachments">
      <metadata type="SPECIAL" name="Child Names" />
    </metadata>
    <metadata type="SPECIAL" name="Detected">
      <scripted-expression>
        <type>ruby</type>
        <script><![CDATA[$currentCase.getAllEntityTypes().select{|type|$current_item.getEntities(type).length > 0}.join(",")]]></script>
      </scripted-expression>
    </metadata>
    <metadata type="SPECIAL" name="Phrase 0">
      <scripted-expression>
        <type>ruby</type>
        <script><![CDATA[values=[]
itemText=$current_item.getTextObject().toString()
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		values.push(value)
	end
end

count=0
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		results=itemText.scan(/(?<=\s|^)(?:[\n\sA-z\S]{0,20})#{Regexp.quote(value)}(?:[\n\sA-z\S]{0,20}(?=\s|$))/m)
		results.each do | result |
			if(count==0)
				result=result.gsub(/[\s\n\r\t]+/,' ')
				finalText=result
				values.each do | value |
					finalText=finalText.gsub(value,' ...' + type + '... ')
				end
				return finalText
			else
				count=count+1
			end
		end
	end
end
return '']]></script>
      </scripted-expression>
    </metadata>
    <metadata type="SPECIAL" name="Phrase 1">
      <scripted-expression>
        <type>ruby</type>
        <script><![CDATA[values=[]
itemText=$current_item.getTextObject().toString()
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		values.push(value)
	end
end

count=0
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		results=itemText.scan(/(?<=\s)(?:[
\sA-z\S]{0,20})#{Regexp.quote(value)}(?:[
\sA-z\S]{0,20}(?=\s))/m)
		results.each do | result |
			if(count==1)
				finalText=result
				values.each do | value |
					finalText=finalText.gsub(value,' ...' + type + '... ')
				end
				return finalText
			else
				count=count+1
			end
		end
	end
end
return '']]></script>
      </scripted-expression>
    </metadata>
    <metadata type="SPECIAL" name="Phrase 2">
      <scripted-expression>
        <type>ruby</type>
        <script><![CDATA[values=[]
itemText=$current_item.getTextObject().toString()
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		values.push(value)
	end
end

count=0
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		results=itemText.scan(/(?<=\s)(?:[
\sA-z\S]{0,20})#{Regexp.quote(value)}(?:[
\sA-z\S]{0,20}(?=\s))/m)
		results.each do | result |
			if(count==2)
				finalText=result
				values.each do | value |
					finalText=finalText.gsub(value,' ...' + type + '... ')
				end
				return finalText
			else
				count=count+1
			end
		end
	end
end
return '']]></script>
      </scripted-expression>
    </metadata>
    <metadata type="SPECIAL" name="Phrase 3">
      <scripted-expression>
        <type>ruby</type>
        <script><![CDATA[values=[]
itemText=$current_item.getTextObject().toString()
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		values.push(value)
	end
end

count=0
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		results=itemText.scan(/(?<=\s)(?:[
\sA-z\S]{0,20})#{Regexp.quote(value)}(?:[
\sA-z\S]{0,20}(?=\s))/m)
		results.each do | result |
			if(count==3)
				finalText=result
				values.each do | value |
					finalText=finalText.gsub(value,' ...' + type + '... ')
				end
				return finalText
			else
				count=count+1
			end
		end
	end
end
return '']]></script>
      </scripted-expression>
    </metadata>
    <metadata type="SPECIAL" name="Phrase 4">
      <scripted-expression>
        <type>ruby</type>
        <script><![CDATA[values=[]
itemText=$current_item.getTextObject().toString()
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		values.push(value)
	end
end

count=0
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		results=itemText.scan(/(?<=\s)(?:[
\sA-z\S]{0,20})#{Regexp.quote(value)}(?:[
\sA-z\S]{0,20}(?=\s))/m)
		results.each do | result |
			if(count==4)
				finalText=result
				values.each do | value |
					finalText=finalText.gsub(value,' ...' + type + '... ')
				end
				return finalText
			else
				count=count+1
			end
		end
	end
end
return '']]></script>
      </scripted-expression>
    </metadata>
    <metadata type="SPECIAL" name="Phrase 5">
      <scripted-expression>
        <type>ruby</type>
        <script><![CDATA[values=[]
itemText=$current_item.getTextObject().toString()
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		values.push(value)
	end
end

count=0
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		results=itemText.scan(/(?<=\s)(?:[
\sA-z\S]{0,20})#{Regexp.quote(value)}(?:[
\sA-z\S]{0,20}(?=\s))/m)
		results.each do | result |
			if(count==5)
				finalText=result
				values.each do | value |
					finalText=finalText.gsub(value,' ...' + type + '... ')
				end
				return finalText
			else
				count=count+1
			end
		end
	end
end
return '']]></script>
      </scripted-expression>
    </metadata>
    <metadata type="SPECIAL" name="Phrase 6">
      <scripted-expression>
        <type>ruby</type>
        <script><![CDATA[values=[]
itemText=$current_item.getTextObject().toString()
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		values.push(value)
	end
end

count=0
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		results=itemText.scan(/(?<=\s)(?:[
\sA-z\S]{0,20})#{Regexp.quote(value)}(?:[
\sA-z\S]{0,20}(?=\s))/m)
		results.each do | result |
			if(count==6)
				finalText=result
				values.each do | value |
					finalText=finalText.gsub(value,' ...' + type + '... ')
				end
				return finalText
			else
				count=count+1
			end
		end
	end
end
return '']]></script>
      </scripted-expression>
    </metadata>
    <metadata type="SPECIAL" name="Phrase 7">
      <scripted-expression>
        <type>ruby</type>
        <script><![CDATA[values=[]
itemText=$current_item.getTextObject().toString()
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		values.push(value)
	end
end

count=0
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		results=itemText.scan(/(?<=\s)(?:[
\sA-z\S]{0,20})#{Regexp.quote(value)}(?:[
\sA-z\S]{0,20}(?=\s))/m)
		results.each do | result |
			if(count==7)
				finalText=result
				values.each do | value |
					finalText=finalText.gsub(value,' ...' + type + '... ')
				end
				return finalText
			else
				count=count+1
			end
		end
	end
end
return '']]></script>
      </scripted-expression>
    </metadata>
    <metadata type="SPECIAL" name="Phrase 8">
      <scripted-expression>
        <type>ruby</type>
        <script><![CDATA[values=[]
itemText=$current_item.getTextObject().toString()
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		values.push(value)
	end
end

count=0
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		results=itemText.scan(/(?<=\s)(?:[
\sA-z\S]{0,20})#{Regexp.quote(value)}(?:[
\sA-z\S]{0,20}(?=\s))/m)
		results.each do | result |
			if(count==8)
				finalText=result
				values.each do | value |
					finalText=finalText.gsub(value,' ...' + type + '... ')
				end
				return finalText
			else
				count=count+1
			end
		end
	end
end
return '']]></script>
      </scripted-expression>
    </metadata>
    <metadata type="SPECIAL" name="Phrase 9">
      <scripted-expression>
        <type>ruby</type>
        <script><![CDATA[values=[]
itemText=$current_item.getTextObject().toString()
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		values.push(value)
	end
end

count=0
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		results=itemText.scan(/(?<=\s)(?:[
\sA-z\S]{0,20})#{Regexp.quote(value)}(?:[
\sA-z\S]{0,20}(?=\s))/m)
		results.each do | result |
			if(count==9)
				finalText=result
				values.each do | value |
					finalText=finalText.gsub(value,' ...' + type + '... ')
				end
				return finalText
			else
				count=count+1
			end
		end
	end
end
return '']]></script>
      </scripted-expression>
    </metadata>
    <metadata type="SPECIAL" name="Phrase 10">
      <scripted-expression>
        <type>ruby</type>
        <script><![CDATA[values=[]
itemText=$current_item.getTextObject().toString()
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		values.push(value)
	end
end

count=0
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		results=itemText.scan(/(?<=\s)(?:[
\sA-z\S]{0,20})#{Regexp.quote(value)}(?:[
\sA-z\S]{0,20}(?=\s))/m)
		results.each do | result |
			if(count==10)
				finalText=result
				values.each do | value |
					finalText=finalText.gsub(value,' ...' + type + '... ')
				end
				return finalText
			else
				count=count+1
			end
		end
	end
end
return '']]></script>
      </scripted-expression>
    </metadata>
    <metadata type="SPECIAL" name="Phrase 11">
      <scripted-expression>
        <type>ruby</type>
        <script><![CDATA[values=[]
itemText=$current_item.getTextObject().toString()
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		values.push(value)
	end
end

count=0
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		results=itemText.scan(/(?<=\s)(?:[
\sA-z\S]{0,20})#{Regexp.quote(value)}(?:[
\sA-z\S]{0,20}(?=\s))/m)
		results.each do | result |
			if(count==11)
				finalText=result
				values.each do | value |
					finalText=finalText.gsub(value,' ...' + type + '... ')
				end
				return finalText
			else
				count=count+1
			end
		end
	end
end
return '']]></script>
      </scripted-expression>
    </metadata>
    <metadata type="SPECIAL" name="Phrase 12">
      <scripted-expression>
        <type>ruby</type>
        <script><![CDATA[values=[]
itemText=$current_item.getTextObject().toString()
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		values.push(value)
	end
end

count=0
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		results=itemText.scan(/(?<=\s)(?:[
\sA-z\S]{0,20})#{Regexp.quote(value)}(?:[
\sA-z\S]{0,20}(?=\s))/m)
		results.each do | result |
			if(count==12)
				finalText=result
				values.each do | value |
					finalText=finalText.gsub(value,' ...' + type + '... ')
				end
				return finalText
			else
				count=count+1
			end
		end
	end
end
return '']]></script>
      </scripted-expression>
    </metadata>
    <metadata type="SPECIAL" name="Phrase 13">
      <scripted-expression>
        <type>ruby</type>
        <script><![CDATA[values=[]
itemText=$current_item.getTextObject().toString()
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		values.push(value)
	end
end

count=0
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		results=itemText.scan(/(?<=\s)(?:[
\sA-z\S]{0,20})#{Regexp.quote(value)}(?:[
\sA-z\S]{0,20}(?=\s))/m)
		results.each do | result |
			if(count==13)
				finalText=result
				values.each do | value |
					finalText=finalText.gsub(value,' ...' + type + '... ')
				end
				return finalText
			else
				count=count+1
			end
		end
	end
end
return '']]></script>
      </scripted-expression>
    </metadata>
    <metadata type="SPECIAL" name="Phrase 14">
      <scripted-expression>
        <type>ruby</type>
        <script><![CDATA[values=[]
itemText=$current_item.getTextObject().toString()
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		values.push(value)
	end
end

count=0
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		results=itemText.scan(/(?<=\s)(?:[
\sA-z\S]{0,20})#{Regexp.quote(value)}(?:[
\sA-z\S]{0,20}(?=\s))/m)
		results.each do | result |
			if(count==14)
				finalText=result
				values.each do | value |
					finalText=finalText.gsub(value,' ...' + type + '... ')
				end
				return finalText
			else
				count=count+1
			end
		end
	end
end
return '']]></script>
      </scripted-expression>
    </metadata>
    <metadata type="SPECIAL" name="Phrase 15">
      <scripted-expression>
        <type>ruby</type>
        <script><![CDATA[values=[]
itemText=$current_item.getTextObject().toString()
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		values.push(value)
	end
end

count=0
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		results=itemText.scan(/(?<=\s)(?:[
\sA-z\S]{0,20})#{Regexp.quote(value)}(?:[
\sA-z\S]{0,20}(?=\s))/m)
		results.each do | result |
			if(count==15)
				finalText=result
				values.each do | value |
					finalText=finalText.gsub(value,' ...' + type + '... ')
				end
				return finalText
			else
				count=count+1
			end
		end
	end
end
return '']]></script>
      </scripted-expression>
    </metadata>
    <metadata type="SPECIAL" name="Phrase 16">
      <scripted-expression>
        <type>ruby</type>
        <script><![CDATA[values=[]
itemText=$current_item.getTextObject().toString()
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		values.push(value)
	end
end

count=0
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		results=itemText.scan(/(?<=\s)(?:[
\sA-z\S]{0,20})#{Regexp.quote(value)}(?:[
\sA-z\S]{0,20}(?=\s))/m)
		results.each do | result |
			if(count==16)
				finalText=result
				values.each do | value |
					finalText=finalText.gsub(value,' ...' + type + '... ')
				end
				return finalText
			else
				count=count+1
			end
		end
	end
end
return '']]></script>
      </scripted-expression>
    </metadata>
    <metadata type="SPECIAL" name="Phrase 17">
      <scripted-expression>
        <type>ruby</type>
        <script><![CDATA[values=[]
itemText=$current_item.getTextObject().toString()
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		values.push(value)
	end
end

count=0
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		results=itemText.scan(/(?<=\s)(?:[
\sA-z\S]{0,20})#{Regexp.quote(value)}(?:[
\sA-z\S]{0,20}(?=\s))/m)
		results.each do | result |
			if(count==17)
				finalText=result
				values.each do | value |
					finalText=finalText.gsub(value,' ...' + type + '... ')
				end
				return finalText
			else
				count=count+1
			end
		end
	end
end
return '']]></script>
      </scripted-expression>
    </metadata>
    <metadata type="SPECIAL" name="Phrase 18">
      <scripted-expression>
        <type>ruby</type>
        <script><![CDATA[values=[]
itemText=$current_item.getTextObject().toString()
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		values.push(value)
	end
end

count=0
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		results=itemText.scan(/(?<=\s)(?:[
\sA-z\S]{0,20})#{Regexp.quote(value)}(?:[
\sA-z\S]{0,20}(?=\s))/m)
		results.each do | result |
			if(count==18)
				finalText=result
				values.each do | value |
					finalText=finalText.gsub(value,' ...' + type + '... ')
				end
				return finalText
			else
				count=count+1
			end
		end
	end
end
return '']]></script>
      </scripted-expression>
    </metadata>
    <metadata type="SPECIAL" name="Phrase 19">
      <scripted-expression>
        <type>ruby</type>
        <script><![CDATA[values=[]
itemText=$current_item.getTextObject().toString()
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		values.push(value)
	end
end

count=0
$currentCase.getAllEntityTypes().each do |type|
	$current_item.getEntities(type).each do | value |
		results=itemText.scan(/(?<=\s)(?:[
\sA-z\S]{0,20})#{Regexp.quote(value)}(?:[
\sA-z\S]{0,20}(?=\s))/m)
		results.each do | result |
			if(count==19)
				finalText=result
				values.each do | value |
					finalText=finalText.gsub(value,' ...' + type + '... ')
				end
				return finalText
			else
				count=count+1
			end
		end
	end
end
return '']]></script>
      </scripted-expression>
    </metadata>
  </metadata-list>
</metadata-profile>
