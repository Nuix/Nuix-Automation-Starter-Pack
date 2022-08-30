# Menu Title: Manage Criteria Presets

require 'java'

import javax.swing.JOptionPane

begin
  Java::ComNuixAppsUtils::VersionChecker.assertValidVersion(NUIX_VERSION)
  Java::ComNuixAppsNdfGui::Main.manageCriteriaPresets($utilities)
rescue Exception => e
    JOptionPane.showMessageDialog nil, "#{e}",
        "Error starting plugin", JOptionPane::ERROR_MESSAGE
end
