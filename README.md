# Icy Bulk Installer

## Requirements

1. Java 17+ (25 recommended)
2. Maven 3.10+
3. Git

## Preparation

### Testing requirements

In Terminal for Macos and Linux, in CMD / Powershell for Windows:

1. Test Java: (you must be on Java 17+ to run the script properly)
```shell
java -version
``` 
2. Test Maven: (if you are not on Maven 3.10+, the script will not work)
```shell
mvn -version
``` 
3. Test Git: (any git version will work)
```shell
git --version
``` 

### MacOS (Apple Silicon)

1. Install Homebrew: https://brew.sh
    - run this command in your terminal: 
    ```shell
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ```
    - It will ask you to download and install `Xcode Command Line Tools` if it is not already the case, accept it
2. Install Java: (you can install Java 17 with `zulu@17` or Java 21 with `zulu@21`)
```shell
brew install --cask zulu@25
```
3. Install Maven:
```shell
brew install maven
```
4. Install Git:
```shell
brew install git
```

### MacOS (Intel)

>Unfortunately, you will not be able to use Homebrew on an Intel Mac anymore, but you can use [MacPorts](https://www.macports.org) instead.

1. Install MacPorts: https://guide.macports.org/#installing
    - Install Xcode from the Apple developer website: https://developer.apple.com/download/all/ (you will need an Apple account)
    - Install Macports by downloading, then running the correct `.pkg` file based on your macOS version: https://guide.macports.org/#installing.macports.binary
2. Install Java: (you can also install Java 17 with `openjdk17-zulu` or Java 21 with `openjdk21-zulu`)
```shell
sudo port install openjdk25-zulu
```
3. Install Maven:
```shell
sudo port install maven3
```
4. Install Git:
```shell
sudo port install git
```

### Linux

#### Debian based Linux (Ubuntu)

1. Update your package manager: 
    ```shell
    sudo apt update
    ```
    >It is also recommended to upgrade the already installed packages: 
    >```shell
    >sudo apt upgrade
    >```
2. Install Java: (you can install Java 17 using `openjdk-17-jdk` or Java 21 using `openjdk-21-jdk`)
```shell
sudo apt install openjdk-25-jdk
```
3. Install Maven:
```shell
sudo apt install maven
```
4. Install Git:
```shell
sudo apt install git
```

#### Arch based Linux (ArchLinux)

1. Install Java: (you can install Java 17 using `jdk17-openjdk` or Java 21 using `jdk21-openjdk`)
```shell
sudo pacman -S jdk25-openjdk
```
2. Install Maven:
```shell
sudo pacman -S maven
```
3. Install Git:
```shell
sudo pacman -S git
```

### Windows

1. Install Scoop: https://scoop.sh
    - Open PowerShell and type this command: 
    ```shell
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
    ```
1. Install Java: (you can install Java 17 with `java/zulu17-jdk` or Java 21 with `java/zulu21-jdk`)
```shell
scoop install java/zulu25-jdk
```
2. Install Maven:
```shell
scoop install main/maven
```
6. Install Git:
```shell
scoop install main/git
```

## Running script

Clone the repository:
```shell
git clone https://gitlab.pasteur.fr/bia/icy/icy-bulk-installer.git
```

This command will create a folder named 'icy-bulk-installer' and download the content of this repository inside this newly created folder.

Then move in this folder:
```shell
cd icy-bulk-installer
```

Then follow the steps below according to your operating system.

### Unix (MacOS & Linux)

In Terminal, from the same folder as the scripts:

```shell
./unix_setup.sh --run
```

### Windows

In CMD / Powershell from the same folder as the scripts:

```
.\win_setup.bat --run
```

> Note that the script will ask you permission to copy the `extensions.yml` present in this repository.
> If this step does not work, you can just copy the `extensions.yml` file into the `.icy` folder located in your personal folder:
> - `C:\Users\<your-username>\.icy\` in Windows
> - `~/.icy/` in macOS or Linux

## How to use this script

### Unix (MacOS & Linux)

Usage (in Terminal): ./unix_setup.sh [OPTIONS]

-  -v, --verbose     Show logs from Git and Maven
-  -c, --clean       Remove the install directory and start from scratch (cannot be used with --uninstall)
-  -u, --uninstall   Remove the install directory (cannot be used with --clean)
-  -r, --reset       Reset Icy's configuration directory (located at: $HOME/.icy)
-  --run             Run Icy at the end of the script
-  --run-only        Skip the installation and run Icy
-  -h, --help        Show this help message

### Windows

Usage (in CMD / Powershell): .\win_setup.bat [OPTIONS]

-  -v, --verbose     Show logs from Git and Maven
-  -c, --clean       Remove the install directory and start from scratch (cannot be used with --uninstall)
-  -u, --uninstall   Remove the install directory (cannot be used with --clean)
-  -r, --reset       Reset ICY's configuration directory (located at: %USERPROFILE%/.icy)
-  --run             Run Icy at the end of the script
-  --run-only        Skip the installation and run Icy
-  -h, --help        Show this help message

## How to update the script

Inside the 'icy-bulk-installer' folder, in the Terminal or CMD / Powershell:
```shell
git fetch
```

Then

```shell
git pull
```
