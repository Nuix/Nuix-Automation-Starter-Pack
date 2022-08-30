# Menu Title: Manage Entity Presets

require 'java'

import javax.swing.JOptionPane

begin
  Java::ComNuixAppsUtils::VersionChecker.assertValidVersion(NUIX_VERSION)
  Java::ComNuixAppsNdfGui::Main.manageEntityPresets($utilities)
rescue Exception => e
    JOptionPane.showMessageDialog nil, "#{e}",
        "Error starting plugin", JOptionPane::ERROR_MESSAGE
end
