# Disable-DepartedUsers

*A PowerShell script for disabling user accounts in Active Directory based on user data stored in JSON.*

---------------------------------------------------------------

## Pre-requisites

This script assumes that you have sufficient permissions in your domain both to run PowerShell scripts and to modify user objects within Active Directory. Depending on the version of Windows & PowerShell you are running, you can import the Active Directory PowerShell module through PowerShell commands or by downloading the **Remote Server Administration Tools** and enabling the *Active Directory Module for Windows PowerShell* feature.


## Variable Definitions

In order for the script to run, several variables must be defined based your environment & needs. They are:

### JSON Parsing Variables

**1.** `$webURL`: If you are running this script against JSON data from a website, set this variable equal to the full URL (in quotes).
<br>
<br>
**2.** `$jsonContent`: If reading JSON from a website, this variable gets & stores the JSON content. **If you want to read data from a local JSON file instead**, set this variable equal to the file path (in quotes).
<br>

### JSON Object Variables
The variables used to parse & store user account information assume that each JSON object corresponds to a single user account and that the object keys reference common AD user attributes, such as *Name*,*SamAccountName*, and *Enabled* status.  The following variables may or may not work for you, so it is recommended that you review them carefully to make sure they correspond to the actual JSON key names in your data:
<br>
<br>
**1.** `$departure`: *Datetime* variable equal to the value of a JSON object's *DepartureDate* key. In the current version of the script, this variable is only used as a means of sorting the user names which appear in the GUI prompt and is not displayed as output. 
<br>
<br>
**2.** `$employee`: *String* variable equal to the value of a JSON object's *PreferredName* key. ***PreferredName* in this case is analogous to the *Name* user attribute in AD.** 
<br>
<br>
**3.** `$userName`: *String* variable equal to the value of a JSON object's *Alias* key. ***Alias* in this case is analogous to the *SamAccountName* user attribute in AD.**
<br>
### E-mail Notification Variables
The following variables are used in an e-mail notification that is sent for auditing purposes whenever the script is run successfully:
<br>
<br>
**1.** `$sender`: *String* variable for the sender's e-mail address.
<br>
<br>
**2.** `$recipient`: *String* variable for the recipient's e-mail address.
<br>
<br>
**3.** `$smtpServer`: *String* variable for the SMTP server's FQDN.

## Script Logic
### Part 1: Gather & Parse JSON content
After the initial JSON parsing variables are set, an empty Hashtable is created named `$employeeHash`. A For loop is constructed to create the JSON object variables, defined above, for each JSON object (user account). In this For loop, the `$username` and `$departure` variables are added to `$employeeHash` as key/value pairs. If the `$username` for a JSON object is null or empty, the `$employee` variable is set as a key in `$employeeHash` with the value of "Alias not found".
<br>
<br>
Once all JSON objects have been iterated upon, the `$messageContent` variable is set using the keys within `$employeeHash`, sorted in order of their `$departure` values.
<br>
### Part 2: The GUI Prompt
The `$messageBox` variable is used to defined the parameters of a GUI prompt that lists the user accounts gathered in Part 1 and prompts the script user to confirm, deny, or cancel the account disabling process.
<br>
### Part 3: GUI Prompt Selection/Disabling User Accounts in AD
If the script user chooses either "No" or "Cancel" from the GUI prompt, 1 of 2 messages will be outputted to their console window:
<br>
<br>
**1.** "Users not disabled - Program ended." [Printed as a warning in the console window when script user chooses "No".]
<br>
<br>
**2.** "Program canceled." [Printed as regular console output when script user chooses "Cancel".]
<br>
<br>
If the script user chooses "Yes", an empty array named `$successArray` is created and a For loop iterates over the keys of `$employeeHash`. Inside the For loop, the `Get-ADUser` command is run against each key in `$employeeHash`. If `Get-ADUser` can return a user account object for a key, the user account is disabled and the account's *Name* and *Enabled* attributes are added to `$successArray`. If `Get-ADUser` cannot return a user account object for a key, a warning is outputted to the console window.

### Part 4: E-mail Notification
After the `$employeeHash` keys have been iterated upon, a variable, `$emailBody`, is created containing the contents of `$successAraay` in *String* format. Finally, a `Send-MailMessage` command is created using `$emailBody` and the variables specified in the **E-mail Notification Variables** section.
