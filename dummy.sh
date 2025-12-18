#!/usr/bin/env bash

# Force reading from a real terminal (/dev/tty)
# This makes it behave like a real vendor installer
exec < /dev/tty

echo "Do you want to set a different device name? (y/n)"
read yn
   
if [[ "$yn" =~ [Yy] ]]; then
    echo "Please enter a name to identify this device"
    read device_name
    echo "You entered: $device_name"
else
    echo "Okay, keeping default name."
fi

echo ""
echo "Purple screen popup: please press [ENTER] to continue"
read _

echo "Setup complete!"
