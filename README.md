# Weclome 
## Varun Khanna
Parallel Molecular Docking using PLANTS software
# Acknowledgement
I would like to thank authors of PLANTS molecular docking software for making [PLANTS](http://www.tcd.uni-konstanz.de/research/plants.php) free for academic use. Otherwise, this script would not have been possible.

# This script runs multiple independent instances of PLANTS by spliting the ligand file. 
## Can be used for virtual screning.
Steps to use the script. 
1. (Required) [downlaod it](http://www.tcd.uni-konstanz.de/plants_download/) if not already downloaded. Follow the instructions to install and make sure to change the name of the PLANTS executable from default name (e.g. PLANTS1.2_64bit) to PLANTS1.2 and put the executable in the path.
2. (Required) Download the script parallelPLANTS.sh and accessory perl sripts in the scripts folder.
3. (Optional) Download the example files.
4. Prepare the protein and ligand file for docking using your favourite tool. Save the prepared files in mol2 format.
5. Define the binding site on the protein using PLANTS. Read the PLANTS manual for details or run PLANTS in the following mode
```diff 
PLANTS1.2 --mode bind ligand.mol2 10 protein.mol2
```
6. (Required) Modify the line number 109 and 110 in the script to update the binding site center and bindind site radius produced from the command above
7. Done. Ready to roll!!.
8. Issue the following command to run virtual screening
```diff
bash parallelPLANTS.sh proteinFileName.mol2 ligandFileName.mol2 splits
```
