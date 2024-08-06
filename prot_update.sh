#!/bin/bash
# Updater cover version
# Variables
mainpath="//stacmstore1.websense.com/departments/RND/CM/dev/PortAuthority/"
#SOURCE_PATH="//stacmstore1.websense.com/departments/RND/CM/dev/PortAuthority/"
#USERNAME="qa"
#PASSWORD="qa"

## Root?
function root_check() {
  [ "$(id -u)" != 0 ] && {
      echo "You must log on as root to install this update." >&2
      exit 1
  }
}

# Check if yum repo needs patching (Old CentOS releases)
function detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
    PNAME=$PRETTY_NAME
  else
    OS=$(uname -s)
    VER=$(uname -r)
  fi
  echo "Detected OS: $PNAME"
}

function patch_centos_repo() {
if [[ "$OS" = "centos" ]]; then
    if grep -q "^baseurl=http://mirror.centos.org" /etc/yum.repos.d/CentOS-*; then
        echo "Patching yum repository on CentOS 7..."
        sudo sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
        sudo sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
    fi
    else
      echo "Already patched or latest OS version"
fi
}

function install_dependencies {
    packages=("cifs-utils" "unzip")

    for package in "${packages[@]}"; do
        if ! rpm -qa | grep -qw "$package"; then
            echo -n "Checking dependencies for $package... "
            if ! sudo yum install -y "$package"; then
                echo "Failed to install $package. Exiting."
                exit 1
            fi
        else
            echo "$package is already installed."
        fi
    done
}

function protector_update() {
echo "Enter version to which update"
read -r version_input
if [[ "$version_input" == 10.1 ]] || [[ "$version_input" == 10.2 ]] || [[ "$version_input" == 10.3 ]] || [[ "$version_input" == 8.8 ]]; then
  version="${version_input}.0"
else version="${version_input}.0.0"
fi
echo "Version ${version}"
echo "Enter build to which update"
read -r build_input
build="${build_input}"
echo "Build $build_input"
echo "${mainpath}${version}/${build}/install/"
if [[ $version_input == 10.3 ]]; then
  ls -lah /mnt/tmp/ | grep 'protector-update-${version}-${build}.${os}'
  cp /mnt/tmp/protector-update-${version}-${build}.${os} /root/tmp/
  chmod +x /root/tmp/protector-update-${version}-${build}.${os}
  ./protector-update-${version}-${build}.${os} --silent
else
  ls -lah /mnt/tmp/ | grep 'protector-update-${version}-${build}.zip'
  cp /mnt/tmp/protector-update-${version}-${build}.zip /root/tmp/
  unzip "/root/tmp/protector-update-${version}-${build}".zip
  ls -lah /root/tmp/ | grep "protector-update-${version}-${build}"
  chmod +x "/root/tmp/protector-update-${version}-${build}"
  ./protector-update-"${version}-${build}" --silent
fi
}

root_check

# Print current version
echo "The version you using is: $version"

# Main script execution
echo "Forcepoint Protector ISO Updater"
detect_os
patch_centos_repo
install_dependencies
protector_update

# Mount share with builds
if [[ ! -e /mnt/tmp ]]; then
            mkdir /mnt/tmp
fi

mkdir /root/tmp
cd /root/tmp/ || exit

full_remote_path="${mainpath}${version}/${build}/install/"

mount.cifs "$full_remote_path" /mnt/tmp/ -o user=qa,password=qa
# OS Detection
os_version=$(hostnamectl | grep "Operating System" | awk -F': ' '{print $2}' | awk '{print $1 $2 $3}')
if [ "$os_version" == "CentOSLinux7" ]; then
  os="el7.x86_64"
elif [ "$os_version" == "RedHatEnterprise" ]; then
  os="el8.x86_64"
fi


# Cleanup and post-upgrade reboot
echo "Cleaning up..."
rm -rf /root/tmp/
#echo "Restarting..." | reboot
