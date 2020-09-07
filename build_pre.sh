#!/bin/sh

mkdir build || exit
cd build
WORK=`pwd`
echo $WORK

git clone git://git.yoctoproject.org/poky
git clone git://git.linaro.org/openembedded/meta-linaro.git
git clone git://git.openembedded.org/meta-openembedded
git clone git://github.com/renesas-rcar/meta-renesas
#ADAS need
git clone git://github.com/CogentEmbedded/meta-rcar.git

#For yocto v3.9.0 BSP V4
cd $WORK/poky
git checkout -b tmp 342fbd6a3e57021c8e28b124b3adb241936f3d9d
cd $WORK/meta-openembedded
git checkout -b tmp dacfa2b1920e285531bec55cd2f08743390aaf57
cd $WORK/meta-linaro
git checkout -b tmp 75dfb67bbb14a70cd47afda9726e2e1c76731885
cd $WORK/meta-renesas
git checkout -b tmp fd078b6ece537d986852cb827bd21e022a797b2f
cd $WORK/meta-rcar
git checkout -b v3.9.0-release4 4dc3c67469b5dc53d2e33f966eb8043e47087d0a


cd $WORK/
#wait for key enter
read -s -n1 -p "Press any key to continue ..."

read -t 10 -p "Do you want to use Software Packages?(yes or no):" Arg
case $Arg in
Y|y|YES|yes)
 break;;
N|n|NO|no)
 exit;;
"")
 exit;;
esac

echo -e "\n"
echo "Start to copy Software Packages..." && echo -e "\n"
PKGS_DIR=$WORK/../proprietary
mkdir $PKGS_DIR || exit
test ! -d $PKGS_DIR && echo "Packages directory DO NOT exist!" && exit 0

read -p "Please input your Software package path(for example: /home/dell/Downloads): " \
path

test ! -d $path && echo "Packages directory DO NOT exist!" && exit 0
cp -v $path/* $PKGS_DIR

cd $WORK/meta-renesas
sh meta-rcar-gen3/docs/sample/copyscript/copy_proprietary_softwares.sh -f $PKGS_DIR
