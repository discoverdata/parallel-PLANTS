#!/bin/bash 
# This scripts run the parallel multiple instances of PLANTS docking software requested by the user and collect all the results 
#========================================================================
#
#                FILE: parallelPLANTS.sh
#
#               USAGE: sh parallelPLANTS.sh
#
#         DESCRIPTION: This script first runs splitMol.pl script to split a big mol2 file into smaller files 
#		       and runs as many independent instances of PLANTS as number of splits.
#
#             OPTIONS: -----
#       REQURIREMENTS: please provide protein receptor and ligand file in the same folder from where you running the script.
#                BUGS: TODO: Skip all files simultaneously
#               NOTES: -----
#             AUTHORS: Varun Khanna, varun.khanna@flinders.edu.au
#        ORGANIZATION: Vaxine Pvt Ltd, FMC
#             VERSION: 1.0
#             CREATED: 10-July-2018
#            REVISION: 
#                CITE: If use this script please cite Dr Varun Khanna (https://github.com/discoverdata/parallel-PLANTS)
#========================================================================
set -e
#=======================Define Variables ==============
START=$(date +"%s")
workdir=$(pwd) 
SKIP=() # Define array
export LIGANDFILE=${2}
export LIGANDSPLITS=${3}
red=`tput setaf 1`
blue=`tput setaf 4`
reset=`tput sgr0`
#====================================================

# Check if PLANTS is installed  
if command -v PLANTS1.2 &> /dev/null; then
        echo "PLANTS1.2 found - OK"
	cores=$(nproc --all)
	echo "The optimum value for splits is ${red}$cores${reset} for your system. Use this value during virtual screening."
	echo "======================================================================================"
else
        echo "${red}Please install PLANTS software first${reset} and make sure PLANTS1.2 is in the path." 
	echo "Read step 1 in the repository README file (https://github.com/discoverdata/parallel-PLANTS) for more details."
        exit
fi
#=======================================


