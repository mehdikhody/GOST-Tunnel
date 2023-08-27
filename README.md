## Introduction

GOST-Tunnel is a simple and easy-to-use tool that allows you to tunnel your server via GOST. GOST is a versatile and secure transport layer security (TLS) proxy that supports multiple protocols and encryption algorithms. With GOST-Tunnel, you can easily set up a secure and reliable tunnel between your server and any other device.

In this article, we will discuss how to install and use GOST-Tunnel on your server.

## Installation

The first step in using GOST-Tunnel is to install it on your server. You can easily install GOST-Tunnel by running the following command:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/mehdikhody/GOST-Tunnel/master/install.sh)
```

This command will download and run the installation script for GOST-Tunnel. The script will automatically install all the necessary dependencies and configure GOST-Tunnel for you.

## Usage

Once you have installed GOST-Tunnel, you can use the `gtctl` command to manage your GOST-Tunnel configuration. Here are some of the most common commands:

### Show current config info

You can use the `info` command to show the current configuration of your GOST-Tunnel:

```bash
gtctl info
```

This command will display information about the current configuration of your GOST-Tunnel, including the Hostname and targeted ports.

### Start gost

You can use the start command to start your GOST-Tunnel service:

```bash
gtctl start
```

This command will start your GOST-Tunnel and begin listening for incoming connections.

### Stop gost

You can use the stop command to stop your GOST-Tunnel service:

```bash
gtctl stop
```

This command will stop your GOST-Tunnel and close all existing connections.

### Restart gost

You can use the restart command to restart your GOST-Tunnel service:

```bash
gtctl restart
```

This command will stop and then start your GOST-Tunnel service.

### Show gost status

You can use the status command to show the current status of your GOST-Tunnel service:

```bash
gtctl status
```

This command will display the current status of your GOST-Tunnel service, including whether it is running or stopped.

### Uninstall everything

You can use the uninstall command to completely uninstall GOST-Tunnel from your server:

```bash
gtctl uninstall
```

This command will remove all files and configurations related to GOST-Tunnel from your server.

### Update everything

You can use the update command to update GOST-Tunnel to the latest version:

```bash
gtctl update
```

This command will download and install the latest version of GOST-Tunnel on your server.

### Show help message

You can use the help command to display a help message for the gtctl command:

```bash
gtctl help
```

This command will display a list of available commands and their descriptions.

## Conclusion

In this article, we have discussed how to install and use GOST-Tunnel on your server. With GOST-Tunnel, you can easily set up a secure and reliable tunnel between your server and any other server. By using the gtctl command, you can manage your GOST-Tunnel configuration and perform various tasks such as starting, stopping, restarting, and updating GOST-Tunnel.
