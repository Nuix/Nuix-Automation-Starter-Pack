# Nuix Automation Starter Pack
Get started with our new web based multi-user pipeline platform with many common workflows and tasks ready to go, contributions welcome.

This pack includes some community workflows and profiles that are often used as examples in our demonstrations to show how far Nuix Automation can be extended. The scripts included are to be considered beta released to future features that will come bundled with the product. If you like a workflow/script here please let your account manager know so that that feature can be better prioritised. 

## Features

| Nuix Enterprise Collection Center| Nuix Automation | Nuix Natural Language Processing | Nuix Investigate | Nuix Discover |
| :-: | :-: | :-: | :-: | :-: |
|![Nuix Enterprise Collection Center](https://github.com/Nuix/Nuix-Automation-Starter-Pack/blob/main/product%20svg/Nuix%20Enterprise%20Collection%20Center.svg?raw=true)<br /><br />|![Nuix Automation](https://github.com/Nuix/Nuix-Automation-Starter-Pack/blob/main/product%20svg/Nuix%20Automation.svg?raw=true)|<img src="https://github.com/Nuix/Nuix-Automation-Starter-Pack/blob/main/product%20svg/NLP%20Wordmark%20-%20Vertical%20-%20Colour.png?raw=true" alt="drawing" width="80"/>|![Nuix Investigate](https://github.com/Nuix/Nuix-Automation-Starter-Pack/blob/main/product%20svg/Nuix%20Investigate.svg?raw=true)|![Nuix Discover](https://github.com/Nuix/Nuix-Automation-Starter-Pack/blob/main/product%20svg/Nuix%20Discover.svg?raw=true)|

## Deploying

1. Download the latest [release](https://github.com/Nuix/Nuix-Automation-Starter-Pack/releases) and unzip.
2. Move the components user-data to the Nuix Automation user-data directory. Usually this is:
This step is optional, however some workflows will require elements to function.
> C:\Program Files\Nuix\Web Platform\Nuix-Automation\nuix-engine\user-data
3. Move the scripts directory to the scripts directory inside the Nuix Automation installation. Usually this is:
>  C:\Program Files\Nuix\Web Platform\Nuix-Automation\scripts
4. Update the credentials as best you can, for now the only important fields are for Nuix Automation.
> "automation": {
>		"server": "http://server.domain.com:8780",
>		"username": "demoUsername",
>		"password": "demoPassword"
>	}
5. Open Nuix Automation and Create a new Workflow titled "Restore Environment"
6. Inside the new Workflow add a task for "Bulk Run User Script"
7. Add a name "Restore Environment"
8. Select the language "Ruby"
9. From the script drop down select the script titled "GENERIC_RestoreEnvironment.rb"
10. Save the Workflow
11. Run the workflow against any (create a new case if no cases exist yet).
