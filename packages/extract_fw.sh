#!/usr/bin/env bash

DL_FILE=./link.txt
FW_FILE=firmware.bin

check_link() {
  if [ -f "$DL_FILE" ]; then
    DL_LINK=$(cat $DL_FILE)
    echo "Found >> $DL_LINK << in $DL_FILE"
  else
    echo "Not found $DL_FILE: Creating file"
    echo "Please paste the link in $DL_LINK"
    touch $DL_FILE
  fi
}

download_fw() {
  FW_BINNAME=$(echo $DL_LINK | rev | cut -d '/' -f 1 | rev)
  FW_PRODUCT=$(echo $FW_BINNAME | cut -d '-' -f 2)
  FW_VERSION=$(echo $FW_BINNAME | cut -d '-' -f 3)
  # echo $DL_FILENAME
  echo -e "\nProduct: $FW_PRODUCT-$FW_VERSION"
  if [ -f "$FW_FILE" ]; then
    echo "Found $FW_FILE"
  else 
    wget -O $FW_FILE $DL_LINK
  fi
}

check_tools_available() {
  app_name=$1
  for app in $app_name; do
    app_check=$(which $app)
    if [ -f "$app_check" ]; then
      echo "Found: $app ($app_check)"
    else
      echo "Not Found $app, exiting..."
      exit 1
    fi
  done
}


process_firmware() {
  # Extract content
  binwalk --extract --run-as=root $FW_FILE
  
  # Extract packages from Ubiquity to package list file
  dpkg-query --admindir=_$FW_FILE.extracted/squashfs-root/var/lib/dpkg/ -W -f='${package} | ${Maintainer}\n' | grep -E "@ubnt.com|@ui.com" | cut -d "|" -f 1 > packages.full.list

  # F
  while read pkg; do
    dpkg-repack --root=_$FW_FILE.extracted/squashfs-root --arch=arm64 ${pkg}
  done < packages.list

  # Move all the deb packages to packages
  mkdir packages
  mv -v *_arm64.deb packages/

  # Cleanup
  rm -Rf _$FW_FILE.extracted 
  rm -v packages.list

}

main() {
  check_link
  download_fw
  check_tools_available "dpkg binwalk dpkg-repack"
  process_firmware 
}

main