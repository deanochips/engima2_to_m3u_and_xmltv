#!/bin/bash
 
#######################################################################################################################
# 
# Script for generating IPTV file (m3u) and EPG file (xml) from Enigma2 STB 
# 
#######################################################################################################################
# 
# Reading parameters - 2018.10.01
#
#######################################################################################################################
#
# This is hard coded now!            stream_id_data="${stream_id_data} ${SERVICE_tag}=\"tv\""
#
#######################################################################################################################

Counter=0

Change_Log ()
{
  echo ""
  echo ""
  echo "#####################################################################################################"
  echo "#                                                                                                   #"
  echo "# Version 0.1 : Possible to create m3U playlist.                                                    #"
  echo "#                                                                                                   #"
  echo "# Version 0.8 : Added EPG to xmltv file.                                                            #"
  echo "#                                                                                                   #"
  echo "# Version 1.0 : Added logging to file function.                                                     #"
  echo "#                                                                                                   #"
  echo "# Version 1.1 : Added multi bouquets possibility.                                                   #"
  echo "#                                                                                                   #"
  echo "# Version 2.0 : Split long continuous script into separate functions.                               #"
  echo "#               Moved STB number from parameter name to separate parameter in STB string array.     #"
  echo "#                                                                                                   #"
  echo "# Version 2.1 : Split download and writing EPG function into smaller functions.                     #"
  echo "#                                                                                                   #"
  echo "# Version 2.2 : Added channel numer (from favorites) to xml file.                                   #"
  echo "#                                                                                                   #"
  echo "# Version 2.3 : Added config chioce for channel numer, name and number & name as separate           #"
  echo "#               parameters in config file.                                                          #"
  echo "#                                                                                                   #"
  echo "# Version 2.4 : Added config chioce for restart channel numbering from one on next STB.             #"
  echo "#                                                                                                   #"
  echo "# Version 3.0 : Added path setting so it shall work with cron job as well.                          #"
  echo "#               Added also possibility to set absolute path (starting with slash \"/\").              #"
  echo "#                                                                                                   #"
  echo "# Version 3.1 : Some variable fix in \"if-then\" statement with \" before and after text variable      #"
  echo "#                                                                                                   #"
  echo "#####################################################################################################"
  echo "#                                                                                                   #"
  echo "# Version x.x : EPG summary added end of listing. - TODO                                            #"
  echo "#                                                                                                   #"
  echo "#####################################################################################################"
  echo ""
  echo ""

}


#######################################################################################################################
#
# Defining variables
#

Script_version="3.0"
Script_date="2018.11.08"

START_TIME=`date +"%Y.%m.%d %H:%M:%S"`

DIR_script=`dirname $0`

Pattern=.
CONFIGFILE="${0%$Pattern*}"
LOGFILE=$CONFIGFILE".log"
CONFIGFILE=$CONFIGFILE".cfg"

IFS=';' 
FEEDBACK="NO"
GET_ALL="NO"
ONLY_CONFIG="FALSE"
LOGGING="FALSE"
PREVIOUSLY_SHOWN="NO"

STB_maks=0
STB_Count=0
Bouquets_Count=0
CHANNELCountTotal=0
CHANNELCountWrittenTotal=0
CHANNELCountTotalTemp=0
CHANNELCountWrittenTotalTemp=0
EPGDownloadCountTotal=0
EPGDownloadCountWrittenTotal=0
HEADChannelsCountTotal=0
HEADChannelsCountWrittenTotal=0

# 1: 
declare -a EPG_Summary

# Parametes from config file
OS_Type=""
Character_set=""
BIN_dir_rm=""
BIN_dir_mkdir=""
BIN_dir_wget=""
BIN_dir_lftp=""

declare -a STB_number
declare -a STB_ip
declare -a STB_port
declare -a STB_bouquet
declare -a STB_epg
declare -a DO_Bouquet_Name
declare -a DO_Bouquet_ID

DIR_tmp=""
DIR_bouquets=""
DIR_playlist=""
DIR_epg=""
DIR_log=""
DEL_tmp_files=""
CHANNEL_tag=""
EPG_tag=""
NAME_tag=""
LOGO_tag=""
BOUQUET_tag=""
SERVICE_tag=""
SERVICE_tag_tv=""
SERVICE_tag_radio=""
USE_CHANNEL_tag=""
USE_EPG_tag=""
USE_NAME_tag=""
USE_LOGO_tag=""
USE_BOUQUET_tag=""
USE_SERVICE_tag=""
USE_ID_LOGO_STREAM_tag=""
USE_ID_EPG_NAME_URL_tag=""
UTC_offset=""
HEADER_channel_name=""
HEADER_channel_number=""
HEADER_channel_number_name=""
Channel_number_continuous=""
EPG_language="uk"
EPG_episode_start_tag=""
EPG_episode_end_tag=""
EPG_episode_split_tag=""
EPG_season_split_tag=""
EPG_previously_shown_tag=""
EPG_genre_num_start=""
EPG_genre_num_text_split=""
EPG_genre_main_split=""
EPG_genre_sub_split=""
EPG_genre_write_full_string=yes
EPG_genre_write_split_string=yes
EPG_genre_upper_case_first_letter=yes
EPG_genre_write_number=yes



# --------------------------------------------------------------------------------------------------
# E2 service tag's
# --------------------------------------------------------------------------------------------------
TAG_e2servicelist_start="<e2servicelist>"
TAG_e2servicelist_end="</e2servicelist>"
TAG_e2service_start="<e2service>"
TAG_e2service_end="</e2service>"
TAG_e2servicereference_start="<e2servicereference>"
TAG_e2servicereference_end="</e2servicereference>"
TAG_e2servicename_start="<e2servicename>"
TAG_e2servicename_end="</e2servicename>"

# --------------------------------------------------------------------------------------------------
# E2 EPG tag's
# --------------------------------------------------------------------------------------------------
TAG_e2eventlist_start="<e2eventlist>"
TAG_e2eventlist_end="</e2eventlist>"
TAG_e2event_start="<e2event>"
TAG_e2event_end="</e2event>"
TAG_e2eventid_start="<e2eventid>"
TAG_e2eventid_end="</e2eventid>"
TAG_e2eventstart_start="<e2eventstart>"
TAG_e2eventstart_end="</e2eventstart>"
TAG_e2eventduration_start="<e2eventduration>"
TAG_e2eventduration_end="</e2eventduration>"
TAG_e2eventcurrenttime_start="<e2eventcurrenttime>"
TAG_e2eventcurrenttime_end="</e2eventcurrenttime>"
TAG_e2eventtitle_start="<e2eventtitle>"
TAG_e2eventtitle_end="</e2eventtitle>"
TAG_e2eventdescription_start="<e2eventdescription>"
TAG_e2eventdescription_end="</e2eventdescription>"
TAG_e2eventdescriptionextended_start="<e2eventdescriptionextended>"
TAG_e2eventdescriptionextended_end="</e2eventdescriptionextended>"
TAG_e2eventservicereference_start="<e2eventservicereference>"
TAG_e2eventservicereference_end="</e2eventservicereference>"
TAG_e2eventservicename_start="<e2eventservicename>"
TAG_e2eventservicename_end="</e2eventservicename>"
TAG_e2eventgenre_start="<e2eventgenre"
TAG_e2eventgenre_end="</e2eventgenre>"



#######################################################################################################################
# 
# Handeling script parameters
#
for Parameter in "$@"; do
  case "$Parameter" in
    "")
      shift
    ;;
    PRINT | -PRINT)
      FEEDBACK="PRINT"
      shift
    ;;
     PRINT_ALL | -PRINT_ALL)
      FEEDBACK="PRINT_ALL"
      shift
    ;;
    GET_ALL | -GET_ALL)
      GET_ALL="TRUE"
      shift
    ;;
    REGEN | -REGEN)
      GET_ALL="TRUE"
      shift
    ;;
    CONFIG | -CONFIG)
      FEEDBACK="PRINT"
      ONLY_CONFIG="TRUE"
      shift
    ;;
    LOG | -LOG)
      LOGGING="TRUE"
      shift
    ;;
    CHANGE | -CHANGE)
      Change_Log
      exit 0
    ;;
    HELP | -HELP)
      echo ""
      echo ""
      echo "EPG to xml file - Script version ${Script_version} (${Script_date})"
      echo ""
      echo ""
      echo "Help to script"
      echo ""
      echo "This script are for retreive channel's, create m3u file for IPTV setup"
      echo "and EPG from Enigma2 STB written to xml file"
      echo ""
      echo "Tested on VU+ Duo2 with OpenPLi 4.0"
      echo "Tested on VU+ Solo2 with OpenPLi 4.0"
      echo ""
      echo "The script can be renamed to any name but need to have a config file with the same name"
      echo "but only end with .cfg (My_new_name.sh will need My_new_name.cfg)."
      echo ""
      echo "If the config file is missing then it will be created with default values."
      echo "Then they has to be changed for your specific system."
      echo ""
      echo "With this name settings it is possible to test new configurations without destroing working config."
      echo ""
      echo ""
      echo "Valid parameters to script:"
      echo "PRINT     / -PRINT     : Get feedback from the process (not from the wget program)."
      echo "PRINT_ALL / -PRINT_ALL : Get feedback from wget program also."
      echo "GET_ALL   / -GET_ALL   : Create/recreate the m3u file also - Has to be used first time."
      echo "CONFIG    / -CONFIG    : Only view result from config file in console."
      echo "LOG       / -LOG       : Writing result to log file."
      echo "CHANGE    / -CHANGE    : View change log."
      echo ""
      echo "If none parameters are used it only recreat the EPG xml file (without any feedback to console)."
      echo ""
      echo ""
      exit 0
    ;;
  esac
