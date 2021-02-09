#!/bin/bash
####################################################
#                                                  #
# Auth: jean-christophe.iacono@1001pharmacies.com  #
#                                                  #
#  img-compressr.sh                                #
#                                                  #
#  Usage: img-compressr.sh <options>               #
#                                                  #
# This script compresses images in target folders  #
#   and subfolders using ImageMagick.              #
#                                                  #
#                                                  #
# Version: 0.4                                     #
#                                                  #
####################################################
#
#
### Documentation used
# - ImageMagick install : https://imagemagick.org/script/install-source.php
# OR apt install. (because manual install means manual plugin management)
#
# - PageSpeed Insights : https://developers.google.com/speed/docs/insights/OptimizeImages
#
### Notes
#
# The purpose of this script is to compress images in a list of folders
# with potential subfolders.
#
# - Script can handle spaces in files or folders names
#
# - imagemagick : target and destination files can be the same, this will overwrite file
#   with compressed version
#
#
#
### TODO
#
#  - Catch and manage error codes
#  - Set customizable (maxdepth) recursivity
#  - Log path as a variable
#
#
#


PATH=${PATH:-/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/bin}

# imagemagick convert binary
convert=convert


lastrun_marker=compression_marker
original_ext=uncompressedbak
convert_args_jpg="-sampling-factor 4:2:0 -strip -quality 85 -interlace JPEG -colorspace RGB"
convert_args_png="-strip -define png:compression-filter=0 -define png:compression-level=9 -define png:compression-strategy=1"

report="/tmp/img_compression_report.log"
current_time="$(date +"%Y-%m-%d_%H-%M-%S")"

RED="\033[31m"
GREEN="\033[32m"
BLUE="\033[96m"
YELLOW="\033[93m"
BRIGHTGREEN="\033[32m\033[1m"
BRIGHTBLUE="\033[36m\033[1m"
COLOR_RESET="\033[0m"


if ! [ -x "$(command -v $convert)" ] ; then
    echo "Imagemagick convert ($convert) is required to execute this script" >> $report
    exit 1
fi

function show_help(){
    printf "Script usage :\n"
    printf "\t-b          : Backup, copy original images as <imagename>.$original_ext ;\n"
    printf "\t-c          : Clean backups, backup copies will be removed ;\n"
    printf "\t-f          : Force, ignore last compression timestamp. Will also overwrite backups if combined with -b ;\n"
    printf "\t-r          : Recursive, convert images recursively in folder and subfolders ;\n"
    printf "\t-u          : Undo, revert to original files (requires backup to be previously created) ;\n"
    printf "\t-v          : Verbose, display commands and files being compressed ;\n"
    printf "\t-y          : Yes, do not ask for confirmation to begin compression ;\n"
    printf "\n"
    printf "\t-h          : this screen.\n"
    printf "\n"
    printf "        Examples : $0 -vbr /some/directory \"/directory/with some/spaces\"\n"
    printf "                   $0 -ryu /some/directory \"/directory/with some/spaces\"\n"
    printf "                   $0 -cry /some/directory \"/directory/with some/spaces\"\n"
    printf "\n"
}



function user_confirmation() {
    if [ "$yes" -eq 0 ] ; then
        read -p "Are you sure you want to proceed ? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]] ; then
            echo "Operation aborted, no change on files" ; exit 0
        fi
    fi
}



function clean_backups() {
user_confirmation
echo ; echo -e "${BLUE}Cleaning backups...${COLOR_RESET}"

    for target_folder in "$@" ; do
        find "$target_folder" -type f -iname '*.$original_ext' -delete
    done

echo -e "${BLUE}Cleaning backups ${BRIGHTGREEN}OK${COLOR_RESET}"
exit 0
}


function image_error() {
    error_count=$((error_count+1))
    echo -e "${RED}Error${COLOR_RESET} on file ${YELLOW}$file${COLOR_RESET}, file is ${BLUE}not modified${COLOR_RESET}"
    echo "($1)"
    log_message "error" "$1"
    rm -f "$file.compressed"
    if [ $force -eq 0 ] ; then rm -f "$file.$original_ext" ; fi
}


function log_message() {
    echo "[$(date +"%Y/%m/%d-%H:%M:%S")] event=\"$1\" message=\"$2\"" >> $report    ### :
}


function bytes_to_human() {
    b=${1:-0}; d=''; s=0; S=(Bytes {K,M,G,T,P,E,Z,Y}B)
    while ((b > 1024)); do
        d="$(printf ".%02d" $((b % 1024 * 100 / 1024)))"
        b=$((b / 1024))
        let s++
    done
    echo "$b$d ${S[$s]}"
}



