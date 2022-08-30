# Menu Title: Processing Configuration (store in case)
# Needs Case: true

require 'java'

import javax.swing.JOptionPane

begin
  Java::ComNuixAppsUtils::VersionChecker.assertValidVersion(NUIX_VERSION)
  settings=Java::ComNuixAppsNdfGui::Main.captureSettings($utilities)
  gsonBuilder=com.google.gson.GsonBuilder().new().setPrettyPrinting().create()
  fileLocation=$currentCase.getLocation().to_s + "/ndf.json"
  File.open(fileLocation, 'w') { |file| file.write(gsonBuilder.toJson(settings)) }
  File.open($currentCase.getLocation().to_s + "\\config_ndf.profile.file.json", 'w') { |file| file.write(gsonBuilder.toJson(fileLocation)) }
rescue Exception => e
    JOptionPane.showMessageDialog nil, "#{e}",
        "Error starting plugin", JOptionPane::ERROR_MESSAGE
end