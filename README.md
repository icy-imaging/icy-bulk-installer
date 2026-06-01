# Icy Bulk Installer

## Requirements

1. Java 17+ (25 recommended)
2. Maven
3. Git

## Preparation

### MacOS

1. Install Homebrew, follow the instruction here: https://brew.sh
2. Install Java: `brew install --cask zulu@25` (you can install Java 17 with 'zulu@17' or Java 21 with 'zulu@21')
3. Install Maven: `brew install maven`
4. Install Git: `brew install git`

### Linux

1. Install Java: `sudo apt install openjdk-25-jdk` (you can install Java 17 using 'openjdk-17-jdk' or Java 21 using 'openjdk-21-jdk')
2. Install Maven: `sudo apt install maven`
3. Install Git: `sudo apt install git`


### Windows

1. Install Java: https://www.azul.com/downloads/?version=java-25-lts&os=windows&package=jdk#zulu (choose the right architecture for your computer x64 or ARM64)
2. Download Maven binary package: https://maven.apache.org/download.cgi#CurrentMaven
3. Extract the tar.gz or zip previously downloaded
4. Copy the extracted folder (should be named like 'apache-maven-X.X.X') in your C:\Program Files\
5. Configure your PATH variable and set MAVEN_HOME and M2_HOME using this guide: https://stackoverflow.com/a/48411269
6. Install Git: https://git-scm.com/install/windows

## Testing requirements

In terminal for Macos and Linux, in CMD for Windows:

1. Test Java: `java -version`
2. Test Maven: `mvn -version`
3. Test Git: `git --version`

## Running script

### Unix (MacOS & Linux)

In terminal:

```shell
./unix_setup.sh --run
```

### Windows

In CMD:

```
.\win_setup.bat --run
```