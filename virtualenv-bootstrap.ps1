# Make PS stop when something's gone wrong - instead of ploughing on
# regardless.  Don't ask me when you'd want the default behaviour.
$ErrorActionPreference="Stop"

$python = "c:\python27\python.exe";
$pipfile = [io.path]::GetTempFileName();
$url = "https://raw.github.com/pypa/pip/master/contrib/get-pip.py";
$client = new-object System.Net.WebClient;
$client.DownloadFile($url, $pipfile);
Write-Debug "Downloaded Pip";
& $python $pipfile --user --ignore-installed | write-host;

& "$env:APPDATA\Python\Scripts\pip.exe" install --user --ignore-installed virtualenv | write-host;

mkdir "$env:USERPROFILE\python-envs" -ErrorAction SilentlyContinue | Out-Null;

$envpath = "$env:USERPROFILE\python-envs\automation"

& "$env:APPDATA\Python\Scripts\virtualenv.exe" $envpath | write-host;


$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$Home\Desktop\Automation Command Prompt.lnk")
$Shortcut.TargetPath = "$env:windir\system32\cmd.exe"
$Shortcut.Arguments = "/k ""$envpath\Scripts\activate"""
$Shortcut.Save()
