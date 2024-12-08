# Weclome 
## Varun Khanna
Parallel Molecular Docking using PLANTS software
# Acknowledgement
I would like to thank authors of PLANTS molecular docking software for making [PLANTS](PLANTS1.2) free for academic use.
 
 ## If you use the this script please cite
 [![DOI](https://zenodo.org/badge/140142034.svg)](https://zenodo.org/badge/latestdoi/140142034)
 
# This script runs multiple independent instances of PLANTS by spliting the multi-mol2 ligand file. 
## Can be used for Virtual Screening (VS).
Steps to use the script. 
1. (Required) [download PLANTS](PLANTS1.2) if not already downloaded. Copy PLANTS1.2 executable file into the PATH folder (for example /usr/local/bin). 
2. (Optional) Or append the following to ~/.bash_profile or ~/.bashrc files. Add <LOACATION to PLANTS executable> in the PATH. For example PLANTS_HOME = ~/<PATH TO PLANTS DIR/PLANTS1.2>. Then do export "PATH=$PATH:$PLANTS_HOME". Finally reload the shell by the command source ~/.bashrc.
3. (Required) Download the script parallelPLANTS.sh and accessory perl sripts in the scripts folder. Unzip the script folder using _unzip scripts.zip_ command. 
4. (Optional) Download the example files. Unzip example files.
5. Prepare the protein and ligand file for docking using your favourite tool. Save the prepared files in mol2 format.
6. Define the binding site on the protein using PLANTS. Read the PLANTS manual for details **OR** run PLANTS in the following mode. This will generate _'bindingsite.def'_ file which you will need later during docking and virtual screening.
```diff 
+ PLANTS1.2 --mode bind pdbligand.mol2 (native or PDB ligand) 10 protein.mol2 (your protein file name)
```
7. Done. Ready to roll!!.
8. Issue the following command to run docking or virtual screening. Substitute the proteinFileName and ligandFileName with your protein and ligand files. The ligand file can be multi-mol2 file containing multiple small molecules in a single file for VS. Where **splits** = number of parallel instances of PLANTS you would like to run. The parallelPLANTS.sh script recommends you a value based on the number of core you have. If you have a small number of ligands to screen say less than 1000 I recommend use splits = 1.
```diff
+ bash parallelPLANTS.sh proteinFileName.mol2 ligandFileName.mol2 splits bindingsite.def
```
9. If you have previously run the script and want to skip over some folders such as (file1, file3 and so no..). Follow the prompt to skip folders.

10. If instead you want to remove all previous folders and rerun VS, issue the following command where N = no. of folders to remove + 1. For example if you have 2 folders called (files1 and files2) created from previous run your N will be = 3 (2 + 1).
```diff
+ yes "" | head -nN | bash parallelPLANTS.sh proteinFileName.mol2 ligandFileName.mol2 splits bindingsite.def
```
