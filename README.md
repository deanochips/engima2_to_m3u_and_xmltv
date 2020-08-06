# Engima2_to_m3u_and_xmltv


## install
1) Extract and edit stb_epg.conf
2) Make the script is ready to run by: chmod +x stb_epg.sh
3) Run the script with help parameter first time: ./stb_epg.sh HELP if you need help for parametes.
4) First time the script is used you need to run ./stb_epg.sh GET_ALL 
to get data from your STB

This forces the creation of channel list from bouquets.

every time you change your bouquets you need to run GET_ALL, otherwise it will only update the epg


Special Thanks to Ole Andreas Gloersen