### Catching options ###

script_options="$@" # For logs
backup=0
do_clean_backups=0
force=0
recursive=0
undo=0
verbose=0
yes=0

if [ $# -eq 0 ] ; then # If 0 option
    echo "Some options are required" ; echo
    show_help ; exit 1
fi


while getopts "bcfruvyh" optName; do
    case "$optName" in
    b) backup=1 ; echo "Backup enabled. A copy of files will be created" ;;
    c) do_clean_backups=1 ; echo "Clean mode, backups in target folders will be removed" ;;
    f) force=1 ; echo "Force enabled. Last compression timestamp will be ignored"
        echo "Note that forcing compression will overwrite any existing backups with current version" ;;
    r) recursive=1 ; echo "Recursivity enabled. Subfolders will be treated" ;;
    u) undo=1 ; echo "Undo mode, original files for target folders will be restored if present" ;;
    v) verbose=1 ; echo "Verbose mode enabled" ;;
    y) yes=1 ; echo "Auto confirmation enabled" ;;
    h) show_help ; exit 0 ;;
    *) echo "Option $1 not recognized" ; show_help ; exit 1 ;;
    esac
done
shift "$((OPTIND -1))"

if [ -z "$1" ] ; then
    echo ; echo "You must specify at least one target directory"
    echo ; show_help ; exit 1
fi

if [ $backup -eq 1 ] && [ $undo -eq 1 ] ; then
    echo ; echo "You may not want to backup and undo at the same time"
    echo ; show_help ; exit 1
fi

if [ $do_clean_backups -eq 1 ] ; then
    clean_backups "$@"
fi




#############
### START ###
#############


# Report definition
start_time="$current_time"

#echo "[$(date +"%Y-%m-%d_%H-%M-%S")] Script started. Options: $script_options" >> $report
echo >> $report
echo >> $report
echo >> $report
#echo "[$current_time] event=\"info\" message=\"Script started. Options: $script_options\"" >> $report
log_message "info" "Script started."
log_message "info" "Script options : $script_options"
[ "$verbose" -eq 1 ] && echo && echo -e "${BLUE}Script started at : $(date)${COLOR_RESET}"

# Stats : init total
total_before=0
total_after=0
error_count=0
subfolders_count=0

### SUBFOLDERS DISCOVERY ###

# Create the subfolder list
echo ; echo -e "${BLUE}Listing affected subfolders...${COLOR_RESET}"

if [ $recursive -eq 0 ] ; then # target folders will be the actual folder list
    subfolders_list="$(find "$@" -maxdepth 0 -type d)"
else # recursive enabled, get subfolders
    subfolders_list="$(find "$@" -type d)"
fi

subfolders_total=$(echo "$subfolders_list" | wc -l)

# Display and confirm $subfolders_list
echo "$subfolders_list"
echo -e "${BLUE}Listing $subfolders_total subfolders ${BRIGHTGREEN}OK${COLOR_RESET}"; echo

user_confirmation



### BACKUP RESTORATION ###
if [ $undo -eq 1 ] ; then # Restore available backups
	restored_count=0
    echo ; echo -e "${BLUE}Restoring available backups in target subfolders...${COLOR_RESET}"

    while IFS="" read -r folder ; do
        subfolders_count=$(($subfolders_count+1))
        echo
        echo
        echo
        echo -e "${BRIGHTBLUE}*** Entering folder ${COLOR_RESET}${YELLOW}$folder ${COLOR_RESET} ${BLUE}($subfolders_count / $subfolders_total)${COLOR_RESET}"
        echo
        echo -e "${BLUE}Restoring files...${COLOR_RESET}"

            while IFS="" read -r file ; do
                if [ -z "$file" ] ; then # list is empty
                    echo -e "${BLUE}No new files to restore in this folder${COLOR_RESET}"
                else
                    mv "$file" "${file%.$original_ext}"
                    [ "$verbose" -eq 1 ] && echo -ne "${BLUE}folder $subfolders_count/$subfolders_total${COLOR_RESET} "
                    [ "$verbose" -eq 1 ] && echo -e "File ${YELLOW}${file%.$original_ext}${COLOR_RESET} ${BLUE}restored${COLOR_RESET}"
                    restored_count=$(($restored_count+1))
                fi
            done <<< "$(find "$folder" -maxdepth 1 -type f -iname "*.$original_ext")"

        if [ -f "$folder/$lastrun_marker" ] ; then
            echo -e "${BLUE}Removing compression marker${COLOR_RESET}" ; rm "$folder/$lastrun_marker"
        fi
    done <<< "$subfolders_list"

    echo ; echo -e "${BLUE}Cleaning backups ${BRIGHTGREEN}OK${COLOR_RESET}"
    echo -e "${BLUE}$restored_count files restored${COLOR_RESET}" ; echo
    log_message "info" "$restored_count files restored"
    log_message "info" "Script ended."
    exit 0
