# Bigfix installer for v11.04 with current masthead approved by CM team
Echo "Begin Bigfix Installation"
# Create installation dir for Bigfix
sudo mkdir -v /etc/opt/BESClient
Echo "Download Masthead"
# Download latest BigFix Masthead
sudo wget http://epmanp.jackinthebox.com:52311/masthead/masthead.afxm -O /etc/opt/BESClient/
Echo "Download Bigfix-25% Complete" 
# Download 11.0.4 Bigfix Agent
sudo wget https://software.bigfix.com/download/bes/110/BESAgent-11.0.4.60-ubuntu18.amd64.deb -O /etc/opt/BESClient/BESAgent-11.0.4.60-ubuntu18.amd64.deb
Echo "Change permissions-50% Complete"
# elevate permissions on folder for BESClient
sudo chmod -R 777 /etc/opt/BESClient
Echo "Install BigFix-75% Complete"
# Install BES Agent with masthead
echo qu | sudo -S dpkg -i /etc/opt/BESClient/BESAgent-11.0.4.60-ubuntu18.amd64.deb 2>/dev/null
Echo "Verify Service is running-100% Complete"
#Start BES Service
systemctl | grep besclient
"Verify completed-Please take a picture for documentation"
#Show if service is working
ps -ef | grep -i besclient