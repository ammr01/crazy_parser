#!/bin/bash
# Author : amr
# OS : Debian 12 x86_64
# Date : 09-Sep-2024
# Project Name : crazy_parser



error_flag=0
default_error_code=1


err(){
    # err [message] <type> <isexit> <exit/return code>
    #   I- message (mandatory): text to print
    #  II- type (optional "default is (note)"): 
    #      1 : note
    #      2 : warning
    #      3 : error (needs two more arguments)
    # III- isexit (optional "default is 1"):
    #      0 : exit after printing 
    #          (set exit code in the next
    #           arg, default error code
    #           is used if error code
    #           is not set).
    #      1 : return a status code after printing 
    #          (set return code in the next
    #           arg, default return code
    #           is used if return code
    #           is not set).
    #      2 : do not exit or return
    #  IV- error/return code : 
    #      to set error/return code, must be numeric, 
    #      if not numeric or not set, the default 
    #      value will be used. 
    
    local text="$1"
    local type=${2-1}
    local isexit=${3-1}
    local error_code=${4-$default_error_code}
    local typestr=""
    local fd=1
    
    if ! [[ "$type" =~ ^[0-9]+$ ]]; then
        type=1
    fi

    if ! [[ "$isexit" =~ ^[0-9]+$ ]]; then
        isexit=1
    fi

    if ! [[ "$error_code" =~ ^[0-9]+$ ]]; then
        error_code=$default_error_code
    fi
    case $type in 
    1)
        typestr="NOTE"
        fd=1 #stdout
    ;;
    2)
        typestr="WARNING"
        fd=1 #stdout
    ;; 
    3)
        typestr="ERROR"
        fd=2 #stderr
    ;;
    *)
        typestr="NOTE"
        fd=1 #stdout
    ;;
    esac
    
    if [ $error_flag -eq 0 ]; then 
        >&$fd echo -e "[$typestr:START]\n$text\n[$typestr:END]"
        if [ "$isexit" -eq 0 ]; then
            exit "$error_code"
        elif [ "$isexit" -eq 1 ]; then
            return "$error_code"
        fi

    fi
    
}


list=()

print_list(){

    # check arguments number
    if [ "$#" -ne 2 ]; then
        err "Invalid arguments number to print_list() function!" 3 1 3 ; return $?
    fi
    # receive first argument as a list
    local list=("${!1}") 

    # second argument is the elemnts seperator
    local seperator="$2" 

    local len="${#list[@]}"

    for ((i=0;i<len-1;i++)); do
        echo -n "${list[$i]}"
        echo -ne "$seperator"
    done
    if [ "$len" -gt 0 ]; then
        echo -n "${list[$len-1]}"
    fi
}


convert_to_arrayln_O() {
    # Convert to arrayln OPTIMIZED
    # Converts strings to array, each element is a line 
    # Stores the output in the global array $list
    # Returns 0 if no errors occurred
    # $1 is the string
    
    local input="$1"
    list=()

    # Temporarily change IFS to newline to handle spaces correctly
    while IFS=$'\n' read -r line; do
        list+=( "$line" )
    done <<< "$input"

    return 0
}



      

parseall(){


    
    local headerfields="DetectId
CommandLine
ComputerName
UserName
DetectDescription
DetectName
FileName
FilePath
LocalIP
MACAddress
MachineDomain
ParentCommandLine
ParentImageFileName
PatternDispositionDescription
SeverityName
Tactic
Technique
QuarantineFiles[x].ImageFileName
DocumentsAccessed[x].FileName
DocumentsAccessed[x].FilePath
ExecutablesWritten[x].FilePath"

local fields="DetectId
CommandLine
ComputerName
UserName
DetectDescription
DetectName
FileName
FilePath
LocalIP
MACAddress
MachineDomain
ParentCommandLine
ParentImageFileName
PatternDispositionDescription
SeverityName
Tactic
Technique"

    convert_to_arrayln_O "$headerfields"


    header="$(print_list list[@] ,)"
    echo $header

    convert_to_arrayln_O "$fields"

    query_fields="$(print_list list[@] " , .")"
    local tmp=`mktemp`

    local tmp1=`mktemp`
    # local tmp2=`mktemp`
    local tmp3=`mktemp`
    local tmp4=`mktemp`
    local tmp5=`mktemp`
    local tmp6=`mktemp`


    x=0
    for ((x=0;x<json_array_length;x++));do
        echo "" > $tmp1
        echo "" > $tmp3
        echo "" > $tmp4
        echo "" > $tmp5
        echo "" > $tmp6

        jq ".[$x] | .$query_fields" "$datafile"  > $tmp 2>/dev/null || err "cannot read from file \"$datafile\"" 3 1 77 || return $?
        convert_to_arrayln_O "$(cat $tmp)"
        print_list list[@] ","
        echo -n ","
        jq --argjson x $x '.[$x] | with_entries(select(.key | test("QuarantineFiles\\[\\d\\].ImageFileName$|DocumentsAccessed\\[\\d\\].FileName$|DocumentsAccessed\\[\\d\\].FilePath$|ExecutablesWritten\\[\\d\\].FilePath$"))) ' "$datafile"   > $tmp1 2>/dev/null || err "cannot read from file \"$datafile\"" 3 0 78
        convert_to_arrayln_O "$(cat $tmp1)"
        print_list list[@] "\n" | awk -F '": "'  -v tmp6=$tmp6 -v tmp3=$tmp3 -v tmp4=$tmp4  -v tmp5=$tmp5 '$1 ~ /"QuarantineFiles\[[0-9]+\]\.ImageFileName/ {print "\"" $2 > tmp6 }  $1 ~ /"DocumentsAccessed\[[0-9]+\]\.FileName/ {print "\"" $2 > tmp3 } $1 ~ /"DocumentsAccessed\[[0-9]+\]\.FilePath/ {print "\"" $2 > tmp4 } $1 ~ /"ExecutablesWritten\[[0-9]+\]\.FilePath/ {print "\"" $2 > tmp5 }' 
        # print_list list[@] "\n" | awk -F '": "'  '  $1 ~ /"DocumentsAccessed\[\d\]\.FileName/ {print "\"" $2 } $1 ~ /"DocumentsAccessed\[\d\]\.FilePath/ {print "\"" $2 } $1 ~ /"ExecutablesWritten\[\d\]\.FilePath/ {print "\"" $2  }' 
        echo -n "\"`cat $tmp6 | tr  -d  '"' | sed 's/,$//'`\",\"`cat $tmp3 | tr  -d  '"' | sed 's/,$//'`\",\"`cat $tmp4 | tr  -d  '"' | sed 's/,$//'`\",\"`cat $tmp5 | tr  -d  '"' | sed 's/,$//'`\""
        # cat $tmp4
        echo ""
      

    done
    rm $tmp
    rm $tmp1
    rm $tmp3
    rm $tmp4
    rm $tmp5
    rm $tmp6
    
 
}


if [ $# -lt 1 ]; then
    err "provide input file name, ex: $0 /home/user/Downloads/sample.json" 3 0 10
fi

datafile="$1"
if [ ! -f "$datafile" ]; then
    err "file \"$datafile\" is not found" 3 0 7
fi

which jq 1>/dev/null || err "please install jq tool before use this script, for debian based system use \"sudo apt install jq\"" 3 0 8
json_array_length=`jq length "$datafile"`

tmp1=`mktemp`

parseall > $tmp1 || err "parseall error" 3 0 $?
cat $tmp1