fi




### COMPRESSION ###
while IFS="" read -r folder ; do
    subfolders_count=$(($subfolders_count+1))
    echo
    echo
    echo
    echo -e "${BRIGHTBLUE}*** Entering folder ${COLOR_RESET}${YELLOW}$folder${COLOR_RESET} ${BLUE}($subfolders_count / $subfolders_total)${COLOR_RESET}"



    ### FILE LISTING ###
    echo ; echo -e "${BLUE}Listing files...${COLOR_RESET}"

    #  If marker present, use it, unless Force is used
    use_marker=0
    if [ $force -eq 0 ] ; then
        if [ -f "$folder/$lastrun_marker" ] ; then
           use_marker=1 ; [ "$verbose" -eq 1 ] && echo -e "${BLUE}Found marker from last compression, only compressing new files${COLOR_RESET}"
        else
            se_marker=0 ; [ "$verbose" -eq 1 ] && echo -e "${BLUE}No marker found, all files in this folder will be compressed${COLOR_RESET}"
        fi
    else
        use_marker=0 ; [ "$verbose" -eq 1 ] && echo -e "${BLUE}Force used, all files in this folder will be compressed${COLOR_RESET}"
    fi

    # Create files list
    #
    # (Duplicated command here, passing -newer with quotes would make find to not locate the marker)
    #
    if [ $use_marker -eq 0 ] ; then
#        newer_opt=""
#        newer_marker=""
        images_list="$(find "$folder" -maxdepth 1 -type f -iregex '.*\.\(jpe?g\|png\)')"

    else
#        newer_opt="-newer"
#        newer_marker="\"$folder/$lastrun_marker\""
        images_list="$(find "$folder" -maxdepth 1 -type f -newer "$folder/$lastrun_marker" -iregex '.*\.\(jpe?g\|png\)')"
    fi

    [ "$verbose" -eq 1 ] && echo -e "${BLUE}command : ${GREEN}find $folder -maxdepth 1 -type f $newer_opt $newer_marker -iregex \'.*\.\(jpe?g\|png\)\'${COLOR_RESET}"
