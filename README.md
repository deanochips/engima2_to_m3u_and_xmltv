# Engima2_to_m3u_and_xmltv

Enigma2 to M3u and XMLTV allows you to generate m3u and xmltv files for use in iptv players such as Tivimate and plex,
it should work with all software that accepts these inputs

allowing you to get your terrestrial tv to your other devices.....
for example i am using it to get all the terrestrial channels to my androidtv nvidia shield

---

## Setup
1) Download/clone script 
2) edit stb_epg.cfg with your settings
3) Make the script is ready to run by: chmod +x stb_epg.sh
4) Run the script with help parameter first time: ./stb_epg.sh -HELP if you need help for parametes.
5) First time the script is used you need to run ./stb_epg.sh -GET_ALL 
to get data from your STB

This forces the creation of channel list from bouquets.

every time you change your bouquets you need to run GET_ALL, otherwise it will only update the epg

---

```
usage: stb_epg.sh [-PRINT] [-PRINT_ALL] [-GET_ALL] [-CONFIG] [-LOG] [-CHANGE]

optional arguments:
  -PRINT       Get feedback from the process (not from the wget program).
  -PRINT_ALL   Get feedback from wget program also.
  -GET_ALL     Create/recreate the m3u file also - Has to be used first time.
  -CONFIG      Only view result from config file in console.
  -LOG         Writing result to log file.
  -CHANGE      View change log.

  ```
  If none parameters are used it only recreate the EPG xml file (without any feedback to console).

---

## Automation 
#### Linux
Use crontab 

Example crontab:

`0 3 * * * /path/to/stb_epg.sh >> /path/to/log.log 2>&1`

---

## Acknowledgments
Special Thanks to Ole Andreas Gloersen
