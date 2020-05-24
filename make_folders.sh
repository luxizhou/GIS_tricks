#!/bin/bash

# Provide options to structure the folders
CATALOG_LENGTH=1000
SIMU_YEARS=200
CHUNKS=5
FIRST_YEAR=9001
FIRST_CHUNK=46
GAP=$(( $CATALOG_LENGTH / $CHUNKS ))
EXECUTABLE=EQLossSim_release.exe
START_YEAR=$FIRST_YEAR

# local template file for FF intensity file path
PATH_FILE="FF_TD10K_DAMAGE_RATIOS.txt"
# path to text file, in which the content shows the real FF intensity text file 
BIN_PATH="\\\\edc\RS\Earthquake\Model\Model_052\m6.0_v15\LossSimulation\EQLossSim\data\FireFollowing"

# FF intensity file generated from step 2
FF_FILE=FF_CLASIC2_DAMAGE_RATIOS_wAuto_sorted.txt
# path to the actual location of FF intesntiy text file on edc
TXT_DEST="\\\\edc\RS\Earthquake\Model\Model_052\m6.0_v15\LossSimulation\EQLossSim\data\FireFollowing\V6_Reproduction\Stochastic"
# path to the location of FF intensity text file generated from step 2
TXT_ORIG="\\\\rs16sv004\C\Users\i24874\Work\M052\2013_Release_Reproduction\Stochastic\02_FFE_DamageRatio"

# Provide specifications on the server
COMPUTER=rs16sv004 
BASE_DIR="C:\Users\i24874\Work\M052\2013_Release_Reproduction\Stochastic\03_Binary_File_for_EQSim"

# Provide specifications for the scheduled tasks
TN="FFE_TD10K_Step3_"
SH=11
SM=0
SD="05/06/2020"
USR="i24874"
PWD="Welcome2020!"
#read -p 'iNumber: ' USR
#read -sp 'Password: ' PWD

# Make folders and prepare files and executables for each folder
idx=$FIRST_CHUNK
END_CHUNK=$(( $FIRST_CHUNK + $CHUNKS -1 ))
while [ $idx -le $END_CHUNK ]
do
  echo NUMYEARSTART: $START_YEAR
  ITEM="chunk$idx"
  DIR="./$ITEM"
  # make a folder 
  [ ! -d $DIR ] && mkdir -p $DIR
  ((idx++))
  START_YEAR_STR="NUMYEARSTART;  ${START_YEAR}"

  # modify original op_industry file and move to destination folder
  OUT_FILE="${DIR}/op_industry"
  sed "s/chunk1/$ITEM/g" op_industry > op_temp
  sed "s/NUMYEARSTART;  1/$START_YEAR_STR/g" op_temp > $OUT_FILE

  # make binary path file
  FILE_NAME=FF_TD10K_DAMAGE_RATIOS_${ITEM}.txt
  sed "s/chunk1/$ITEM/g" $PATH_FILE > $FILE_NAME
  cp -r $FILE_NAME $BIN_PATH
  
  cp -r ${TXT_ORIG}/${ITEM}/${FF_FILE} ${TXT_DEST}/${FILE_NAME}


  # copy executables to folders
  cp $EXECUTABLE $DIR

  # copy in_industry to folders
  OUT_FILE="${DIR}/in_industry"
  sed "s/chunk1/$ITEM/g" in_industry > $OUT_FILE

  # make executable script
  DEST_DIR="${BASE_DIR}\\${ITEM}"
  RUN_FILE="${DIR}/run.bat"
  exec 101<> $RUN_FILE
    echo "cd ${DEST_DIR}" >&101
    echo $EXECUTABLE >&101
  exec 101>&-

  # update information (START_YEAR) for next chunk
  NEW_YEAR=$(( $START_YEAR + $GAP ))
  START_YEAR=$NEW_YEAR
done

# Make task scheduling batch files
idx=$FIRST_CHUNK
exec 102<> 04_ScheduleTasks.bat
exec 103<> 04_QueryTasks.bat
exec 104<> 04_EndTasks.bat
while [ $idx -le $END_CHUNK ]
do
  ITEM="chunk$idx"
  EXEC_FILE="${BASE_DIR}\\${ITEM}\run.bat"
  mm=$(printf "%02d" $SM)
  echo "schtasks /Create /TN \"${TN}${ITEM}\" /TR \"${EXEC_FILE}\" /S ${COMPUTER} /U ${USR} /P \"${PWD}\" /SC once /SD ${SD} /ST ${SH}:${mm} /RU ${USR} /RP \"${PWD}\"" >&102
  echo "schtasks /Query /TN \"${TN}${ITEM}\" /S ${COMPUTER}" >&103
  echo "schtasks /end /TN \"${TN}${ITEM}\" /S ${COMPUTER}" >&104
  ((idx++))
  ((SM++))
done
exec 102>&-
exec 103>&-
exec 104>&-
chmod +xwr 04_ScheduleTasks.bat
chmod +xwr 04_QueryTasks.bat
chmod +xwr 04_EndTasks.bat

echo Done!