#    images_list="$(find "$folder" -maxdepth 1 -type f $newer_opt $newer_marker -iregex '.*\.\(jpe?g\|png\)')"


    images_total=$(echo "$images_list" | wc -l)
    images_count=0




    ### FILE COMPRESSION ###
    [ "$verbose" -eq 1 ] && echo ; echo -e "${BLUE}Converting files...${COLOR_RESET}"
    [ "$verbose" -eq 1 ] && echo -e "${BLUE}command : ${GREEN}$convert $convert_args <src> <dst>${COLOR_RESET}"

    if [ -z "$images_list" ] ; then # list is empty
        echo -e "${BLUE}No new files to compress in this folder${COLOR_RESET}"
    else

        # Initialization of folder statistics
        folder_before=0
        folder_after=0

        while IFS="" read -r file ; do

            images_count=$(($images_count+1))


            # Stats before
            size_before=$(stat -c%s "$file")
            if [ "$size_before" -eq 0 ] ; then
                image_error "File $file has a size of 0" ; continue
            fi

            # Display count as output prefix
            [ "$verbose" -eq 1 ] && echo -ne "${BLUE}folder $subfolders_count/$subfolders_total ; image $images_count/$images_total)${COLOR_RESET} "

            file_type="$(file -b "$file" | awk '{print $1}')"
            if [ $file_type == "very" ] ; then file_type="very small or empty" ; fi

            case $file_type in
                [jJ][pP][gG] | [jJ][pP][eE][gG])
                    convert_args="$convert_args_jpg"  ;;
                [pP][nN][gG])
                    convert_args="$convert_args_png" ;;
                 *)
                    image_error "File $file has an unexpected filetype : $file_type" ; continue ;;
            esac

            $convert $convert_args "$file" "$file.compressed" 2>>$report

            if [ ! $? -eq 0 ] ; then
                image_error "Compression failed for $file" ; continue
            else

                # Stats
                size_after=$(stat -c%s "$file.compressed")
                variation=$(awk -v after="$size_after" -v before="$size_before" 'BEGIN {print int(((after*100)/before)-100)}')
                folder_before=$(( $folder_before + $size_before ))
                total_before=$(( $total_before + $size_before ))

                if [ "$variation" -ge 0 ] ; then
                    # No improvement, do not keep.
                    rm -f "$file.compressed"
                    if [ $force -eq 0 ] ; then rm -f "$file.$original_ext" ; fi

                    # Stats update
                    folder_after=$(( $folder_after + $size_before ))
                    total_after=$(( $total_after + $size_before ))

                    [ "$verbose" -eq 1 ] && echo -e "File ${YELLOW}$file${COLOR_RESET} would increase by $variation %, file is ${BLUE}not modified${COLOR_RESET}"
                else

                    # Create / overwrite backup (unless force used && backup already present)
                    if [ $backup -eq 1 ] ; then
                        if [ $force -eq 0 ] || [[ $force -eq 1 && ! -f "$file.$original_ext" ]] ; then
                            cp -a "$file" "$file.$original_ext"
                        fi
                    fi

                    # Replace
                    mv "$file.compressed" "$file"

                    #  Stats update
                    folder_after=$(( $folder_after + $size_after ))
                    total_after=$(( $total_after + $size_after ))

                    [ "$verbose" -eq 1 ] && echo -e "File ${YELLOW}$file${COLOR_RESET} ${GREEN}decreased${COLOR_RESET} from $(bytes_to_human $size_before) to $(bytes_to_human $size_after), by ${GREEN}$variation %${COLOR_RESET}"
                fi
            fi
        done <<< "$images_list"

        echo -e "${BLUE}Compression ${BRIGHTGREEN}OK${COLOR_RESET}"

        # Stats for this folder
        echo
        [ "$verbose" -eq 1 ] && echo -e "${BLUE}Folder${COLOR_RESET} ${YELLOW}$folder ${BLUE}complete.${COLOR_RESET}"
        echo -e "${BLUE}Initial size${COLOR_RESET} :    $(bytes_to_human $folder_before)"
        echo -e "${BLUE}Compressed size${COLOR_RESET} : $(bytes_to_human $folder_after)"
        folder_variation=$(awk -v after="$folder_after" -v before="$folder_before" 'BEGIN {print int(((after*100)/before)-100)}')
        if [ $folder_after -gt $folder_before ] ; then
                echo -e "${BLUE}Folder compression gain :  ${RED}$folder_variation %${COLOR_RESET}"
            else
                echo -e "${BLUE}Folder compression gain :  ${GREEN}$folder_variation %${COLOR_RESET}"
        fi

        # Test success with exit code ?
        [ "$verbose" -eq 1 ] && echo -e "${BLUE}Success, generating compression marker...${COLOR_RESET}"
        echo "Success" > "$folder/$lastrun_marker"
    fi

done <<< "$subfolders_list"


# Total stats
echo ; echo ; echo ; echo -e "${BRIGHTBLUE}*** Compression complete ! ***${COLOR_RESET}"

if [ $total_before -eq 0 ] ; then
    echo -e "${BLUE}No file were modified.${COLOR_RESET}"
    log_message "info" "No file were modified."
else
    echo -e "${BLUE}Total initial size :${COLOR_RESET}    $(bytes_to_human $total_before)"
    log_message "info" "Total initial size :     $(bytes_to_human $total_before)"
    echo -e "${BLUE}Total compressed size :${COLOR_RESET} $(bytes_to_human $total_after)"
    log_message "info" "Total compressed size :  $(bytes_to_human $total_after)"
    total_variation=$(awk -v after="$total_after" -v before="$total_before" 'BEGIN {print int(((after*100)/before)-100)}')
    if [ $total_after -gt $total_before ] ; then
             echo -e "${BLUE}Total compression gain :  ${RED}$total_variation %${COLOR_RESET}"
        else
            echo -e "${BLUE}Total compression gain :  ${GREEN}$total_variation %${COLOR_RESET}"
    fi
    log_message "info" "Total compression gain :  $total_variation %"
fi

if [ $error_count -gt 0 ] ; then
    echo -e "${BLUE}$error_count errors during execution, check $report for details${COLOR_RESET}"
    log_message "info" "$error_count errors during execution, check $report for details"
fi
echo

echo
echo -e "${BLUE}Script ended at : $(date)${COLOR_RESET}"
log_message "info" "Script ended."
echo