# Check for the arugments
if [[ ! $# -eq 4 ]]; then
        echo "Usage: bash parallelPLANTS.sh recName.mol2 (protein file name) ligands.mol2 (multi-mol2 ligand file name) splits (no. of splits for ligand file) bindingsite.def"
        exit
fi

function uniqDockedLigands {
# This function gets the input form sorted_ligandRanking file and 
# picks only unique ligands by ignoring any isomers of the ligand. 
cut -f2,3 $1 | sed 's/\(_[^_]*\).*\t/\1\t/' | sort -rk1 >tempUniq
awk 'prev!=$1{print}{prev=$1}' tempUniq | sort -rk2 >uniqueLigands.csv
uniq=$(cat uniqueLigands.csv |wc -l)
echo $uniq
}


# Check for the existance of receptor, ligand and bindingsite.def files
if [[ !  ( -f ${1}  && -s ${1} )  ]]; then
	echo "${red}Exiting.${reset} No such receptor file called ${red}${1}${reset} found. Something wrong with the file."
	exit
fi

if [[ !  ( -f ${2} && -s ${2} )  ]]; then
	echo "${red}Exiting.${reset} No such ligand file called ${red}${2}${reset} found. Something wrong with the file."
	exit
fi

if [[ !  ( -f ${4} && -s ${4} )  ]]; then
	echo "${red}Exiting.${reset} No such bindingsite.def file called ${red}${4}${reset} found. Something wrong with the file."
	exit
fi
cp scripts/*.pl . 
perl splitMol.pl 
for file in $(ls file*.mol2); 
do 
#echo ${file};
	dir=$(basename ${file} .mol2)
	if [ -d ${dir} ]; then
		echo "Directory${blue} ${dir} ${reset}exists"
		echo "Do you want me to remove it"
		read input
		if [[ ${input} =~ ^([yY][eE][sS]|[yY])$ || ${#input} -eq 0 ]]; then
			rm -rf ${dir}
			echo "Removed"
			sleep 1
			echo "Creating new directory ${dir}"
			mkdir ${dir}
				cp ${file} ${1} ${dir}
		else 
				echo "Skipping directory ${dir}"
				SKIP+=("${dir}") 

		fi
	else
		echo "Creating directory ${dir}"
		mkdir ${dir}
			cp ${file} ${1} ${dir}
	fi			

# Sample plantsconfig file
cat >${dir}/plantsconfig << EOF
scoring_function                chemplp
output_dir                      ${workdir}/${dir}/result
protein_file                    ${workdir}/${dir}/${1}
ligand_file                     ${workdir}/${dir}/${file}
write_protein_splitted          0
bindingsite_center              0.00 0.00 0.00
bindingsite_radius              0.00
write_multi_mol2                1
write_rescored_structures       1
cluster_structures              1
rescore_mode                    simplex
EOF


done

# Find the length of SKIP array
SKIP_LEN=${#SKIP[@]}
# Find the number of dir to run PLANTS on
DIR_NUM=$(ls -d file*/ | wc -l)
# Exit if SKIP array equals total number of dirs
if [[ ${SKIP_LEN} -eq ${DIR_NUM} ]]; then
	echo "${red}Nothing to do.${reset} Exiting"
	exit
fi

############ RUNNING MULTIPLE INSTANCES OF PLANTS###
for dir in $(ls -d file*/ | cut -f1 -d'/');
do
	# Check if the dir is to be skipped
	inarray=$(echo "${SKIP[@]}" | grep -x "${dir}" | wc -w )
	if [[ ${inarray} -eq 0 ]]; then
		# Update binding site info
		center=$(grep 'bindingsite_center' ${4})
		radius=$(grep 'bindingsite_radius' ${4})
		sed -i "s/bindingsite_center.*/${center}/" ${dir}/plantsconfig 
		sed -i "s/bindingsite_radius.*/${radius}/" ${dir}/plantsconfig 
		# Launch PLANTS	
		echo "Launching PLANTS for directory ${dir} ..."
		PLANTS1.2 --mode screen $workdir/${dir}/plantsconfig &
	fi
done
wait # Wait till background job is finished

############ ANALYSIS OF RESULTS ###################
# Check if the following files are present
if [[ -e ligandRanking.csv  || -e sorted_ligandRanking.csv || -e tempdocked_ligands.mol2 ]]; then
mkdir -p backup
mv *.csv temp* backup || true
fi

for dir in $(ls -d file*/);
do
	lines=$(cat ${workdir}/${dir}/result/bestranking.csv | wc -l)
	
	yes ${dir} | head -n ${lines} >${workdir}/${dir}/result/temp000
	paste ${workdir}/${dir}/result/temp000 ${workdir}/${dir}/result/bestranking.csv >${workdir}/${dir}/result/temp001 

	cat ${workdir}/${dir}/result/temp001 >>ligandRanking.csv
	rm ${workdir}/${dir}/result/temp*
	cat ${workdir}/${dir}/result/docked_ligands.mol2 >>tempdocked_ligands.mol2
done

cut -f1,2 -d',' ligandRanking.csv | sed 's/,/\t/' | sed '/LIGAND_ENTRY/d' |sed 's/\///'|sort -nk3 > sorted_ligandRanking.csv
sed -i -e '1iFOLDER	LIGAND_ENTRY	TOTAL_SCORE\' sorted_ligandRanking.csv
echo "To limit the result please enter the ${red} cutoff docking score (e.g -70)${reset} followed by a space 
OR number of ${red} top hits (e.g. 25) ${reset}"
echo "If mentioned, top hits are given priority over cutoff docking score. OR press ${green} ENTER ${reset} to continue"
read -er -a ANAME
cutoff=$( bc <<< "${ANAME[0]} - 1" )
top=$(( ${ANAME[1]} + 1 ))
if [[ -n ${ANAME[1]} ]]; then 
	cat sorted_ligandRanking.csv | head -n$top >tempcopy.csv
	mv tempcopy.csv sorted_ligandRanking.csv
	cut -f2 sorted_ligandRanking.csv >tempids
	grep -Fxb -f tempids tempdocked_ligands.mol2 | sed 's/:/\t/' >tempRawindexFile
elif [[ -n ${ANAME[0]} ]]; then
	cp sorted_ligandRanking.csv tempcopy.csv
	sed "/$cutoff/q" tempcopy.csv >sorted_ligandRanking.csv
	cut -f2 sorted_ligandRanking.csv >tempids
	grep -Fxb -f tempids tempdocked_ligands.mol2 | sed 's/:/\t/' >tempRawindexFile
else
	echo "You have not provided any filter criterion. Calculation of results may take some time. Please be patient... "
	cut -f2 sorted_ligandRanking.csv >tempids
	grep -Fxb -f tempids tempdocked_ligands.mol2 | sed 's/:/\t/' >tempRawindexFile
fi

echo "Collecting results."
while read TEMPID; 
do 
grep "$TEMPID" tempRawindexFile | cut -f1 >>tempindexFile 
done<"tempids"
export FROMFILE="tempdocked_ligands.mol2"
perl molExtractor.pl

uniqLigands=$(uniqDockedLigands sorted_ligandRanking.csv)
rm -f temp* 
mv "extractedFile" "resultsFile.mol2"
rm -f *.pl

echo "Done! The results are in ${red}sorted_ligandRanking.csv ${reset}file."
echo "There are ${red}${uniqLigands}${reset} ligands identified names are in ${red}uniqueLiagnds.csv${reset} file."
echo "The docked ligand are in ${red}resultsFile.mol2 ${reset}file."
#COMMENT
############ EXECUTION TIME #######################
END=$(date +"%s")
ELAPSED=$((${END} - ${START}))
echo "Time taken the script: $((${ELAPSED}/3600)) hours $((${ELAPSED}/60)) minutes $(($ELAPSED % 60)) seconds" 
