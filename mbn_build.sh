#!/bin/bash

#This script is used for build mcfg(mbn) for all country.Author by hero.guo@tcl.com, if there is some bug or problem in this, please send the #log.txt to the mail address.
#Thanks.
#

FATAL=1
ERROR=2
INFO=3
DEBUG=4

DEBUG_LEVEL=$ERROR
LOG_FILE="/log.txt"


CUR_PATH=""
ROOT_PATH=""
MBN_ROOT_PATH=""
MBN_ROOT_PATH_SUFFIX="/amss/modem_proc/mcfg/mcfg_gen/generic"
MBN_OUTPUT_PATH=""
MBN_OUTPUT_PATH_SUFFIX="/vendor/tct/source/qcn/auto_make_tar/mbn/mcfg_sw_mbn"
MBN_BUILD_PATH=""
MBN_BUILD_PATH_SUFFIX="/amss/modem_proc/mcfg/build"
project=$TARGET_PRODUCT
current_mbn_build=""

#{{index}, {PATH}, {region}, {operator}, {NA_TMO_Commercial}}
declare -a MBN_XML
declare -a MBN_NAME
declare -a mbn_build_list
user_selection=0
now_time='['$(date +"%Y-%m-%d %H:%M:%S")']'

function write_log()
{
  #now_time='['$(date +"%Y-%m-%d %H:%M:%S")']'
  echo ${now_time} $1 | tee -a ${LOG_FILE} > /dev/null
}

function usage()
{
    echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    echo "+  ./mbn_build.sh NA_TMO_TF_Commercial.mbn              +"
    echo "+  ./mbn_build.sh                                       +"
    echo "+  you can select the number you want to build          +"
    echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
}

function init_work_path()
{
    #get script path
    CUR_PATH=$(cd "$(dirname "$0")"; pwd)
    cd $CUR_PATH
    cd ..
    #get android source code path
    ROOT_PATH=$(pwd)
    MBN_ROOT_PATH=$ROOT_PATH$MBN_ROOT_PATH_SUFFIX
    MBN_OUTPUT_PATH=$ROOT_PATH$MBN_OUTPUT_PATH_SUFFIX
    #local tmp=`env|grep -i TARGET_PRODUCT`
    #TARGET_PRODUCT=${product##*=}    
    LOG_FILE=$CUR_PATH$LOG_FILE
    if [ -e $LOG_FILE ];then
        rm $LOG_FILE
        write_log "Delete last time log file = "$LOG_FILE    
    fi
    #if [ $DEBUG_LEVEL -ge $INFO ];then
        write_log "CUR_PATH="$CUR_PATH
        write_log "ROOT_PATH="$ROOT_PATH
        write_log "MBN_ROOT_PATH="$MBN_ROOT_PATH
        write_log "MBN_OUTPUT_PATH="$MBN_OUTPUT_PATH
        write_log "TARGET_PRODUCT="$TARGET_PRODUCT
    #fi
}

