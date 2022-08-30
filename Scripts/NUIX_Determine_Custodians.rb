iu=utilities.getItemUtility()
ba=utilities.getBulkAnnotater()

currentCase.searchUnsorted('name:"Users" mime-type:"filesystem/directory"').each do | userDirectory |
	userDirectory.getChildren().each do | custodianDir|
		custodianDescendants=iu.findItemsAndDescendants([custodianDir])
		ba.assignCustodian(custodianDir.getName(), custodianDescendants)
	end
end

currentCase.searchUnsorted('name:"Top of Information Store" mime-type:"application/vnd.ms-outlook-folder"').each do | infoStore |
	mailboxStore=infoStore.getParent()
	custodianDescendants=iu.findItemsAndDescendants([mailboxStore])
	ba.assignCustodian(mailboxStore.getName().gsub('Mailbox - ','').split('{').first().strip(), custodianDescendants)
end

currentCase.searchUnsorted('name:"Sent Items" mime-type:"application/vnd.ms-outlook-folder"').each do | sentFolder |
	child=sentFolder.getChildren()
	if(child.size > 0)
		custodianName=child.first().getCommunication().getFrom().first().getPersonal()
		
		custodianDescendants=iu.findItemsAndDescendants([sentFolder.getParent()])
		ba.assignCustodian(custodianName, custodianDescendants)
	end
end
