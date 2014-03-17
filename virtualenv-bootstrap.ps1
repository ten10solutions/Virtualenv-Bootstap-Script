# Make PS stop when something's gone wrong - instead of ploughing on
# regardless.  Don't ask me when you'd want the default behaviour.
$ErrorActionPreference="Stop"

# Set some variables

# We're going to take the maximum version that matches this pattern
$PythonVersionPattern = "2.[67]"

$VirtualEnvName = "automation"
$VirtualEnvHome = "$env:USERPROFILE\python-envs"
$VirtualEnvPath = "$VirtualEnvHome\$VirtualEnvName"

$ShortcutName = "Automation Command Prompt"

# Places we might find out about installations.  As it's usually
# better to use 32 bit versions, we place the WOW64 prefixed versions
# first.  We will accept a 64 bit Python 2.7 over a 32 bit Python
# 2.6.  Remove or re-arrange as necessary
$PythonRegistryKeys = (
    "Registry::HKEY_CURRENT_USER\SOFTWARE\WOW6432Node\Python\PythonCore",
    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Python\PythonCore",
    "Registry::HKEY_CURRENT_USER\SOFTWARE\Python\PythonCore",
    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Python\PythonCore"
)


function Find-Python() {
    # If Python is on the path, and it matches the pattern above,
    # we'll go with that
    $python = Get-Command Python -ErrorAction SilentlyContinue
    if ($python -and (& $python --version 2>&1 -match $PythonVersionPattern)) {
    	return $python;
    }
    
    $found_version = $null
    $found_interpreter = $null
    
    # Find Pythons by investigating a number of registry keys which
    # might possibly point to python versions.
    foreach ($key in $PythonRegistryKeys) {
	$versions = @(Get-ChildItem $key -ErrorAction SilentlyContinue)
        $matching = ($versions |
	  foreach {$_.PSChildName} |
	  where {$_ -match $PythonVersionPattern} |
	  foreach {$_ -as [decimal]} |
	  where {$_ -gt $found_version }) | sort -descending

	foreach ($version in $matching) {
	    $path = (Get-ItemProperty "$key\$version\InstallPath" -Name '(default)').'(default)'
	    $interpreters = @(get-childitem "$path\python.exe" -ErrorAction SilentlyContinue)
	    if ($interpreters) {
	        $found_version = $version
		$found_interpreter = $interpreters[0]
		break;  # Go to the next registry hive.
	    }
	}
    
    }
    if (!$found_version) {
	throw "Unable to find a Python Installation!"
    }
    return $found_interpreter;
}

$python = Find-Python

## Install Pip
# WARNING: This will overwrite any pre-exisiting user installation of pip.

$pipfile = [io.path]::GetTempFileName();
$url = "https://raw.github.com/pypa/pip/master/contrib/get-pip.py";
$client = new-object System.Net.WebClient;
$client.DownloadFile($url, $pipfile);
Write-Debug "Downloaded Pip";
& $python $pipfile --user --ignore-installed | write-host;


## Use pip to install a recent virtualenv.
# WARNING: This will overwrite any pre-existing user installation of
# virtualenv
& "$env:APPDATA\Python\Scripts\pip.exe" install --user --ignore-installed virtualenv | write-host;

## Create a virtualenv
mkdir $VirtualEnvHome -ErrorAction SilentlyContinue | Out-Null;
& "$env:APPDATA\Python\Scripts\virtualenv.exe" $VirtualEnvPath | write-host;

## Create a shortcut on the desktop
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$Home\Desktop\$ShortcutName.lnk")
$Shortcut.TargetPath = "$env:windir\system32\cmd.exe"
$Shortcut.Arguments = "/k ""$VirtualEnvPath\Scripts\activate"""
$Shortcut.Save()
