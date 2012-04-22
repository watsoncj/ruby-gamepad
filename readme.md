This is an example of how to read from a USB gamepad using the ruby-usb gem.

The product and vendor IDs will likely need to be changed to match your device. See the `lspci` command for details on Unix-like operating systems.

Must be run with sufficient privileges to read from the device. This can be accomplished by running as root or by modifying your [udev rules](http://ubuntuforums.org/showthread.php?t=901891).

