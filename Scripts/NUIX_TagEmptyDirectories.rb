ba=$utilities.getBulkAnnotater()
items=currentCase.searchUnsorted("mime-type:filesystem/directory")
ba.addTag("Trivial|filesystem|EmptyDirectory",items)

puts "Determining required folders"
$iu=$utilities.getItemUtility()
ascendants=currentCase.searchUnsorted("not tag:*")
parentsOfIncludedItems=ascendants
collection=[]
while(parentsOfIncludedItems.length > 0)
	actualParents=parentsOfIncludedItems.map{|item|item.getParent()}.reject{|a|a.nil?} #every parent's parent until resolved to nil
	parentsOfIncludedItems=$iu.difference(actualParents,collection)
	puts "\tremapping #{collection.length} + #{parentsOfIncludedItems.length}"
	collection=$iu.union(parentsOfIncludedItems,collection)
	puts "\t\tTotal: #{collection.length}"
end
puts "\tCollection Total #{collection.length}"
ba.removeTag("Trivial|filesystem|EmptyDirectory",collection)
ba.removeTag("Trivial|filesystem|drive",collection)



puts "\tcontinuing"