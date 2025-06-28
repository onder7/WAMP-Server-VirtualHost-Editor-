## A PowerShell script that makes it easy to create and manage VirtualHosts for WAMP Server installed in the C:\wamp64\ directory in Windows




## WampVHostGUI Version


![image](https://github.com/user-attachments/assets/ddc907fa-e8fb-4ff2-bf84-476a8fcf3ec7)


![image](https://github.com/user-attachments/assets/f0c802ee-6c6a-4033-ac0a-1cbb0540cf26)


## Usage Instructions
Save this code to a .ps1 file (e.g., WampVHostGUI.ps1)


Run PowerShell as an administrator (required to modify the hosts file)


Run the script: .\WampVHostGUI.ps1


## GUI Features
Add New VirtualHost Tab:


Form to enter the domain name and project folder


Automatically configures all settings with a single button


Automatically creates a folder in the www directory


## VirtualHost List Tab:


Displays all existing VirtualHosts in a table format


Option to remove the selected VirtualHost


Refresh list button


## Administrator Status Indicator:


Indicates whether the script is running with administrator privileges


## Important Notes
You must update the $httpdConf and $httpdVhosts paths according to your Apache version.


Check the PowerShell Execution Policy settings for the script to work properly:


powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
Don't forget to restart the service after each change in WAMP Server.


This GUI interface will provide a much more user-friendly and error-free experience compared to the command line version.


## ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////




![image](https://github.com/user-attachments/assets/dbef477d-6bf1-4f04-ae67-e5d35226b4d4)


![image](https://github.com/user-attachments/assets/52a08282-ffe7-4a79-aa2f-8b3cfaccc16d)




# Usage Instructions
Save this script as a .ps1 file (e.g., WampVirtualHost.ps1)


Run PowerShell as an administrator (required to modify the hosts file)


Run the script: .\WampVirtualHost.ps1


# Features
Add New VirtualHost:


Creates a new VirtualHost by specifying the domain name and project folder


Automatically updates all necessary configuration files (httpd-vhosts.conf, hosts)


Automatically creates the project directory


# List VirtualHosts:


Lists all existing VirtualHosts and their associated directories


# Remove VirtualHost:


Removes the VirtualHost and hosts entry associated with the specified domain


# Notes
The script has been tested with WAMP Server 3.2.0 (Apache 2.4.46).


You may need to update the $httpdConf and $httpdVhosts paths for different WAMP/Apache versions.


The PowerShell Execution Policy may need to be set to RemoteSigned or Unrestricted for the script to run.