function init_mbn_xml()
{
    cd $MBN_ROOT_PATH
    local MBN_CONFIG=($(find -name '*.xml'))
    for ((index=0;index < ${#MBN_CONFIG[@]};index++));
    do        
        local mbn=`get_mbn_name_from_path ${MBN_CONFIG[$index]}`
        write_log "get_mbn_name_from_path [region_operator_suffix]=["$mbn"]"
        MBN_XML[$index]=${MBN_CONFIG[$index]}
        MBN_NAME[$index]=$mbn
    done
    local index=0
    write_log "==============MBN_NAME START==============="
    for name in ${MBN_NAME[@]};
    do
        write_log "MBN_NAME["$index"]="$name
        ((index++))
    done
    write_log "==============MBN_NAME END================="
    write_log "==============MBN_XML START================"
    index=0
    for xml in ${MBN_XML[@]};
    do
        write_log "MBN_XML["$index"]="${xml}
        ((index++))
    done
    write_log "==============MBN_XML END================"
}

function get_mbn_name_from_path()
{
    #str="./NA/ATT/mcfg_sw_gen_VoLTE.xml"
    local str=$1
    write_log "================================================================="
    if [ -z $str ];then
        #write_log "str is null"
        return 1
    fi
    write_log "original string = "$str
    #remove ./
    local tmp=${str#./}
    write_log "tmp = "${tmp}
    #remove region
    local region=${tmp%%/*}
    tmp=${tmp#*/}
    write_log "region = "$region" #### tmp = "$tmp
    local operator=${tmp%%/*}
    tmp=${tmp#*/}
    write_log "operator = "$operator" #### tmp = "$tmp
    tmp=${tmp##mcfg_sw_gen_}
    local suffix=${tmp%%.xml}
    tmp=${tmp%%.xml}
    write_log "suffix = "$suffix" #### tmp = "$tmp
    echo $region"_"$operator"_"$suffix
    write_log "================================================================="
}

function get_region_from_mbn_name()
{
    #local mbn="NA_TMO_Commercial"
    local mbn=$1
    if [ -z $mbn ];then
        write_log "get_region_from_mbn_name mbn error mbn = "$1
        return 1
    fi
    local region=${mbn%%_*}
    write_log "get_region_from_mbn_name mbn="$mbn" region="$region
    echo $region
    
}

function get_operator_from_mbn_name()
{
    #local mbn="NA_TMO_TF_Commercial"
    local mbn=$1
    if [ -z $mbn ];then
        write_log "get_operator_from_mbn_name error mbn = "$1
        return 1
    fi
    local operator=${mbn#*_}
    operator=${operator%%_*}
    write_log "get_operator_from_mbn_name mbn="$mbn" operator="$operator
    echo $operator
}

function get_suffix_from_mbn_name()
{
    #local mbn="NA_TMO_TF_Commercial"
    local mbn=$1
    if [ -z $mbn ];then
        write_log "get_suffix_from_mbn_name error mbn = "$1
        return 1
    fi
    local tmp=${mbn#*_}
    local suffix=${tmp#*_}
    write_log "get_suffix_from_mbn_name mbn="$mbn" suffix="$suffix
    echo $suffix
}

function show_mbn_list()
{
    if [ ${#MBN_NAME[@]} == 0 ];then
        write_log "ERROR MBN_NAME empty!"
        return 1
    fi
    local index=1
    echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    for name in ${MBN_NAME[@]};
    do
        echo $prefix$index"."$name".mbn"
        ((index++))
    done
    echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
}

function user_selection()
{
    while true;
    do
        show_mbn_list
        read -p "please select the mbn you want to build?" -a user_selection
        local error=0
        local index=0
        if [ ${#user_selection[@]} -eq 0 ];then
            continue
        fi
        for sel in ${user_selection[@]};
        do
            #check the input is a numeric
            expr ${sel} + 0 1>/dev/null 2>&1
            if [ $? -eq 0 ];then
                mbn_build_list[$index]=${MBN_NAME[((${sel}-1))]}
                ((index++))
                continue
            else
                echo "input is not a numeric exit"
                error=1
                break
            fi
        done
        if [ $error -eq 0 ];then
            write_log "==============MBN_BUILD_LIST START=========="
            local index=0
            for list in ${mbn_build_list[@]};
            do
                write_log "mbn_build_list["$index"] = "$list
                ((index++))
            done
            write_log "==============MBN_BUILD_LIST END============"
            break
        else
            continue
        fi
    done
    return 0
}

#precondition  exist amss/modem_proc/mcfg/build/mcfg_sw.mbn
function sign_mbn()
{
    local pre_mbn=$ROOT_PATH"/amss/modem_proc/mcfg/build/mcfg_sw.mbn"
    if [ ! -e $pre_mbn ];then
        write_log $pre_mbn" not exists"
        return 1
    fi
    if [ -z $TARGET_PRODUCT ];then
        write_log "TARGET_PRODUCT NO VALUED, please run source ./build/envsetup.sh && choosecombo"
        echo "TARGET_PRODUCT does not exsist, please run command under the root path"
        echo "source ./build/envsetup.sh"
        echo "choosecombo"
        return 1
    fi
    case $TARGET_PRODUCT in
        pixi355_tf)
            project="pixi355tf";;
        pixi355_tmo)
            project="pixi355tmo";;
        pixi455_geophone)
            project="pixi445tf";;
        pixi355)
            project="pixi355";;
        pixi355_cricket)
            project="pixi355cricket";;
        #begin: added by yunzhou.song for bug 1143935
        pixi445_tf)
            project="pixi355tf";;
        pixi4453g_tf)
            project="pixi4453gtf";;
        #end: added by yunzhou.song for bug 1143935

    esac
    local sign_dir=$ROOT_PATH"/build/tools/sign_tool/"$project
    write_log "sign_mbn sign_dir = "$sign_dir
    cd $sign_dir
    #begin: modified by yunzhou.song for bug 1143935
    if [ "$TARGET_PRODUCT" == "pixi445_tf" ]; then
        local sign_command="./st.sh "$ROOT_PATH" "pixi355_tf" mcfg"
    else
        local sign_command="./st.sh "$ROOT_PATH" "$TARGET_PRODUCT" mcfg"
    fi
    #end: modified by yunzhou.song for bug 1143935
    echo ${now_time}" sign_command = "$sign_command >> $LOG_FILE
    $sign_command 1 >> $LOG_FILE
    if [ $? -eq 0 ];then
        write_log "sign_mbn sign success"
    else
        write_log "sign_mbn sign failed mbn = "$current_mbn_build
        return 1
    fi
}

#parameters NA_TMO_Commercial mbn_name
function build_mcfg()
{
    #local mbn="NA_TMO_Commercial"
    local mbn=$1
    if [ -z $mbn ];then
        write_log "build_mcfg mbn error empty mbn = "$1
        return 1
    fi
    
    #mbn information such as region operator suffix
    local region=`get_region_from_mbn_name ${mbn}`
    if [ ! $? -eq 0 ];then
        write_log "build_mcfg region error"
    fi
    local operator=`get_operator_from_mbn_name ${mbn}`
    if [ ! $? -eq 0 ];then
        write_log "build_mcfg operator error"
    fi
    local suffix=`get_suffix_from_mbn_name ${mbn}`
    if [ ! $? -eq 0 ];then
        write_log "build_mcfg suffix error"
    fi
    
    #ROOT_PATH/amss/modem_proc/mcfg/build
    MBN_BUILD_PATH=$ROOT_PATH$MBN_BUILD_PATH_SUFFIX
    cd $MBN_BUILD_PATH
    local build_command="perl ./build_mcfgs.pl --force-regenerate --force-rebuild --source-dir=generic/"$region"/"$operator" --configs=mcfg_sw:"$suffix" --xml"
    echo ${now_time}" build_command = "${build_command} >> $LOG_FILE
    
    #copy the mcfg_sw.mbn to amss/modem_proc/mcfg/build  ready for sign
    source_mbn=$ROOT_PATH"/amss/modem_proc/mcfg/configs/mcfg_sw/generic/"$region"/"$operator"/"$suffix"/mcfg_sw.mbn "
    local copy_command="cp -f "$ROOT_PATH"/amss/modem_proc/mcfg/configs/mcfg_sw/generic/"$region"/"$operator"/"$suffix"/mcfg_sw.mbn "$ROOT_PATH"/amss/modem_proc/mcfg/build/"
    if [ -e $source_mbn ];then
        write_log "delete the last build mbn path = "$source_mbn
        rm $source_mbn
    fi
    if [ -e mcfg_sw.mbn ];then
        write_log "delete the last build mbn path = "$(pwd)"/mcfg_sw.mbn"
        rm mcfg_sw.mbn
    fi
    echo ${now_time}" copy_command = "${copy_command} >> $LOG_FILE
    $build_command 1 >> ${LOG_FILE}
    if [ $? -eq 0 ];then
        write_log "build mbn success mbn = "$mbn
    else
        write_log "build mbn failed errorcode ="$?
        return 1
    fi
    $copy_command >> ${LOG_FILE}
    if [ $? -eq 0 ];then
        write_log "copy mbn to build success"
    else
        write_log "copy mbn to build failed errorcode ="$?
        return 2
    fi
    #call function sign_mbn
    sign_mbn
    if [ $? -eq 0 ];then
        write_log "build_mcfg sign success"
    else
        write_log "build_mcfg sign failed mbn ="$mbn
        return 1
    fi
    
    #copy to signed mbn to /vendor/tct/source/qcn/auto_make_tar/mbn/mcfg_sw_mbn
    local signed_mbn=$ROOT_PATH"/amss/modem_proc/mcfg/build/mcfg_sw.mbn"
    local dest_mbn=$ROOT_PATH"/vendor/tct/source/qcn/auto_make_tar/mbn/mcfg_sw_mbn/"$region"/"$operator"/"$suffix"/"
    local dest_cur_mbn=$ROOT_PATH"/amss/"
    if [ ! -e $dest_mbn ];then
        write_log "directory is not exist, make it dir = "$dest_mbn
        mkdir -p $dest_mbn
    fi
    local copy_vendor="cp -f "$signed_mbn" "$dest_mbn$mbn".mbn"
    local copy_cur="cp -f "$signed_mbn" "$dest_cur_mbn$mbn".mbn"
    write_log "copy_vendor = "$copy_vendor
    write_log "copy_cur = "$copy_cur
    $copy_cur
    if [ $? -eq 0 ];then
        write_log "copy to current path success"
    else
        write_log "copy to current path failed"
        return 1;
    fi
    $copy_vendor
    if [ $? -eq 0 ];then
        write_log "copy to vendor success"
    else
        write_log "copy to vendor failed"
        return 1
    fi
}

function build_mcfg_list()
{
    if [ ${#mbn_build_list[@]} -lt 0 ];then
        write_log "mbn_build_list empty, there is no mbn need to build error"
        return 1;
    fi
    local index=0
    for build in ${mbn_build_list[@]}
    do
        write_log ">>>>>>>>build mcfg START>>>>>>>>>>>>>>>>>>"$build
        build_mcfg $build
        if [ $? -eq 0 ];then
            write_log "build success and unset mbn_build_list["$index"] = "${mbn_build_list[$index]}
            echo "build success mbn = "${mbn_build_list[$index]}
            unset mbn_build_list[$index]
        else
            write_log "build failed mbn = "$build
            echo "build failed mbn = "${mbn_build_list[$index]}
            return 1
        fi
        write_log "<<<<<<<<build mcfg END<<<<<<<<<<<<<<<<<<<<"$build
        ((index++))
    done
    return 0;
}

function __init__()
{
    #init work path
    init_work_path
    #init mbn xml
    init_mbn_xml
    #clear the screen
    #clear
}

function __main__()
{
    echo $1
    if [ -n "$1" ];then
        local index=0
        local user_need="$1"
        user_need=${user_need%.mbn}
        for input_mbn in ${MBN_NAME[@]}
        do
            if [ "$input_mbn" == "$1" -o "$input_mbn" = "$user_need" ];then
                mbn_build_list[index]=$input_mbn
                write_log "input_mbn["$index"]="$input_mbn
                ((index++))
            fi            
        done
        if [ ${#mbn_build_list[@]} -eq 0 ];then
            #call usage for show command
            echo "The mbn command you want to build does not exists, please check the mbn name"
            usage
        fi
    elif [ ${#mbn_build_list[@]} -eq 0 ];then
        write_log "not input build mbn name list to select"
        user_selection
    else
        #call usage to show a command 
        usage
    fi
    build_mcfg_list
    if [ $? -eq 0 ];then
        return 0;
    else
        return 1;
    fi
}

__init__
__main__ $1




