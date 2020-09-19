# Pi-Hole - Youtube Ads Blocker

![](https://deividsdocs.files.wordpress.com/2020/05/image.png)

This script will block all the Youtube's advertisement in your network. It must be used with Pi-Hole. This is a modification to include date and time info on the comment field on the blacklist database. It also add the URLs to the `my-adlist.txt` file and send the changes to GitHub.

## Installation
- Download the script 
  `cd ~`
  `# git clone https://github.com/AlexDCode/ytadsblocker.git`
- Move to the directory
  
  `# cd ytadsblocker`
- Make the script executable
   
   `# chmod a+x ytadsblocker.sh`
- Execute the script as root with the option: install
  
  `# sudo ./ytadsblocker.sh install`
- Start the service and that's it
  
  `# systemctl start ytadsblocker`
- View the status of the script

  `# sudo service ytadsblocker status`
- Stop ytadsblocker service

  `# sudo service ytadsblocker stop`
- Uninstall ytadsblocker

  `~/ytadsblocker uninstall`
## Legacy: prior to Pihole 5.0

- Just download the legacy version and follow the same previous steps, changing the name from `ytadsblocker` to `ytadsblocker_legacy`.

## More info
- Version 3.0 just works with Pihole 5.0 or newer. If you're running a lower version of Pihole, you must upgrade it.
- Instalación del script en [mi blog (ES)](https://deividsdocs.wordpress.com/2018/11/28/bloquear-anuncios-de-youtube-en-pihole/)
- Installation of the script in [my blog (EN)](https://deividsdocs.wordpress.com/2020/04/15/script-to-block-youtube-advertisements-in-pi-hole/)

## Buy me a coffe (To the Original Author)
[![ko-fi](https://www.ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/U7U01LTQB)
