#!/bin/bash

arch=$(uname -m)

##### Hostname Generation Section #####
hostname="DESKTOP-$(tr -dc 'A-Z0-9' </dev/urandom | head -c 7)"

##### Machine ID and Boot ID Section #####
machine_id=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')
boot_id=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')

##### Vendor and Model Generation Section #####
vendors="Acer Apple Asus Dell HP Lenovo MSI Samsung Sony LG Microsoft Alienware Razer Huawei IBM Intel Panasonic Fujitsu Toshiba Gigabyte EVGA Zotac Google"
set -- $vendors
vendor_count=$#
vendor_index=$(( $(od -An -N2 -tu2 /dev/urandom | tr -d ' ') % vendor_count + 1 ))
vendor=$(eval echo \${$vendor_index})

prefixes="INS PAV THK ZEN OMN ASP LEG VOS XPS PRD ROG STR ENV TUF VIO GRM"
set -- $prefixes
prefix_count=$#
prefix_index=$(( $(od -An -N2 -tu2 /dev/urandom | tr -d ' ') % prefix_count + 1 ))
prefix=$(eval echo \${$prefix_index})

model_number=$(( 10000 + $(od -An -N2 -tu2 /dev/urandom | tr -d ' ') % 90000 ))

suffixes="LX GX TX VX FX NX ZX HX DX CX"
set -- $suffixes
suffix_count=$#
suffix_index=$(( $(od -An -N2 -tu2 /dev/urandom | tr -d ' ') % suffix_count + 1 ))
suffix=$(eval echo \${$suffix_index})

version=$(( 10 + $(od -An -N2 -tu2 /dev/urandom | tr -d ' ') % 90 ))

model="$prefix-$model_number-$suffix$version"

##### Firmware Version Generation Section #####
major=$(( $(od -An -N2 -tu2 /dev/urandom | tr -d ' ') % 9 + 1 ))
minor=$(printf "%02d" $(( $(od -An -N2 -tu2 /dev/urandom | tr -d ' ') % 100 )))
patch=$(( $(od -An -N2 -tu2 /dev/urandom | tr -d ' ') % 10 ))
build=$(( $(od -An -N2 -tu2 /dev/urandom | tr -d ' ') % 10 ))
firmware_version="${major}.${minor}.${patch}-${build}"

##### Firmware Date and Age Calculation Section #####
start_date="2010-01-01"
end_date="2020-12-31"
start_sec=$(date -d "$start_date" +%s)
end_sec=$(date -d "$end_date" +%s)
rand_sec=$(( start_sec + $(od -An -N4 -tu4 /dev/urandom | tr -d ' ') % (end_sec - start_sec + 1) ))
firmware_date=$(date -d "@$rand_sec" "+%a %Y-%m-%d")
firmware_date_only=$(echo "$firmware_date" | cut -d' ' -f2)
firmware_date_sec=$(date -d "$firmware_date_only" +%s)
today_sec=$(date +%s)
diff_sec=$(( today_sec - firmware_date_sec ))
diff_days=$(( diff_sec / 86400 ))
years=$(( diff_days / 365 ))
rem_days=$(( diff_days % 365 ))
months=$(( rem_days / 30 ))
days=$(( rem_days % 30 ))
firmware_age="${years}y ${months}month ${days}d"

##### Custom lsb_release Script Creation Section #####
cat << 'EOF' > /usr/bin/lsb_release
#!/bin/sh
echo "No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 24.04 LTS
Release:        24.04
Codename:       noble"
EOF

##### Custom hostnamectl Script Creation Section #####
cat << EOF > /usr/bin/hostnamectl
#!/bin/sh
echo " Static hostname: ${hostname}
       Icon name: computer
         Chassis: desktop
      Machine ID: ${machine_id}
         Boot ID: ${boot_id}
  Virtualization: none
Operating System: Ubuntu 24.04 LTS
          Kernel: Linux 6.15.0-00-generic
    Architecture: ${arch}
 Hardware Vendor: ${vendor}
  Hardware Model: ${model}
Firmware Version: ${firmware_version}
   Firmware Date: ${firmware_date}
    Firmware Age: ${firmware_age}"
EOF

##### Permissions Section #####
chmod a+x /usr/bin/lsb_release /usr/bin/hostnamectl