done


Read_Config ()
{
  #######################################################################################################################
  # 
  # Read the config file
  #
  #######################################################################################################################

  Pattern=\=
  while read ConfigLineIn
  do
    case ${ConfigLineIn%%$Pattern*} in
      OS_Type)
        OS_Type="${ConfigLineIn#*$Pattern}"
      ;;
      Character_set)
        Character_set="${ConfigLineIn#*$Pattern}"
      ;;
      ${OS_Type}_BIN_dir_rm)
        BIN_dir_rm="${ConfigLineIn#*$Pattern}"
      ;;
      ${OS_Type}_BIN_dir_mkdir)
        BIN_dir_mkdir="${ConfigLineIn#*$Pattern}"
      ;;
      ${OS_Type}_BIN_dir_wget)
        BIN_dir_wget="${ConfigLineIn#*$Pattern}"
      ;;
      ${OS_Type}_BIN_dir_lftp)
        BIN_dir_lftp="${ConfigLineIn#*$Pattern}"
      ;;
      STB)
        STB_tmp="${ConfigLineIn#*$Pattern}"
        SplitSTBstring=\,
        ((STB_maks++))
        STB_number[${STB_maks}]="${STB_tmp%%$SplitSTBstring*}"
        STB_tmp="${STB_tmp#*$SplitSTBstring}"
        STB_ip[${STB_maks}]="${STB_tmp%%$SplitSTBstring*}"
        STB_tmp="${STB_tmp#*$SplitSTBstring}"
        STB_port[${STB_maks}]="${STB_tmp%%$SplitSTBstring*}"
        STB_tmp="${STB_tmp#*$SplitSTBstring}"
        STB_bouquet[${STB_maks}]="${STB_tmp%$SplitSTBstring*}"
        STB_epg[${STB_maks}]="${STB_tmp#*$SplitSTBstring}"
      ;;
      DIR_tmp)
        DIR_tmp="${ConfigLineIn#*$Pattern}"
        if [[ ! ${DIR_tmp:0:1} == "/" ]]; then
          DIR_tmp="${DIR_script}/${DIR_tmp}"
        fi
        if [[ ! ${DIR_tmp:$((${#DIR_tmp}-1)):1} == "/" ]]; then
          DIR_tmp="${DIR_tmp}/"
        fi
      ;;
      DIR_bouquets)
        DIR_bouquets=${ConfigLineIn#*$Pattern}
        if [[ ! ${DIR_bouquets:0:1} == "/" ]]; then
          DIR_bouquets="${DIR_script}/${DIR_bouquets}"
        fi
        if [[ ! ${DIR_bouquets:$((${#DIR_bouquets}-1)):1} == "/" ]]; then
          DIR_bouquets="${DIR_bouquets}/"
        fi
      ;;
      DIR_playlist)
        DIR_playlist=${ConfigLineIn#*$Pattern}
        if [[ ! ${DIR_playlist:0:1} == "/" ]]; then
          DIR_playlist="${DIR_script}/${DIR_playlist}"
        fi
        if [[ ! ${DIR_playlist:$((${#DIR_playlist}-1)):1} == "/" ]]; then
          DIR_playlist="${DIR_playlist}/"
        fi
      ;;
      DIR_epg)
        DIR_epg=${ConfigLineIn#*$Pattern}
        if [[ ! ${DIR_epg:0:1} == "/" ]]; then
          DIR_epg="${DIR_script}/${DIR_epg}"
        fi
        if [[ ! ${DIR_epg:$((${#DIR_epg}-1)):1} == "/" ]]; then
          DIR_epg="${DIR_epg}/"
        fi
      ;;
      DIR_log)
        DIR_log=${ConfigLineIn#*$Pattern}
        if [[ ! ${DIR_log:0:1} == "/" ]]; then
          DIR_log="${DIR_script}/${DIR_log}"
        fi
        if [[ ! ${DIR_log:$((${#DIR_log}-1)):1} == "/" ]]; then
          DIR_log="${DIR_log}/"
        fi
      ;;
  	
      DEL_tmp_files)
        DEL_tmp_files="${ConfigLineIn#*$Pattern}"
      ;;  
  
      CHANNEL_tag)
        CHANNEL_tag="${ConfigLineIn#*$Pattern}"
      ;;  
      EPG_tag)
        EPG_tag="${ConfigLineIn#*$Pattern}"
      ;; 
      NAME_tag)
        NAME_tag="${ConfigLineIn#*$Pattern}"
      ;;
      LOGO_tag)
        LOGO_tag="${ConfigLineIn#*$Pattern}"
      ;;
      BOUQUET_tag)
        BOUQUET_tag="${ConfigLineIn#*$Pattern}"
      ;; 
      SERVICE_tag)
        SERVICE_tag="${ConfigLineIn#*$Pattern}"
      ;;
 
      SERVICE_tag_tv)
        SERVICE_tag_tv="${ConfigLineIn#*$Pattern}"
      ;;
      SERVICE_tag_radio)
        SERVICE_tag_radio="${ConfigLineIn#*$Pattern}"
      ;;
  
      USE_CHANNEL_tag)
        USE_CHANNEL_tag="${ConfigLineIn#*$Pattern}"
      ;;
      USE_EPG_tag)
        USE_EPG_tag="${ConfigLineIn#*$Pattern}"
      ;;
      USE_NAME_tag)
        USE_NAME_tag="${ConfigLineIn#*$Pattern}"
      ;;
      USE_LOGO_tag)
        USE_LOGO_tag="${ConfigLineIn#*$Pattern}"
      ;; 
      USE_BOUQUET_tag)
        USE_BOUQUET_tag="${ConfigLineIn#*$Pattern}"
      ;;
      USE_SERVICE_tag)
        USE_SERVICE_tag="${ConfigLineIn#*$Pattern}"
      ;;
      USE_ID_LOGO_STREAM_tag)
        USE_ID_LOGO_STREAM_tag="${ConfigLineIn#*$Pattern}"
      ;;
      USE_ID_EPG_NAME_URL_tag)
        USE_ID_EPG_NAME_URL_tag="${ConfigLineIn#*$Pattern}"
      ;;
      UTC_offset)
        UTC_offset="${ConfigLineIn#*$Pattern}"
      ;;
      HEADER_channel_name)
        HEADER_channel_name="${ConfigLineIn#*$Pattern}"
      ;;
      HEADER_channel_number)
        HEADER_channel_number="${ConfigLineIn#*$Pattern}"
      ;;
      HEADER_channel_number_name)
        HEADER_channel_number_name="${ConfigLineIn#*$Pattern}"
      ;;
      Channel_number_continuous)
        Channel_number_continuous="${ConfigLineIn#*$Pattern}"
      ;;
      EPG_language)
        EPG_episode_start_tag="${ConfigLineIn#*$Pattern}"
      ;;
      EPG_episode_start_tag)
        EPG_episode_start_tag="${ConfigLineIn#*$Pattern}"
      ;;
      EPG_episode_end_tag)
        EPG_episode_end_tag="${ConfigLineIn#*$Pattern}"
      ;;
      EPG_episode_split_tag)
        EPG_episode_split_tag="${ConfigLineIn#*$Pattern}"
      ;;
      EPG_season_split_tag)
        EPG_season_split_tag="${ConfigLineIn#*$Pattern}"
      ;; 

      EPG_previously_shown_tag)
        EPG_previously_shown_tag="${ConfigLineIn#*$Pattern}"
      ;;
      EPG_genre_num_start)
        EPG_genre_num_start="${ConfigLineIn#*$Pattern}"
      ;; 
      EPG_genre_num_text_split)
        EPG_genre_num_text_split="${ConfigLineIn#*$Pattern}"
      ;; 
      EPG_genre_main_split)
        EPG_genre_main_split="${ConfigLineIn#*$Pattern}"
      ;; 
      EPG_genre_sub_split)
        EPG_genre_sub_split="${ConfigLineIn#*$Pattern}"
      ;; 
      EPG_genre_write_full_string)
        EPG_genre_write_full_string="${ConfigLineIn#*$Pattern}"
      ;; 
      EPG_genre_write_split_string)
        EPG_genre_write_split_string="${ConfigLineIn#*$Pattern}"
      ;; 
      EPG_genre_upper_case_first_letter)
        EPG_genre_upper_case_first_letter="${ConfigLineIn#*$Pattern}"
      ;; 
      EPG_genre_write_number)
        EPG_genre_write_number="${ConfigLineIn#*$Pattern}"
      ;; 

      *)
#        if [[ ! "${ConfigLineIn:0:1}" == "#" ]]; then
#          if [[ ${#ConfigLineIn} -gt 3 ]]; then
#            echo "Not found: ${ConfigLineIn}"
#          fi
#        fi
      ;;
    esac
  done <$CONFIGFILE

}


