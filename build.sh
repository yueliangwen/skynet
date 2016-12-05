#!/bin/sh

#####################################################################################
#  @Filename: build.sh
#  @Brief   : 
#  @Auth    : yuelw
#  @Date    : 2016-12-05
#  @Version : ver 1.1
#  @Function: 
#  @Inparam : NA
#  @Outparam: NA
#  @Remark  : NA
#####################################################################################

BUILD_PATH="./build"

#####################################################################################
#  @Brief   : 简单日志
#  @Inparam : NA
#  @Outparam: NA
#  @Remark  : NA
#####################################################################################
function Log
{
    echo "[BUILD] " `date +"%Y-%m-%d %H:%M:%S"` "    " $1;
}

#####################################################################################
#  @Brief   : 检查是否存在外部编译目录不存在则创建
#  @Inparam : NA
#  @Outparam: NA
#  @Remark  : NA
#####################################################################################
function CreateBuildDirectory
{
    Log "checking build path..."
    if [ ! -x "${BUILD_PATH}" ]; then
        Log "creating build path..."
        mkdir "${BUILD_PATH}"
        ##由于权限可能导致创建失败，将在使用该目录时候检查
    fi
}

#####################################################################################
#  @Brief   : 打印帮助信息
#  @Inparam : NA
#  @Outparam: NA
#  @Remark  : NA
#####################################################################################
function PrintUsage
{
    echo "Usage:"
    echo "  $0 {release|debug|all|clean}"
    echo "  - realse     cmake .."
    echo "  - debug      cmake -DCMAKE_BUILD_TYPE=Debug -DUSER_DEBUG=1 .."
    echo "  - all        cmake -DCMAKE_BUILD_TYPE=Debug -DENABLE_GCOV=1 -DUSER_DEBUG=1 .."
    echo "  - clean      clean .."
}

#####################################################################################
#  @Brief   : 编译目标文件
#  @Inparam : cmake 参数
#  @Outparam: NA
#  @Remark  : NA
#####################################################################################
function BuildTarget
{
    Log "access ${BUILD_PATH}"
    cd ${BUILD_PATH}
    if [ $? -eq 0 ]; then
        Log "execute cmake $1"
        cmake $1
        if [ $? -eq 0 ]; then
            make
        else
            Log "execute cmake $1 failed!"
        fi
    else
        Log "access ${BUILD_PATH} failed!"
    fi
}

#####################################################################################
#  @Brief   : 主函数
#  @Inparam : NA
#  @Outparam: NA
#  @Remark  : NA
#####################################################################################
function Main
{
    case "x$1" in
        xrelease)
            CreateBuildDirectory
            BuildTarget ".."
            ;;
        xdebug)
            CreateBuildDirectory
            BuildTarget "-DCMAKE_BUILD_TYPE=Debug -DUSER_DEBUG=1 .."
            ;;
        xall)
            CreateBuildDirectory;
            BuildTarget "-DCMAKE_BUILD_TYPE=Debug -DENABLE_GCOV=1 -DUSER_DEBUG=1 .."
            ;;
        xclean)
            Log "cleaning..."

            if [ -x "${BUILD_PATH}" ]; then
                rm -rf "${BUILD_PATH}";
            fi
            ;;
        *)
            PrintUsage;
            ;;
    esac
}

## Entrance...
Main $1
