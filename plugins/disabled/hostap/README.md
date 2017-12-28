Install the plugin on your own  risk !

Installing this plugin, will allow you to access Raspberry PI using WIFI and SSH

Steps.

Build the image with hostap plugin enabled.
Write the image to the SD CARD
Start Raspberry PI and wait 5 minutes.

Search for Pi0-AP WIFI network using a proper device (laptop,smartphone) and connect to it using "raspberry" password

Establish SSH connection to 192.168.1.1 using the default credentials (pi/raspberry)

In order to allow PI to be connected to the existing wireless network, execute /usr/bin/wifi-cfg script.

$ sudo su
# /usr/bin/wifi-cfg

Follow the wizard and confirm modification. After reboot, the raspberry PI will connect to the home network, so you can access it again via SSH using the IP provided by your home router.
Be aware that the script will set the device in DHCP mode, so you need to find the newly allocated ip address, consulting your router status page.