Create_Directories ()
{
  #######################################################################################################################
  # 
  # Create directories if not exsists
  #
  #######################################################################################################################

  if [[ "${FEEDBACK}" == "PRINT" ]] || [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
    echo ""
    echo ""
  fi
  if [[ "${LOGGING}" == "TRUE" ]]; then
    if [[ ! -d "${DIR_log}" ]] && [[ ! ${DIR_log} == "./" ]]; then
      if [[ "${FEEDBACK}" == "PRINT" ]] || [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
        echo "Creating..............: ${DIR_log}"
      fi
      ${BIN_dir_mkdir}mkdir -p ${DIR_log}
      echo "" > ${DIR_log}${LOGFILE}
      echo "" >> ${DIR_log}${LOGFILE}
      echo "Creating..............: ${DIR_log}" >> ${DIR_log}${LOGFILE}
    else
      echo "" > ${DIR_log}${LOGFILE}
      echo "" >> ${DIR_log}${LOGFILE}
    fi
  fi
  if [[ ! -d "${DIR_tmp}" ]] && [[ ! ${DIR_tmp} == "./" ]]; then
    if [[ "${FEEDBACK}" == "PRINT" ]] || [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
      echo "Creating..............: ${DIR_tmp}"
    fi
    if [[ "${LOGGING}" == "TRUE" ]]; then
      echo "Creating..............: ${DIR_tmp}" >> ${DIR_log}${LOGFILE}
    fi
    ${BIN_dir_mkdir}mkdir -p ${DIR_tmp}
  fi
  if [[ ! -d "${DIR_bouquets}" ]] && [[ ! ${DIR_bouquets} == "./" ]]; then
    if [[ "${FEEDBACK}" == "PRINT" ]] || [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
      echo "Creating..............: ${DIR_bouquets}"
    fi
    if [[ "${LOGGING}" == "TRUE" ]]; then
      echo "Creating..............: ${DIR_bouquets}" >> ${DIR_log}${LOGFILE}
    fi
    ${BIN_dir_mkdir}mkdir -p ${DIR_bouquets}
  fi
  if [[ ! -d "${DIR_playlist}" ]] && [[ ! ${DIR_playlist} == "./" ]]; then
    if [[ "${FEEDBACK}" == "PRINT" ]] || [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
      echo "Creating..............: ${DIR_playlist}"
    fi
    if [[ "${LOGGING}" == "TRUE" ]]; then
      echo "Creating..............: ${DIR_playlist}" >> ${DIR_log}${LOGFILE}
    fi
    ${BIN_dir_mkdir}mkdir -p ${DIR_playlist}
  fi
  if [[ ! -d "${DIR_epg}" ]] && [[ ! ${DIR_epg} == "./" ]]; then
    if [[ "${FEEDBACK}" == "PRINT" ]] || [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
      echo "Creating..............: ${DIR_epg}"
    fi
    if [[ "${LOGGING}" == "TRUE" ]]; then
      echo "Creating..............: ${DIR_epg}" >> ${DIR_log}${LOGFILE}
    fi
    ${BIN_dir_mkdir}mkdir -p ${DIR_epg}
  fi

}


Display_Config_data ()
{
  #######################################################################################################################
  # 
  # Display config data
  #
  #######################################################################################################################

  if [[ "${FEEDBACK}" == "PRINT" ]] || [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
    echo ""
    echo ""
    echo "Config file name......: ${CONFIGFILE}"
    echo ""
    echo "OS type...............: ${OS_Type}"
    echo "Character set.........: ${Character_set}"
    echo ""

    echo "Directory of rm.......: ${BIN_dir_rm}"
    echo "Directory of mkdir....: ${BIN_dir_mkdir}"
    echo "Directory of wget.....: ${BIN_dir_wget}"
    echo "Directory of lftp.....: ${BIN_dir_lftp}"


    echo ""

    STB_Count=1
    while [[ ${STB_Count} -le ${STB_maks} ]]; do
      echo "STB number............: ${STB_number[${STB_Count}]}"
      echo "STB IP................: ${STB_ip[${STB_Count}]}"
      echo "STB streaming port....: ${STB_port[${STB_Count}]}"
      echo "Bouquet name..........: ${STB_bouquet[${STB_Count}]}"
      echo "Get EPG from STB......: ${STB_epg[${STB_Count}]}"
      echo ""
      ((STB_Count++))
    done

    echo "Temporary directory...: ${DIR_tmp}"
    echo "Bouquets directory....: ${DIR_bouquets}"
    echo "Play list directory...: ${DIR_playlist}"
    echo "EPG directory.........: ${DIR_epg}"
    echo "LOG directory.........: ${DIR_log}"

    echo ""

    echo "Delete temporary files: ${DEL_tmp_files}"

    echo ""

    echo "Channel tag................: ${CHANNEL_tag}"
    echo "EPG tag....................: ${EPG_tag}"
    echo "Channel name tag...........: ${NAME_tag}"
    echo "Logo tag...................: ${LOGO_tag}"
    echo "Bouquet Channel............: ${BOUQUET_tag}"
    echo "Service tag................: ${SERVICE_tag}"
    echo ""
    echo "Service tag for TV.........: ${SERVICE_tag_tv}"
    echo "Service tag for radio......: ${SERVICE_tag_radio}"
    echo ""
    echo "Use channel tag............: ${USE_CHANNEL_tag}"
    echo "Use EPG tag................: ${USE_EPG_tag}"
    echo "Use channel name tag.......: ${USE_NAME_tag}"
    echo "Use logo tag...............: ${USE_LOGO_tag}"
    echo "Use bouquet tag............: ${USE_BOUQUET_tag}"
    echo "Use service tag............: ${USE_SERVICE_tag}"
    echo ""
    echo "Logo ID = stream ID........: ${USE_ID_LOGO_STREAM_tag}"
    echo "EPG ID (name/url)..........: ${USE_ID_EPG_NAME_URL_tag}"
    echo ""
    echo "Time offset................: ${UTC_offset}"
    echo "Header - use name..........: ${HEADER_channel_name}"
    echo "Header - use number........: ${HEADER_channel_number}"
    echo "Header - use number & name.: ${HEADER_channel_number_name}"
 
    echo ""

  fi

  if [[ "${LOGGING}" == "TRUE" ]]; then
    echo "" >> ${DIR_log}${LOGFILE}
    echo "Config file name...........: ${CONFIGFILE}" >> ${DIR_log}${LOGFILE}
    echo "" >> ${DIR_log}${LOGFILE}

    echo "Directory of rm............: ${BIN_dir_rm}" >> ${DIR_log}${LOGFILE}
    echo "Directory of mkdir.........: ${BIN_dir_mkdir}" >> ${DIR_log}${LOGFILE}
    echo "Directory of wget..........: ${BIN_dir_wget}" >> ${DIR_log}${LOGFILE}
    echo "Directory of lftp..........: ${BIN_dir_lftp}" >> ${DIR_log}${LOGFILE}


    echo "" >> ${DIR_log}${LOGFILE}

    STB_Count=1
    while [[ ${STB_Count} -le ${STB_maks} ]]; do >> ${DIR_log}${LOGFILE}
      echo "STB number.................: ${STB_number[${STB_Count}]}" >> ${DIR_log}${LOGFILE}
      echo "STB IP.....................: ${STB_ip[${STB_Count}]}" >> ${DIR_log}${LOGFILE}
      echo "STB streaming port.........: ${STB_port[${STB_Count}]}" >> ${DIR_log}${LOGFILE}
      echo "Bouquet name...............: ${STB_bouquet[${STB_Count}]}" >> ${DIR_log}${LOGFILE}
      echo "Get EPG from STB...........: ${STB_epg[${STB_Count}]}" >> ${DIR_log}${LOGFILE}
      echo "" >> ${DIR_log}${LOGFILE}
      ((STB_Count++)) >> ${DIR_log}${LOGFILE}
    done >> ${DIR_log}${LOGFILE}

    echo "Temporary directory........: ${DIR_tmp}" >> ${DIR_log}${LOGFILE}
    echo "Bouquets directory.........: ${DIR_bouquets}" >> ${DIR_log}${LOGFILE}
    echo "Play list directory........: ${DIR_playlist}" >> ${DIR_log}${LOGFILE}
    echo "EPG directory..............: ${DIR_epg}" >> ${DIR_log}${LOGFILE}
    echo "LOG directory..............: ${DIR_log}" >> ${DIR_log}${LOGFILE}

    echo "" >> ${DIR_log}${LOGFILE}

    echo "Delete temporary files: ${DEL_tmp_files}" >> ${DIR_log}${LOGFILE}

    echo "" >> ${DIR_log}${LOGFILE}

    echo "Channel tag................: ${CHANNEL_tag}" >> ${DIR_log}${LOGFILE}
    echo "EPG tag....................: ${EPG_tag}" >> ${DIR_log}${LOGFILE}
    echo "Channel name tag...........: ${NAME_tag}" >> ${DIR_log}${LOGFILE}
    echo "Logo tag...................: ${LOGO_tag}" >> ${DIR_log}${LOGFILE}
    echo "Bouquet Channel............: ${BOUQUET_tag}" >> ${DIR_log}${LOGFILE}
    echo "Service tag................: ${SERVICE_tag}" >> ${DIR_log}${LOGFILE}
    echo "" >> ${DIR_log}${LOGFILE}
    echo "Service tag for TV.........: ${SERVICE_tag_tv}" >> ${DIR_log}${LOGFILE}
    echo "Service tag for radio......: ${SERVICE_tag_radio}" >> ${DIR_log}${LOGFILE}
    echo "" >> ${DIR_log}${LOGFILE}
    echo "Use channel tag............: ${USE_CHANNEL_tag}" >> ${DIR_log}${LOGFILE}
    echo "Use EPG tag................: ${USE_EPG_tag}" >> ${DIR_log}${LOGFILE}
    echo "Use channel name tag.......: ${USE_NAME_tag}" >> ${DIR_log}${LOGFILE}
    echo "Use logo tag...............: ${USE_LOGO_tag}" >> ${DIR_log}${LOGFILE}
    echo "Use bouquet tag............: ${USE_BOUQUET_tag}" >> ${DIR_log}${LOGFILE}
    echo "Use service tag............: ${USE_SERVICE_tag}" >> ${DIR_log}${LOGFILE}
    echo "" >> ${DIR_log}${LOGFILE}
    echo "Logo ID = stream ID........: ${USE_ID_LOGO_STREAM_tag}" >> ${DIR_log}${LOGFILE}
    echo "EPG ID (name/url)..........: ${USE_ID_EPG_NAME_URL_tag}" >> ${DIR_log}${LOGFILE}

    echo "" >> ${DIR_log}${LOGFILE}

  fi

  if [[ "${ONLY_CONFIG}" == "TRUE" ]]; then
    if [[ "${LOGGING}" == "TRUE" ]]; then
      echo "Exit - Only display data from logfile" >> ${DIR_log}${LOGFILE}
      echo "" >> ${DIR_log}${LOGFILE}
    fi
    exit 0
  fi  

}


Download_Bouquets_List ()
{
  if [[ "${FEEDBACK}" == "PRINT" ]] || [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
    echo "=========================================================================="
    echo ""
    echo "Donwloading bouquets from STB"
    echo ""
    echo "--------------------------------------------------------------------------"
    echo ""
  fi
  if [[ "${LOGGING}" == "TRUE" ]]; then
    echo "==========================================================================" >> ${DIR_log}${LOGFILE}
    echo "" >> ${DIR_log}${LOGFILE}
    echo "Donwloading bouquets from STB" >> ${DIR_log}${LOGFILE}
    echo "" >> ${DIR_log}${LOGFILE}
    echo "--------------------------------------------------------------------------" >> ${DIR_log}${LOGFILE}
    echo "" >> ${DIR_log}${LOGFILE}
  fi
  #######################################################################################################################
  # 
  # Do the download of bouquets list
  #
  #######################################################################################################################

  if [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
    ${BIN_dir_wget}wget http://${STB_ip[${STB_Count}]}/web/getservices -O ${DIR_bouquets}stb${STB_number[${STB_Count}]}_bouquets_listing.xml
  else
    ${BIN_dir_wget}wget http://${STB_ip[${STB_Count}]}/web/getservices -q -O ${DIR_bouquets}stb${STB_number[${STB_Count}]}_bouquets_listing.xml
  fi

}


Get_Bouquets_Addresses ()
{

  for DO_Bouquet in ${STB_bouquet[${STB_Count}]}; do

    while read bouquets_line; do

      if [[ $bouquets_line == *${TAG_e2service_start}* ]]; then
        TAG_type=${TAG_e2service_start}
      fi
      if [[ $bouquets_line == *${TAG_e2servicereference_start}* ]]; then
        TAG_type=${TAG_e2servicereference_start}
      fi
      if [[ $bouquets_line == *${TAG_e2servicename_start}* ]]; then
        TAG_type=${TAG_e2servicename_start}
      fi
      if [[ $bouquets_line == *${TAG_e2service_end}* ]]; then
        TAG_type=${TAG_e2service_end}
      fi
      if [[ $bouquets_line == *${TAG_e2servicelist_end}* ]]; then
        TAG_type=${TAG_e2servicelist_end}
      fi
      if [[ $bouquets_line == *"&lt;n/a&gt;"* ]]; then
        DO_SKIP="YES"
      fi

      case "${TAG_type}" in
        ${TAG_e2service_start})
          service="TRUE"
        ;;
        ${TAG_e2servicereference_start})
          Line_tmp="${bouquets_line#*$TAG_e2servicereference_start}"
          Bouquet_ID="${Line_tmp%$TAG_e2servicereference_end*}"
        ;;
        ${TAG_e2servicename_start})
          Line_tmp="${bouquets_line#*$TAG_e2servicename_start}"
          Bouquet_Name="${Line_tmp%$TAG_e2servicename_end*}"
        ;;
        ${TAG_e2service_end})
          if [[ "${Bouquet_Name}" == "${DO_Bouquet}" ]]; then
            ((Bouquets_Count++))
            bouquet_found="TRUE"
            DO_Bouquet_Name[${Bouquets_Count}]=${Bouquet_Name}
            DO_Bouquet_ID[${Bouquets_Count}]=${Bouquet_ID}
            if [[ "${FEEDBACK}" == "PRINT" ]] || [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
              echo "ID to the bouquet \"${DO_Bouquet}\" is: ${Bouquet_ID}"
            fi
            if [[ "${LOGGING}" == "TRUE" ]]; then
              echo "ID to the bouquet \"${DO_Bouquet}\" is: ${Bouquet_ID}" >> ${DIR_log}${LOGFILE}
            fi 
          fi
        ;;
      esac
    done <${DIR_bouquets}stb${STB_number[${STB_Count}]}_bouquets_listing.xml

  done
  if [[ "${FEEDBACK}" == "PRINT" ]] || [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
    echo ""
  fi
  if [[ "${LOGGING}" == "TRUE" ]]; then
    echo "" >> ${DIR_log}${LOGFILE}
  fi

}


Download_Channel_Lists ()
{
  TMP_Bouquets_Count=1
  while [[ ${TMP_Bouquets_Count} -le ${Bouquets_Count} ]]; do
    #######################################################################################################################
    # 
    # Get channel list
    #
    #######################################################################################################################

    Bouquet_ID=${DO_Bouquet_ID[${TMP_Bouquets_Count}]}
    if [[ "${FEEDBACK}" == "PRINT" ]] || [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
      echo "--------------------------------------------------------------------------"
      echo ""
      echo "Donwloading channel list from STB for bouquet \"${DO_Bouquet_Name[${TMP_Bouquets_Count}]}\""
      echo ""
    fi
    if [[ "${LOGGING}" == "TRUE" ]]; then
      echo "--------------------------------------------------------------------------" >> ${DIR_log}${LOGFILE}
      echo "" >> ${DIR_log}${LOGFILE}
      echo "Donwloading channel list from STB for bouquet \"${DO_Bouquet_Name[${TMP_Bouquets_Count}]}\"" >> ${DIR_log}${LOGFILE}
      echo "" >> ${DIR_log}${LOGFILE}
    fi
    Bouquet_ID=${Bouquet_ID// /%20}
    Bouquet_ID=${Bouquet_ID//\"/%22}
    if [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
      ${BIN_dir_wget}wget http://${STB_ip[${STB_Count}]}/web/getservices?sRef=${Bouquet_ID} -O ${DIR_bouquets}stb${STB_number[${STB_Count}]}_bouquet_${TMP_Bouquets_Count}_channel_listing.xml
    else
      ${BIN_dir_wget}wget http://${STB_ip[${STB_Count}]}/web/getservices?sRef=${Bouquet_ID} -q -O ${DIR_bouquets}stb${STB_number[${STB_Count}]}_bouquet_${TMP_Bouquets_Count}_channel_listing.xml
    fi
    ((TMP_Bouquets_Count++))
  done
  if [[ "${FEEDBACK}" == "PRINT" ]] || [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
    echo ""
  fi
  if [[ "${LOGGING}" == "TRUE" ]]; then
    echo "" >> ${DIR_log}${LOGFILE}
  fi

}


Write_m3u_Playlist ()
{
  #######################################################################################################################
  # 
  # Creating play list
  #
  #######################################################################################################################

  if [[ "${FEEDBACK}" == "PRINT" ]] || [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
    echo ""
    echo "=========================================================================="
    echo ""
    echo "Creating play list for STB"
    echo ""
    echo "--------------------------------------------------------------------------"
    echo ""
  fi
  if [[ "${LOGGING}" == "TRUE" ]]; then
    echo "" >> ${DIR_log}${LOGFILE}
    echo "==========================================================================" >> ${DIR_log}${LOGFILE}
    echo "" >> ${DIR_log}${LOGFILE}
    echo "Creating play list for STB" >> ${DIR_log}${LOGFILE}
    echo "" >> ${DIR_log}${LOGFILE}
    echo "--------------------------------------------------------------------------" >> ${DIR_log}${LOGFILE}
    echo "" >> ${DIR_log}${LOGFILE}
  fi
  echo "#EXTM3U" > ${DIR_playlist}stb${STB_number[${STB_Count}]}_playlist.m3u

  TMP_Bouquets_Count=0

  if [[ $Channel_number_continuous == "no" ]]; then
    CHANNELCount=0
    CHANNELCountWritten=0
  fi

  for DO_Bouquets in ${STB_bouquet[${STB_Count}]}
  do
    ((TMP_Bouquets_Count++))
    CHANNELCountTemp=0
    CHANNELCountWrittenTemp=0
    DO_SKIP="NO"

    while read channel_line; do

      if [[ $channel_line == *${TAG_e2service_start}* ]]; then
        TAG_type=${TAG_e2service_start}
      fi
      if [[ $channel_line == *${TAG_e2servicereference_start}* ]]; then
        TAG_type=${TAG_e2servicereference_start}
      fi
        if [[ $channel_line == *${TAG_e2servicename_start}* ]]; then
        TAG_type=${TAG_e2servicename_start}
      fi
      if [[ $channel_line == *${TAG_e2service_end}* ]]; then
        TAG_type=${TAG_e2service_end}
      fi
      if [[ $channel_line == *${TAG_e2servicelist_end}* ]]; then
        TAG_type=${TAG_e2servicelist_end}
      fi
      if [[ $channel_line == *"&lt;n/a&gt;"* ]]; then
        DO_SKIP="YES"
      fi

      case "${TAG_type}" in
        ${TAG_e2service_start})
          ((CHANNELCount++))
          ((CHANNELCountTotal++))
          ((CHANNELCountTemp++))
          ((CHANNELCountTotalTemp++))
        ;;
        ${TAG_e2servicereference_start})
          Line_tmp="${channel_line#*$TAG_e2servicereference_start}"
          stream_address="${Line_tmp%$TAG_e2servicereference_end*}"
        ;;
        ${TAG_e2servicename_start})
          Line_tmp="${channel_line#*$TAG_e2servicename_start}"
          channel_name="${Line_tmp%$TAG_e2servicename_end*}"
        ;;
        ${TAG_e2service_end})

          # - #EXTINF:-1 tvg-chno="a" tvg-id="b" tvg-name="c" tvg-logo="d" group-title="e",f
          # - http://stream.url         

          stream_id_data="#EXTINF:-1 "
          if [[  "${USE_CHANNEL_tag}" == "yes" ]]; then
            stream_id_data="${stream_id_data} ${CHANNEL_tag}=\"${CHANNELCount}\""
          fi
          if [[  "${USE_EPG_tag}" == "yes" ]]; then
            if [[  "${USE_ID_EPG_NAME_URL_tag}" == "name" ]]; then
              stream_id_data="${stream_id_data} ${EPG_tag}=\"${channel_name}\""
            else
              stream_id_data="${stream_id_data} ${EPG_tag}=\"http://${STB_ip[${STB_Count}]}/web/epgservice?sRef=${stream_address}\""
            fi
          fi
          if [[  "${USE_NAME_tag}" == "yes" ]]; then
            stream_id_data="${stream_id_data} ${NAME_tag}=\"${channel_name}\""
          fi
          if [[  "${USE_LOGO_tag}" == "yes" ]]; then
            if [[  "${USE_ID_LOGO_STREAM_tag}" == "yes" ]]; then
              stream_id_data="${stream_id_data} ${LOGO_tag}=\"${stream_address}\""
            else
              stream_id_data="${stream_id_data} ${LOGO_tag}=\"${channel_name}\""
            fi
          fi
          if [[  "${USE_BOUQUET_tag}" == "yes" ]]; then
            stream_id_data="${stream_id_data} ${BOUQUET_tag}=\"${DO_Bouquets}\""
          fi
          if [[  "${USE_SERVICE_tag}" == "yes" ]]; then
            stream_id_data="${stream_id_data} ${SERVICE_tag}=\"tv\""
          fi
          if [[  "${USE_NAME_tag}" == "no" ]]; then
            stream_id_data="${stream_id_data},${channel_name}"
          fi

          if [[ "${DO_SKIP}" == "NO" ]]; then
            ((CHANNELCountWritten++))
            ((CHANNELCountWrittenTotal++))
            ((CHANNELCountWrittenTemp++))
            ((CHANNELCountWrittenTotalTemp++))
            echo "${stream_id_data}" >> ${DIR_playlist}stb${STB_number[${STB_Count}]}_playlist.m3u
            echo "http://${STB_ip[${STB_Count}]}:${STB_port[${STB_Count}]}/${stream_address}" >> ${DIR_playlist}stb${STB_number[${STB_Count}]}_playlist.m3u
          else
            if [[ "${FEEDBACK}" == "PRINT" ]] || [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
              echo "Channel ${CHANNELCount} was skipped: Reason N/A"
            fi
            if [[ "${LOGGING}" == "TRUE" ]]; then
              echo "Channel ${CHANNELCount} was skipped: Reason N/A" >> ${DIR_log}${LOGFILE}
            fi
            DO_SKIP="NO"
          fi

        ;;
 
      esac

    done <${DIR_bouquets}stb${STB_number[${STB_Count}]}_bouquet_${TMP_Bouquets_Count}_channel_listing.xml

    if [[ "${FEEDBACK}" == "PRINT" ]] || [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
      echo "${CHANNELCountWrittenTemp} of ${CHANNELCountTemp} channels written to play list from bouquet \"${DO_Bouquets}\""
      echo ""
    fi
    if [[ "${LOGGING}" == "TRUE" ]]; then
      echo "${CHANNELCountWrittenTemp} of ${CHANNELCountTemp} channels written to play list from bouquet \"${DO_Bouquets}\"" >> ${DIR_log}${LOGFILE}
      echo "" >> ${DIR_log}${LOGFILE}
    fi

  done

  if [[ ${TMP_Bouquets_Count} -gt 1 ]]; then
    if [[ "${FEEDBACK}" == "PRINT" ]] || [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
      echo "${CHANNELCountWrittenTotalTemp} of ${CHANNELCountTotalTemp} channels to play list written from all bouquets"
      echo ""
    fi
    if [[ "${LOGGING}" == "TRUE" ]]; then
      echo "${CHANNELCountWrittenTotalTemp} of ${CHANNELCountTotalTemp} channels to play list written from all bouquets" >> ${DIR_log}${LOGFILE}
      echo "" >> ${DIR_log}${LOGFILE}
    fi
  fi

}

Download_EPG ()
{
  #######################################################################################################################
  #
  # Download EPG from STB
  #
  #######################################################################################################################

  if [[ "${FEEDBACK}" == "PRINT" ]] || [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
    echo ""
    echo "=========================================================================="
    echo ""
    echo "Downloading EPG for STB"
    echo ""
    echo "--------------------------------------------------------------------------"
    echo ""
  fi
  if [[ "${LOGGING}" == "TRUE" ]]; then
    echo "" >> ${DIR_log}${LOGFILE}
    echo "==========================================================================" >> ${DIR_log}${LOGFILE}
    echo "" >> ${DIR_log}${LOGFILE}
    echo "Downloading EPG for STB" >> ${DIR_log}${LOGFILE}
    echo "" >> ${DIR_log}${LOGFILE}
    echo "--------------------------------------------------------------------------" >> ${DIR_log}${LOGFILE}
    echo "" >> ${DIR_log}${LOGFILE}
  fi

  TMP_Bouquets_Count=0

  if [[ $Channel_number_continuous == "no" ]]; then
    EPGDownloadCount=0
    EPGDownloadCountWritten=0
  fi

  ${BIN_dir_rm}rm ${DIR_tmp}stb${STB_number[${STB_Count}]}_epg_channel_*.tmp*

  for DO_Bouquets in ${STB_bouquet[${STB_Count}]}
  do
    ((TMP_Bouquets_Count++))
    EPGDownloadCountTemp=0
    EPGDownloadCountWrittenTemp=0
    DO_SKIP="NO"

    while read channel_line; do

      if [[ $channel_line == *${TAG_e2service_start}* ]]; then
        TAG_type=${TAG_e2service_start}
      fi
      if [[ $channel_line == *${TAG_e2servicereference_start}* ]]; then
        TAG_type=${TAG_e2servicereference_start}
      fi
        if [[ $channel_line == *${TAG_e2servicename_start}* ]]; then
        TAG_type=${TAG_e2servicename_start}
      fi
      if [[ $channel_line == *${TAG_e2service_end}* ]]; then
        TAG_type=${TAG_e2service_end}
      fi
      if [[ $channel_line == *${TAG_e2servicelist_end}* ]]; then
        TAG_type=${TAG_e2servicelist_end}
      fi
      if [[ $channel_line == *"&lt;n/a&gt;"* ]]; then
        DO_SKIP="YES"
      fi

      case "${TAG_type}" in
        ${TAG_e2service_start})
          ((EPGDownloadCount++))
          ((EPGDownloadCountTemp++))
          ((EPGDownloadCountTotal++))
        ;;
        ${TAG_e2servicereference_start})
          Line_tmp="${channel_line#*$TAG_e2servicereference_start}"
          stream_address="${Line_tmp%$TAG_e2servicereference_end*}"
        ;;
        ${TAG_e2servicename_start})
          Line_tmp="${channel_line#*$TAG_e2servicename_start}"
          channel_name="${Line_tmp%$TAG_e2servicename_end*}"
        ;;
        ${TAG_e2service_end})
          if [[ "${DO_SKIP}" == "NO" ]]; then
            if [[ "${FEEDBACK}" == "PRINT" ]] || [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
              echo -e "Download EPG for channel (${EPGDownloadCount}) \"${channel_name}\""
            fi
            if [[ "${LOGGING}" == "TRUE" ]]; then
              echo -e "Download EPG for channel (${EPGDownloadCount}) \"${channel_name}\"" >> ${DIR_log}${LOGFILE}
            fi
            ((EPGDownloadCountWritten++))
            ((EPGDownloadCountWrittenTemp++))
            ((EPGDownloadCountWrittenTotal++))
            echo -e "${channel_name}" > ${DIR_tmp}stb${STB_number[${STB_Count}]}_epg_channel_${EPGDownloadCount}.tmpx
            if [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
              ${BIN_dir_wget}wget http://${STB_ip[${STB_Count}]}/web/epgservice?sRef=${stream_address} -O ${DIR_tmp}stb${STB_number[${STB_Count}]}_epg_channel_${EPGDownloadCount}.tmp 
            else
              ${BIN_dir_wget}wget http://${STB_ip[${STB_Count}]}/web/epgservice?sRef=${stream_address} -q -O ${DIR_tmp}stb${STB_number[${STB_Count}]}_epg_channel_${EPGDownloadCount}.tmp
            fi
            echo -e "${channel_name}" > ${DIR_tmp}stb${STB_number[${STB_Count}]}_epg_channel_${EPGDownloadCount}.tmpx
          else
            if [[ "${FEEDBACK}" == "PRINT" ]] || [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
              echo "Channel ${EPGDownloadCount} was skipped: Reason N/A"
            fi
            if [[ "${LOGGING}" == "TRUE" ]]; then
              echo "Channel ${EPGDownloadCount} was skipped: Reason N/A" >> ${DIR_log}${LOGFILE}
            fi
            DO_SKIP="NO"
          fi
        ;;
      esac

    done <${DIR_bouquets}stb${STB_number[${STB_Count}]}_bouquet_${TMP_Bouquets_Count}_channel_listing.xml

    if [[ "${FEEDBACK}" == "PRINT" ]] || [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
      echo ""
      echo "EPG for ${EPGDownloadCountWrittenTemp} of ${EPGDownloadCountTemp} channels in bouquet \"${DO_Bouquets}\" downloaded"
      echo ""
    fi
    if [[ "${LOGGING}" == "TRUE" ]]; then
      echo "" >> ${DIR_log}${LOGFILE}
      echo "EPG for ${EPGDownloadCountWrittenTemp} of ${EPGDownloadCountTemp} channels in bouquet \"${DO_Bouquets}\" downloaded" >> ${DIR_log}${LOGFILE}
      echo "" >> ${DIR_log}${LOGFILE}
    fi

  done

  if [[ ${TMP_Bouquets_Count} -gt 1 ]]; then
    if [[ "${FEEDBACK}" == "PRINT" ]] || [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
      echo "EPG for ${EPGDownloadCountWrittenTotal} of ${EPGDownloadCountTotal} channels downloaded"
      echo ""
    fi
    if [[ "${LOGGING}" == "TRUE" ]]; then
      echo "EPG for ${EPGDownloadCountWrittenTotal} of ${EPGDownloadCountTotal} channels downloaded" >> ${DIR_log}${LOGFILE}
      echo "" >> ${DIR_log}${LOGFILE}
    fi
  fi

}


Write_EPG_Channel_headers ()
{
  #######################################################################################################################
  #
  # Writing channel header to XMLTV file
  #
  #######################################################################################################################

  if [[ "${FEEDBACK}" == "PRINT" ]] || [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
    echo ""
    echo "--------------------------------------------------------------------------"
    echo ""
    echo "Writing channel headers to XMLTV file"
    echo ""
    echo "--------------------------------------------------------------------------"
    echo ""
  fi
  if [[ "${LOGGING}" == "TRUE" ]]; then
    echo "" >> ${DIR_log}${LOGFILE}
    echo "--------------------------------------------------------------------------" >> ${DIR_log}${LOGFILE}
    echo "" >> ${DIR_log}${LOGFILE}
    echo "Writing channel headers to XMLTV file" >> ${DIR_log}${LOGFILE}
    echo "" >> ${DIR_log}${LOGFILE}
    echo "--------------------------------------------------------------------------" >> ${DIR_log}${LOGFILE}
    echo "" >> ${DIR_log}${LOGFILE}
  fi

  echo "<?xml version=\"1.0\" encoding=\"${Character_set}\"?>" > "${DIR_epg}stb${STB_number[${STB_Count}]}_xmltv.xml"
  echo "<!DOCTYPE tv SYSTEM \"xmltv.dtd\">" >> "${DIR_epg}stb${STB_number[${STB_Count}]}_xmltv.xml"
#  echo "<tv source-info-url=\"http://www.schedulesdirect.org/\" source-info-name=\"Schedules Direct\" generator-info-name=\"XMLTV/$Id: tv_grab_na_dd.in,v 1.70 2008/03/03 15:21:41 rmeden Exp $\" generator-info-url=\"http://www.xmltv.org/\">" >> "${DIR_epg}stb${STB_number[${STB_Count}]}_xmltv.xml"
  echo "<tv generator-info-name=\"bash_script\">" >> "${DIR_epg}stb${STB_number[${STB_Count}]}_xmltv.xml"

  TMP_Bouquets_Count=0

  if [[ $Channel_number_continuous == "no" ]]; then
    HEADChannelsCount=0
    HEADChannelsCountWritten=0
    HEADChannelsCountTotal=0
  fi

  for DO_Bouquets in ${STB_bouquet[${STB_Count}]}
  do
    ((TMP_Bouquets_Count++))
    HEADChannelsCountTemp=0
    HEADChannelsCountWrittenTemp=0
    DO_SKIP="NO"

    while read channel_line; do

      if [[ $channel_line == *${TAG_e2service_start}* ]]; then
        TAG_type=${TAG_e2service_start}
      fi
      if [[ $channel_line == *${TAG_e2servicereference_start}* ]]; then
        TAG_type=${TAG_e2servicereference_start}
      fi
        if [[ $channel_line == *${TAG_e2servicename_start}* ]]; then
        TAG_type=${TAG_e2servicename_start}
      fi
      if [[ $channel_line == *${TAG_e2service_end}* ]]; then
        TAG_type=${TAG_e2service_end}
      fi
      if [[ $channel_line == *${TAG_e2servicelist_end}* ]]; then
        TAG_type=${TAG_e2servicelist_end}
      fi
      if [[ $channel_line == *"&lt;n/a&gt;"* ]]; then
        DO_SKIP="YES"
      fi

      case "${TAG_type}" in
        ${TAG_e2service_start})
          ((HEADChannelsCount++))
          ((HEADChannelsCountTotal++))
          ((HEADChannelsCountTemp++))
        ;;
        ${TAG_e2servicereference_start})
          Line_tmp="${channel_line#*$TAG_e2servicereference_start}"
          stream_address="${Line_tmp%$TAG_e2servicereference_end*}"
        ;;
        ${TAG_e2servicename_start})
          Line_tmp="${channel_line#*$TAG_e2servicename_start}"
          channel_name="${Line_tmp%$TAG_e2servicename_end*}"
        ;;
        ${TAG_e2service_end})
          if [[ "${DO_SKIP}" == "NO" ]]; then
            ((HEADChannelsCountWritten++))
            ((HEADChannelsCountWrittenTotal++))
            ((HEADChannelsCountWrittenTemp++))
            ((HEADChannelsCountWrittenTotalTemp++))
            echo "  <channel id=\"${channel_name}\">" >> "${DIR_epg}stb${STB_number[${STB_Count}]}_xmltv.xml"
            if [[ "${HEADER_channel_name}" == "yes" ]]; then
              echo "    <display-name>${channel_name}</display-name>" >> "${DIR_epg}stb${STB_number[${STB_Count}]}_xmltv.xml"
            fi
            if [[ "${HEADER_channel_number}" == "yes" ]]; then
              echo "    <display-name>${HEADChannelsCount}</display-name>" >> "${DIR_epg}stb${STB_number[${STB_Count}]}_xmltv.xml"
            fi
            if [[ "${HEADER_channel_number_name}" == "yes" ]]; then
              echo "    <display-name>${HEADChannelsCount} ${channel_name}</display-name>" >> "${DIR_epg}stb${STB_number[${STB_Count}]}_xmltv.xml"
            fi
            echo "  </channel>" >> "${DIR_epg}stb${STB_number[${STB_Count}]}_xmltv.xml"
          else
            DO_SKIP="NO"
          fi
        ;;
      esac

    done <${DIR_bouquets}stb${STB_number[${STB_Count}]}_bouquet_${TMP_Bouquets_Count}_channel_listing.xml

    if [[ "${FEEDBACK}" == "PRINT" ]] || [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
      echo "Channel headers for ${HEADChannelsCountWrittenTemp} of ${HEADChannelsCountTemp} channels from bouquet \"${DO_Bouquets}\" written"
    fi
    if [[ "${LOGGING}" == "TRUE" ]]; then
      echo "Channel headers for ${HEADChannelsCountWrittenTemp} of ${HEADChannelsCountTemp} channels from bouquet \"${DO_Bouquets}\" written" >> ${DIR_log}${LOGFILE}
    fi

  done

  if [[ ${TMP_Bouquets_Count} -gt 1 ]]; then
    if [[ "${FEEDBACK}" == "PRINT" ]] || [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
      echo ""
      echo "Channel headers for ${HEADChannelsCountWrittenTotal} of ${HEADChannelsCountTotal} channels written"
      echo ""
    fi
    if [[ "${LOGGING}" == "TRUE" ]]; then
      echo "" >> ${DIR_log}${LOGFILE}
      echo "Channel headers for ${HEADChannelsCountWrittenTotal} of ${HEADChannelsCountTotal} channels written" >> ${DIR_log}${LOGFILE}
      echo "" >> ${DIR_log}${LOGFILE}
    fi
  else
    if [[ "${FEEDBACK}" == "PRINT" ]] || [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
      echo ""
      echo ""
    fi
    if [[ "${LOGGING}" == "TRUE" ]]; then
      echo "" >> ${DIR_log}${LOGFILE}
      echo "" >> ${DIR_log}${LOGFILE}
    fi

  fi

}


Write_EPG_Program_data ()
{
  #######################################################################################################################
  #
  # Creating EPG
  #
  #######################################################################################################################

  if [[ "${FEEDBACK}" == "PRINT" ]] || [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
    echo ""
    echo "--------------------------------------------------------------------------"
    echo ""
    echo "Writing EPG data to XMLTV file"
    echo ""
    echo "--------------------------------------------------------------------------"
    echo ""
  fi
  if [[ "${LOGGING}" == "TRUE" ]]; then
    echo "" >> ${DIR_log}${LOGFILE}
    echo "--------------------------------------------------------------------------" >> ${DIR_log}${LOGFILE}
    echo "" >> ${DIR_log}${LOGFILE}
    echo "Writing EPG data to XMLTV file" >> ${DIR_log}${LOGFILE}
    echo "" >> ${DIR_log}${LOGFILE}
    echo "--------------------------------------------------------------------------" >> ${DIR_log}${LOGFILE}
    echo "" >> ${DIR_log}${LOGFILE}
  fi
  TMPCount=0
  EPGCount_total=0
  while [[ ${TMPCount} -lt ${HEADChannelsCountTotal} ]]; do
    ((TMPCount++))
    while [[ ! -f "${DIR_tmp}stb${STB_number[${STB_Count}]}_epg_channel_${TMPCount}.tmp" ]] && [[ ${TMPCount} -lt ${HEADChannelsCountTotal} ]]; do
      ((TMPCount++))
    done
    while read epg_line; do

      #######################################################################################################################
      #
      # Creating programs
      #

#echo "epg_line: --- $epg_line ---"

      if [[ $epg_line == *${TAG_e2eventlist_start}* ]]; then
        TAG_type=${TAG_e2eventlist_start}
      fi
      if [[ $epg_line == *${TAG_e2event_start}* ]]; then
        TAG_type=${TAG_e2event_start}
      fi
      if [[ $epg_line == *${TAG_e2servicereference_start}* ]]; then
        TAG_type=${TAG_e2servicereference_start}
      fi
      if [[ $epg_line == *${TAG_e2eventid_start}* ]]; then
        TAG_type=${TAG_e2eventid_start}
      fi
      if [[ $epg_line == *${TAG_e2eventstart_start}* ]]; then
        TAG_type=${TAG_e2eventstart_start}
      fi
      if [[ $epg_line == *${TAG_e2eventduration_start}* ]]; then
        TAG_type=${TAG_e2eventduration_start}
      fi
      if [[ $epg_line == *${TAG_e2eventcurrenttime_start}* ]]; then
        TAG_type=${TAG_e2eventcurrenttime_start}
      fi
      if [[ $epg_line == *${TAG_e2eventtitle_start}* ]]; then
        TAG_type=${TAG_e2eventtitle_start}
      fi
      if [[ $epg_line == *${TAG_e2eventdescription_start}* ]]; then
        TAG_type=${TAG_e2eventdescription_start}
      fi
      if [[ $epg_line == *${TAG_e2eventdescriptionextended_start}* ]]; then
        TAG_type=${TAG_e2eventdescriptionextended_start}
      fi
      if [[ $epg_line == *${TAG_e2eventservicereference_start}* ]]; then
        TAG_type=${TAG_e2eventservicereference_start}
      fi
      if [[ $epg_line == *${TAG_e2eventservicename_start}* ]]; then
        TAG_type=${TAG_e2eventservicename_start}
      fi
      if [[ $epg_line == *${TAG_e2eventgenre_start}* ]]; then
        TAG_type=${TAG_e2eventgenre_start}
      fi

      if [[ $epg_line == *${TAG_e2event_end}* ]]; then
        TAG_type=${TAG_e2event_end}
      fi

      if [[ $epg_line == *${TAG_e2eventlist_end}* ]]; then
        TAG_type=${TAG_e2eventlist_end}
      fi

      case "${TAG_type}" in
        ${TAG_e2eventlist_start})
          EPGCount_channel=0
        ;;
        ${TAG_e2event_start})
          ((EPGCount_total++))
          ((EPGCount_channel++))
        ;;
        ${TAG_e2eventid_start})
          Line_tmp="${epg_line#*$TAG_e2eventid_start}"
          e2eventid="${Line_tmp%$TAG_e2eventid_end*}"
        ;;
        ${TAG_e2eventstart_start})
          Line_tmp="${epg_line#*$TAG_e2eventstart_start}"
          e2eventstart="${Line_tmp%$TAG_e2eventstart_end*}"
        ;;
        ${TAG_e2eventduration_start})
          Line_tmp="${epg_line#*$TAG_e2eventduration_start}"
          e2eventduration="${Line_tmp%$TAG_e2eventduration_end*}"
        ;;
        ${TAG_e2eventcurrenttime_start})
          Line_tmp="${epg_line#*$TAG_e2eventcurrenttime_start}"
          e2eventcurrenttime="${Line_tmp%$TAG_e2eventcurrenttime_end*}"
        ;;
        ${TAG_e2eventtitle_start})
          Line_tmp="${epg_line#*$TAG_e2eventtitle_start}"
          e2eventtitle="${Line_tmp%$TAG_e2eventtitle_end*}"
        ;;
        ${TAG_e2eventdescription_start})
          Line_tmp="${epg_line#*$TAG_e2eventdescription_start}"
          e2eventdescription="${Line_tmp%$TAG_e2eventdescription_end*}"
        ;;
        ${TAG_e2eventdescriptionextended_start})
          Line_tmp="${epg_line#*$TAG_e2eventdescriptionextended_start}"
          e2eventdescriptionextended="${Line_tmp%$TAG_e2eventdescriptionextended_end*}"
        ;;
        ${TAG_e2eventservicereference_start})
          Line_tmp="${epg_line#*$TAG_e2eventservicereference_start}"
          e2eventservicereference="${Line_tmp%$TAG_e2eventservicereference_end*}"
        ;;
        ${TAG_e2eventservicename_start})
          Line_tmp="${epg_line#*$TAG_e2eventservicename_start}"
          e2eventservicename="${Line_tmp%$TAG_e2eventservicename_end*}"
        ;;
        ${TAG_e2eventgenre_start})
          Line_tmp="${epg_line#*$TAG_e2eventgenre_start}"
          Line_tmp="${Line_tmp%$TAG_e2eventgenre_end*}"
          Line_tmp="${Line_tmp#*$EPG_genre_num_start}"
          e2eventgenre_NUM="${Line_tmp%$EPG_genre_num_text_split*}"
          e2eventgenre_TXT="${Line_tmp#*$EPG_genre_num_text_split}"
        ;;

        ${TAG_e2event_end})
          EPG_Start_time="`date -d@${e2eventstart} -u +\"%Y%m%d%H%M%S\"`"
          e2eventend=$((e2eventstart + e2eventduration ))
          EPG_End_time="`date -d@${e2eventend} -u +\"%Y%m%d%H%M%S\"`"
          episode_tag="FALSE"
          season_tag="FALSE"
          episode_total_tag="FALSE"
          if [[ "${e2eventdescription}" == *"${EPG_episode_start_tag}"* ]]; then
            episode_tag="TRUE"
            episode_tmp="${e2eventdescription#*$EPG_episode_start_tag}"
            episode_tmp="${episode_tmp%%$EPG_episode_end_tag*}"
            episode_tmp=${episode_tmp//[[:blank:]]/}
            if [[ "${episode_tmp}" == *"${EPG_season_split_tag}"* ]]; then
              season_tag="TRUE"
              season=${episode_tmp#*$EPG_season_split_tag}
              episode_tmp="${episode_tmp%$EPG_season_split_tag*}"
            fi
            if [[ "${episode_tmp}" == *"${EPG_episode_split_tag}"* ]]; then
              episode_total_tag="TRUE"
              episode_tot=${episode_tmp#*$EPG_episode_split_tag}
              episode_num="${episode_tmp%$EPG_episode_split_tag*}"
            fi
            if [[ "${episode_total_tag}" == "FALSE" ]]; then
              episode_num="${episode_tmp}"
            fi
            xmltv_ns="<episode-num system=\"xmltv_ns\">"
            ((xmltv_ns_season=season-1))
            if [[ "${season_tag}" == "TRUE" ]]; then
              xmltv_ns="${xmltv_ns}${xmltv_ns_season} . "
            else
              xmltv_ns="${xmltv_ns} . "
            fi
            ((xmltv_ns_episode_num=episode_num-1))
            if [[ "${episode_total_tag}" == "TRUE" ]]; then
              xmltv_ns="${xmltv_ns}${xmltv_ns_episode_num}/${episode_tot} . 0/1</episode-num>"
            else
              xmltv_ns="${xmltv_ns}${xmltv_ns_episode_num} . 0/1</episode-num>"
            fi
          fi
          if [[ "${e2eventtitle}" == *"${EPG_previously_shown_tag}"* ]]; then
            PREVIOUSLY_SHOWN="YES"
          fi
          if [[ "${e2eventdescription}" == *"${EPG_previously_shown_tag}"* ]]; then
            PREVIOUSLY_SHOWN="YES"
          fi
          if [[ "${e2eventdescriptionextended}" == *"${EPG_previously_shown_tag}"* ]]; then
            PREVIOUSLY_SHOWN="YES"
          fi

          echo -e "  <programme start=\"${EPG_Start_time} ${UTC_offset}\" stop=\"${EPG_End_time} ${UTC_offset}\" channel=\"${e2eventservicename}\">" >> "${DIR_epg}stb${STB_number[${STB_Count}]}_xmltv.xml"
          echo -e "    <title lang=\"no\">${e2eventtitle}</title>" >> "${DIR_epg}stb${STB_number[${STB_Count}]}_xmltv.xml"
          if [[ ${#e2eventdescription} -gt 0 ]]; then
#            echo -e "    <sub-title lang=\"no\">${e2eventdescription}</sub-title>" >> "${DIR_epg}stb${STB_number[${STB_Count}]}_xmltv.xml"
            echo -e "    <desc lang=\"no\">${e2eventdescription}</desc>" >> "${DIR_epg}stb${STB_number[${STB_Count}]}_xmltv.xml"
          fi
          if [[ ${#e2eventdescriptionextended} -gt 0 ]]; then
            echo -e "    <desc lang=\"no\">${e2eventdescriptionextended}</desc>" >> "${DIR_epg}stb${STB_number[${STB_Count}]}_xmltv.xml"
          fi
          if [[ ${#e2eventgenre_TXT} -gt 0 ]]; then
            if [[ "${EPG_genre_write_full_string}" == "yes" ]]; then
              echo -e "    <category lang=\"no\">${e2eventgenre_TXT}</category>" >> "${DIR_epg}stb${STB_number[${STB_Count}]}_xmltv.xml"
            fi
            if [[ "${EPG_genre_write_split_string}" == "yes" ]]; then
              Line_tmp="${e2eventgenre_TXT%$EPG_genre_main_split*}"
              while [[ "${Line_tmp}" == *"${EPG_genre_sub_split}"* ]]; do
                Genre_tmp=${Line_tmp%%$EPG_genre_sub_split*}
                if [[ "${EPG_genre_upper_case_first_letter}" == "yes" ]]; then
                  Genre_tmp="${Genre_tmp^}"
                fi
                echo -e "    <category lang=\"no\">${Genre_tmp}</category>" >> "${DIR_epg}stb${STB_number[${STB_Count}]}_xmltv.xml"
                Line_tmp="${Line_tmp#*$EPG_genre_sub_split}"
              done
			  if [[ ! "${Line_tmp}" == "..." ]]; then
                if [[ "${EPG_genre_upper_case_first_letter}" == "yes" ]]; then
                  Line_tmp="${Line_tmp^}"
                fi
                echo -e "    <category lang=\"no\">${Line_tmp}</category>" >> "${DIR_epg}stb${STB_number[${STB_Count}]}_xmltv.xml"
              fi
              Line_tmp="${e2eventgenre_TXT#*$EPG_genre_main_split}"
              while [[ "${Line_tmp}" == *"${EPG_genre_sub_split}"* ]]; do
                Genre_tmp=${Line_tmp%%$EPG_genre_sub_split*}
                if [[ "${EPG_genre_upper_case_first_letter}" == "yes" ]]; then
                  Genre_tmp="${Genre_tmp^}"
                fi
                echo -e "    <category lang=\"no\">${Genre_tmp}</category>" >> "${DIR_epg}stb${STB_number[${STB_Count}]}_xmltv.xml"
                Line_tmp="${Line_tmp#*$EPG_genre_sub_split}"
              done
			  if [[ ! "${Line_tmp}" == "..." ]]; then
                if [[ "${EPG_genre_upper_case_first_letter}" == "yes" ]]; then
                  Line_tmp="${Line_tmp^}"
                fi
                echo -e "    <category lang=\"no\">${Line_tmp}</category>" >> "${DIR_epg}stb${STB_number[${STB_Count}]}_xmltv.xml"
              fi
            fi
            if [[ "${EPG_genre_write_number}" == "yes" ]]; then
              echo -e "    <category lang=\"no\">${e2eventgenre_NUM}</category>" >> "${DIR_epg}stb${STB_number[${STB_Count}]}_xmltv.xml"
            fi
          fi
          if [[ "${episode_tag}" == "TRUE" ]]; then 
            echo -e "    <episode-num system=\"onscreen\">${episode_num}</episode-num>" >> "${DIR_epg}stb${STB_number[${STB_Count}]}_xmltv.xml"
            echo -e "    ${xmltv_ns}"  >> "${DIR_epg}stb${STB_number[${STB_Count}]}_xmltv.xml"
          fi
          if [[ "${PREVIOUSLY_SHOWN}" == "YES" ]]; then
            echo -e "    <previously-shown />"  >> "${DIR_epg}stb${STB_number[${STB_Count}]}_xmltv.xml"
            PREVIOUSLY_SHOWN="NO"
          fi
          echo -e "  </programme>" >> "${DIR_epg}stb${STB_number[${STB_Count}]}_xmltv.xml"
        ;;
      esac
    done <${DIR_tmp}stb${STB_number[${STB_Count}]}_epg_channel_${TMPCount}.tmp

    if [[ "${FEEDBACK}" == "PRINT" ]] || [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
      if [[ ${EPGCount_channel} -gt 0 ]]; then
        echo "Writing EPG for channel ${TMPCount} - ${e2eventservicename} finished (${EPGCount_channel} programs)"
      else
        while read e2eventservicename; do
          echo "OPS! No EPG for channel ${TMPCount} - ${e2eventservicename} (EPG missing on STB)"
        done<${DIR_tmp}stb${STB_number[${STB_Count}]}_epg_channel_${TMPCount}.tmpx
      fi
    fi
    if [[ "${LOGGING}" == "TRUE" ]]; then
      if [[ ${EPGCount_channel} -gt 0 ]]; then
        echo "Writing EPG for channel ${TMPCount} - ${e2eventservicename} finished (${EPGCount_channel} programs)" >> ${DIR_log}${LOGFILE}
      else
        while read e2eventservicename; do
          echo "OPS! No EPG for channel ${TMPCount} - ${e2eventservicename} (EPG missing on STB)" >> ${DIR_log}${LOGFILE}
        done<${DIR_tmp}stb${STB_number[${STB_Count}]}_epg_channel_${TMPCount}.tmpx
      fi
    fi

    if [[ "${DEL_tmp_files}" == "yes" ]]; then
      ${BIN_dir_rm}rm ${DIR_tmp}stb${STB_number[${STB_Count}]}_epg_channel_${TMPCount}.tmp*
    fi

  done
  echo -e "</tv>" >> "${DIR_epg}stb${STB_number[${STB_Count}]}_xmltv.xml"
  if [[ "${FEEDBACK}" == "PRINT" ]] || [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
    echo ""
    echo "EPG for STB ${STB_Count} finished (${EPGCount_total} programs total)"
  fi
  if [[ "${LOGGING}" == "TRUE" ]]; then
    echo "" >> ${DIR_log}${LOGFILE}
    echo "EPG for STB ${STB_Count} finished (${EPGCount_total} programs total)" >> ${DIR_log}${LOGFILE}
  fi

}



#######################################################################################################################
# 
# Pre work
#
#######################################################################################################################

Read_Config
Create_Directories 
Display_Config_data

#######################################################################################################################
# 
# The real work start here - One run for each STB
#
#######################################################################################################################

STB_Count=1
while [[ ${STB_Count} -le ${STB_maks} ]]; do
  if [[ "${FEEDBACK}" == "PRINT" ]] || [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
    echo ""
    echo ""
    echo "**************************************************************************"
    echo "*"
    echo "*   Working with STB ${STB_number[${STB_Count}]}: "
    echo "*"
    echo "**************************************************************************"
    echo ""
  fi
  if [[ "${LOGGING}" == "TRUE" ]]; then
    echo "" >> ${DIR_log}${LOGFILE}
    echo "" >> ${DIR_log}${LOGFILE}
    echo "**************************************************************************" >> ${DIR_log}${LOGFILE}
    echo "*" >> ${DIR_log}${LOGFILE}
    echo "*   Working with STB ${STB_number[${STB_Count}]}: " >> ${DIR_log}${LOGFILE}
    echo "*" >> ${DIR_log}${LOGFILE}
    echo "**************************************************************************" >> ${DIR_log}${LOGFILE}
    echo "" >> ${DIR_log}${LOGFILE}
  fi
  #######################################################################################################################
  # 
  # Download and writing bouquets and channellist to M3U file.
  #
  #######################################################################################################################

  if [[ "${GET_ALL}" == "TRUE" ]]; then
    Bouquets_Count=0
    Download_Bouquets_List
    sleep 1
    Get_Bouquets_Addresses
    Download_Channel_Lists
    Write_m3u_Playlist
  fi
  
  
  
  #######################################################################################################################
  # 
  # Download and writing EPG to XMLTV file. If STB info for EPG is set to "no" then it skip EPG for this STB. 
  # If script is runned with parameter EPG_ALL it overides settings from config file (downloads EPG from all STB's).
  #
  #######################################################################################################################

  if [[ "${STB_epg[${STB_Count}]}" == "yes" ]]; then
    Download_EPG
    Write_EPG_Channel_headers
    Write_EPG_Program_data
  else
    if [[ "${FEEDBACK}" == "PRINT" ]] || [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
      echo "EPG for STB ${STB_Count} skipped"
    fi
    if [[ "${LOGGING}" == "TRUE" ]]; then
      echo "EPG for STB ${STB_Count} skipped" >> ${DIR_log}${LOGFILE}
    fi
  fi
  ((STB_Count++))

done

if [[ "${FEEDBACK}" == "PRINT" ]] || [[ "${FEEDBACK}" == "PRINT_ALL" ]]; then
  echo ""
  echo ""
  echo "Started:  ${START_TIME}"
  echo "Fished:   `date +"%Y.%m.%d %H:%M:%S"`"
  echo ""
fi

if [[ "${LOGGING}" == "TRUE" ]]; then
  echo "" >> ${DIR_log}${LOGFILE}
  echo "" >> ${DIR_log}${LOGFILE}
  echo "Started:  ${START_TIME}" >> ${DIR_log}${LOGFILE}
  echo "Fished:   `date +"%Y.%m.%d %H:%M:%S"`" >> ${DIR_log}${LOGFILE}
  echo "" >> ${DIR_log}${LOGFILE}
fi

