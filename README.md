# Installing a WSL Node

To set up your WSL environment for using Lilypad with GPU support, you need to install a few components. This guide will walk you through installing WSL and Docker Desktop to provide you with an Ubuntu instance for a Lilypad GPU provider node. You will also use a script to automatically setup Bacalhau, and Lilypad in that instance.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Setup](#setup)
    1. [Install WSL](#install-wsl)
    2. [Install Docker Desktop](#install-docker-desktop)
    3. [Configure Docker Desktop](#configure-docker-desktop)
    4. [Setup Resource Provider](#setup-resource-provider)


## Prerequisites

* Windows 10 22H2 or later
* Nvidia GPU (Turning architecture or newer)
* [Nvidia drivers](https://www.nvidia.com/en-us/drivers/)
* Wallet Private Key

## Setup

The setup is very similar to the procedure for setting up a GPU provider node on a Linux machine. The main difference is that WSL and Docker Desktop will be provding the Ubuntu environment with access to the GPU driver and CUDA libraries, as well as access to docker containers. This means we don't need to install the Nvidia drivers or the Container Toolkit in the Ubuntu instance as that functionality is provided by the Windows host.

### Install WSL

WSL is a compatibility layer for running Linux binary executables natively on Windows 10 or 11. It allows you to run a full-fledged Linux environment on Windows, including a terminal and access to the Linux package manager.

To install WSL2 on Windows 10, open a PowerShell terminal as an administrator and run the following command:

```bash
wsl --install
```

This will enable the required Windows Subsystem for Linux feature and install the latest version of WSL2 including an Ubuntu distribution.

As part of the installation process, you will be prompted to create a new user account and set a password. This account will be used to access the Ubuntu distribution in WSL.

### Install Docker Destkop

Docker Desktop is a tool for building, sharing, and running containerized applications. It allows you to run containers on your local machine, providing a consistent environment for your applications to run in.

To install Docker Desktop, download the installer from the [official Docker website](https://www.docker.com/products/docker-desktop) and follow the installation instructions.

Alternatively, you can use the following PowerShell commands to install Docker Desktop:

```powershell
Write-Host "Downloading Docker Desktop installer..."
$installerPath = $env:USERPROFILE + "\Downloads\Docker Desktop Installer.exe"

$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri https://desktop.docker.com/win/stable/Docker%20Desktop%20Installer.exe -OutFile $installerPath
$ProgressPreference = 'Continue'

Write-Host "Installing Docker Desktop..."
Start-Process -FilePath $installerPath -Wait -ArgumentList 'install', '--accept-license', '--backend=wsl-2'
```

Reboot when prompted.

## Configure Docker Desktop

When Docker Desktop is installed, you will need to check a few settings. Open Docker Desktop and follow these steps:

 - Settings > General > Enable "Use the WSL 2 based engine".

 - Settings > Resources > WSL Integration > Activate "Enable integration with my default WSL distro".

 - Settings > Resources > WSL Integration > Enable Ubuntu distribution.

 - Settings > Resources > Advanced > Disable "Resource Saver".

## Setup Resource Provider

Open the Ubuntu distribution in WSL by searching for "Ubuntu" in the Windows Start menu. This will open a terminal window running the Ubuntu distribution. 

Run the following command in the Ubuntu terminal to automatically install the required components for running a Lilypad GPU provider node:

```bash
wget https://raw.githubusercontent.com/rhochmayr/lp-wsl-native-rp/main/setup-node.sh && chmod +x setup-node.sh && ./setup-node.sh
```

The script will install and configure the following components:

 - Ubuntu distribution updates
 - Symlink for nvidia-smi
 - Bacalhau
 - Kubo & IPFS
 - Env file for Lilypad
 - Systemd unit for Bacalhau
 - Systemd unit for GPU provider

 The setup routine will also prompt you securely to enter your wallet private key. This key will be stored in the environment file for the GPU provider and is used to sign transactions on the Lilypad network.
