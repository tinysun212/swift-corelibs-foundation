#!/bin/sh

# Prepare zoneinfo directory 
#   reference: https://data.iana.org/time-zones/tz-link.html

SOURCE_FILE=../CFZoneInfo.inc
ZONEINFO_DIR=zoneinfo


cd $ZONEINFO_DIR

# Add TZif files
for tzid in $(find . -name "[A-Z]*" -type f | sed -e "s;^./;;")
do
  TZVAR=$(echo $tzid | sed -e "s;^;k_;" -e "s;/;__;g" -e "s;-;_;g" -e "s;+;p;")
  echo "static const char $TZVAR[] = {"      >> $SOURCE_FILE
  hexdump -v -e '"0x" 1/1 "%02X" ", "' $tzid >> $SOURCE_FILE
  echo "};"                                  >> $SOURCE_FILE
done

# Add zone.tab
echo "static const char k_zone_tab[] = {"     >> $SOURCE_FILE
hexdump -v -e '"0x" 1/1 "%02X" ", "' zone.tab >> $SOURCE_FILE
echo "};"                                     >> $SOURCE_FILE

# Build zoneInfoList
echo "static const struct ZoneInfoListStruct zoneInfoList[] = {" >> $SOURCE_FILE
for tzid in $(find . -name "[A-Z]*" -type f | sed -e "s;^./;;")
do
  TZVAR=$(echo $tzid | sed -e "s;^;k_;" -e "s;/;__;g" -e "s;-;_;g" -e "s;+;p;")
  echo "{\"$tzid\", $TZVAR, sizeof($TZVAR)},"                    >> $SOURCE_FILE
done
echo "{\"zone.tab\", k_zone_tab, sizeof(k_zone_tab)},"           >> $SOURCE_FILE
echo "};"                                                        >> $SOURCE_FILE


