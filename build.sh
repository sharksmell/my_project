#!/bin/sh

cd build
WORK=`pwd`
echo $WORK

cd $WORK
source poky/oe-init-build-env


CONFIG_PATH=${WORK}/build/conf/local.conf
SOC_TYPE=("r8a7795" "r8a7796" "r8a77965" "r8a77980" "r8a77970")
SOC_LIST=("H3" "M3" "M3N" "V3H" "V3M")
BOARD_LIST=("salvator-x" "h3ulcb" "m3ulcb" "m3nulcb" "ebisu" "eagle" "condor" "v3hsk" "v3msk")
PROP_LIST=("bsp" "gfx-only" "mmp")

#default sel
board_sel="salvator-x"
prop_sel="bsp"
soc_sel="H3"
soc_type="r8a7795"

function select_prop (){
        i=1
        number=1
        for prop in ${PROP_LIST[@]}
        do
         echo '('$i')'$prop
         i=$(($i+1))
        done

        read -p "Please select your Proprietary: " number
	if [ ! -n "$number" ]; then
	 echo -e "\nYou have not input a word!"
	 exit 1
	elif [ $number -ge $i ]; then
	 echo -e "\nError selection!"
	 exit 1
        else
         echo "Your selected board is: ${PROP_LIST[$number-1]}"
        fi
        prop_sel=${PROP_LIST[$number-1]}
}

function select_board (){
	i=1
	number=1
	for board in ${BOARD_LIST[@]}
	do
	 echo '('$i')'$board
	 i=$(($i+1))
	done

	read -p "Please select your Board: " number
	if [ ! -n "$number" ]; then
	 echo -e "\nYou have not input a word!"
	 exit 1
	elif [ $number -ge $i ]; then
	 echo -e "\nError selection!"
	 exit 1
	else
         echo "Your selected board is: ${BOARD_LIST[$number-1]}"
	fi
	board_sel=${BOARD_LIST[$number-1]}
}

function select_soc (){
	i=1
	number=1
	for soc in ${SOC_LIST[@]}
	do
	 echo '('$i')'$soc
	 i=$(($i+1))
	done

	read -p "Please select your SoC: " number
	echo -e "\n"

	if [ ! -n "$number" ]; then
	 echo -e "\nYou have not input a word!"
	 exit 1
	elif [ $number -ge $i ]; then
	 echo -e "\nError selection!"
	 exit 1
	else
	 echo "Your selected SoC is: ${SOC_LIST[$number-1]} - ${SOC_TYPE[$number-1]}"
	fi
	
	soc_type_sel=${SOC_TYPE[$number-1]}
	soc_sel=${SOC_LIST[$number-1]}
}
TMP_DIR=$WORK/build/tmp
function modify_config () {
  #check if TMPDIR have changed
  SAVED_TMPPATH=$(sed -n '/tmp/p' $TMP_DIR/saved_tmpdir | sed 's/[ \t]*//g')
  if [ "$SAVED_TMPPATH" != "$TMP_DIR" ]; then
	echo -e "\nThe TMPDIR has changed location!"
	#`sed -n '/tmp/p' $TMP_DIR/saved_tmpdir
	sed -i "s|^.*$|$TMP_DIR|g" $TMP_DIR/saved_tmpdir
	cat $TMP_DIR/saved_tmpdir
	echo -e "\nThe TMPDIR have changed."
  fi
  if [ "$soc_sel" == "V3M" ] || [ "$soc_sel" == "V3H" ]; then
	echo "R-Car V3 series, use ADAS config."
	# R-Car Gen3 ADAS boards
	CONFIG_ORG=$WORK/meta-rcar/meta-rcar-gen3-adas/docs/sample/conf/$board_sel*/poky-gcc/bsp 
	test ! -e $CONFIG_ORG && echo "The CONFIG PATH $CONFIG_ORG DO NOT exist" && exit 0
	cp -v  $CONFIG_ORG/*.conf  ./conf/.
	#For change source directory
	if [ "$SAVED_TMPPATH" != "$TMP_DIR" ]; then
		sed  -i '/meta-rcar-gen3-adas/d' ./conf/bblayers.conf
	fi
	#Add layer meta-rcar
	bitbake-layers add-layer ../meta-rcar/meta-rcar-gen3-adas
  else
	# R-Car Gen3 salvator boards
	#cp $WORK/meta-renesas/meta-rcar-gen3/docs/sample/conf/salvator-x/poky-gcc/bsp/*.conf ./conf/.
	#cp $WORK/meta-renesas/meta-rcar-gen3/docs/sample/conf/salvator-x/poky-gcc/gfx-only/*.conf ./conf/.
	#cp $WORK/meta-renesas/meta-rcar-gen3/docs/sample/conf/salvator-x/poky-gcc/mmp//*.conf ./conf/.
	CONFIG_ORG=$WORK/meta-renesas/meta-rcar-gen3/docs/sample/conf/$board_sel*/poky-gcc/$prop_sel

	test ! -e $CONFIG_ORG && echo "The CONFIG PATH $CONFIG_ORG DO NOT exist" && exit 0
	cp -v  $CONFIG_ORG/*.conf  ./conf/.

	cd $WORK/build
	cp -v conf/local-wayland.conf conf/local.conf

	rp="SOC_FAMILY = \"${soc_type_sel}\""
	echo $rp
	sed -i '/#SOC_FAMILY.*/d' $CONFIG_PATH
	sed -i "s/SOC_FAMILY.*/$rp/g" $CONFIG_PATH
	echo "You have changed the SOC_FAMILY" ; grep -rn 'SOC_FAMILY' $CONFIG_PATH

  fi
}

# MAIN FUNCTION
select_board
echo "Done, $board_sel" && echo -e "\n"
select_prop
echo "Done, $prop_sel" && echo -e "\n"
select_soc
echo "Done, $soc_sel" && echo -e "\n"
modify_config
echo "Done, config modified."


read -t 10 -p "Are you sure you want to start bitbake?(yes or no)" Arg

case $Arg in 
Y|y|YES|yes)
 break;;
N|n|NO|no)
 echo "Cancel the bibtbake, exit."
 exit;;
"")
 break;;
esac
# R-Car Gen3 boards
echo "Start the bitbake task..." && echo -e "\n"

if [ "$soc_sel" == "V3M" ] || [ "$soc_sel" == "V3H" ]; then

	bitbake core-image-minimal
	bitbake core-image-minimal -c populate_sdk
else
	bitbake core-image-weston
	bitbake core-image-weston -c populate_sdk
fi
