# Overview

This is a set of bash scripts that will install Duo's interactive, self-service, two-factor authentication on Ubuntu linux systems.  This includes duo-login and duo-pam authentication methods.  

# Usage
1.  Clone the repository
2.  The scripts need root access, please perform a sudo -s prior to running the scripts
3.  Choose which script to run (either 1-install-duo-login.sh or 2-install-duo-pam.sh)
4.  Add a unix integration at the duosecurity.com website
5.  Copy and paste required keys into the dialog boxes

# Notes
This script is intended to be run after a fresh install of the ubuntu operating system.  It will replace your /etc/pam.d/common-auth file with a templated version after first backing it up.  It has been tested on Ubuntu 14.04 LTS (64 bit).  The script basically automates the instructions in the Duo Unix documentation at https://www.duosecurity.com/docs/duounix.  

# License
(The MIT License)

Copyright (c) 2014 waygee

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
