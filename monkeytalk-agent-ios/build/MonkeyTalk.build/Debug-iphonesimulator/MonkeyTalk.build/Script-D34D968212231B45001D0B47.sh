#!/bin/sh
echo "#define MT_BUILD_STAMP @\"BUILD `date +%y%m%d.%H%M`\"" > MTBuildStampDefines.h
echo "#define MT_BUILD_DATE @\"`date +\"%Y-%m-%d %H:%M:%S %Z\"`\"" >> MTBuildStampDefines.h
echo "#define MT_BUILD_NUMBER @\"${BUILD_NUMBER}\"" >> MTBuildStampDefines.h
echo "#define MT_VERSION @\"${MT_VERSION}\"" >> MTBuildStampDefines.h


