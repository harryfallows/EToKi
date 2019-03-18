#!/bin/bash
#set -e

#Written by Brian Bushnell
#Last updated May 21, 2018

#Fetches the latest taxonomy dump from ncbi, and formats it for use with BBTools
#For other BBTools programs that use taxonomy, you can set "taxpath=X" where X is the location of the files generated by this script.
#Setting "taxpath=X tree=auto" will cause the program to look for the tax tree at location "X/tree.taxtree.gz".

module load pigz

#Old method
#wget -nv ftp://ftp.ncbi.nih.gov/pub/taxonomy/accession2taxid/*.gz

wget -q -O - ftp://ftp.ncbi.nih.gov/pub/taxonomy/accession2taxid/dead_nucl.accession2taxid.gz | shrinkaccession.sh in=stdin.txt.gz out=shrunk.dead_nucl.accession2taxid.gz zl=9 t=4 &
wget -q -O - ftp://ftp.ncbi.nih.gov/pub/taxonomy/accession2taxid/dead_prot.accession2taxid.gz | shrinkaccession.sh in=stdin.txt.gz out=shrunk.dead_prot.accession2taxid.gz zl=9 t=6 &
wget -q -O - ftp://ftp.ncbi.nih.gov/pub/taxonomy/accession2taxid/dead_wgs.accession2taxid.gz | shrinkaccession.sh in=stdin.txt.gz out=shrunk.dead_wgs.accession2taxid.gz zl=9 t=6 &
wget -q -O - ftp://ftp.ncbi.nih.gov/pub/taxonomy/accession2taxid/nucl_est.accession2taxid.gz | shrinkaccession.sh in=stdin.txt.gz out=shrunk.nucl_est.accession2taxid.gz zl=9 t=6 &
wget -q -O - ftp://ftp.ncbi.nih.gov/pub/taxonomy/accession2taxid/nucl_gb.accession2taxid.gz | shrinkaccession.sh in=stdin.txt.gz out=shrunk.nucl_gb.accession2taxid.gz zl=9 t=8 &
wget -q -O - ftp://ftp.ncbi.nih.gov/pub/taxonomy/accession2taxid/nucl_gss.accession2taxid.gz | shrinkaccession.sh in=stdin.txt.gz out=shrunk.nucl_gss.accession2taxid.gz zl=9 t=4 &
wget -q -O - ftp://ftp.ncbi.nih.gov/pub/taxonomy/accession2taxid/nucl_wgs.accession2taxid.gz | shrinkaccession.sh in=stdin.txt.gz out=shrunk.nucl_wgs.accession2taxid.gz zl=9 t=10 &
wget -q -O - ftp://ftp.ncbi.nih.gov/pub/taxonomy/accession2taxid/pdb.accession2taxid.gz | shrinkaccession.sh in=stdin.txt.gz out=shrunk.pdb.accession2taxid.gz zl=9 t=4 &
wget -q -O - ftp://ftp.ncbi.nih.gov/pub/taxonomy/accession2taxid/prot.accession2taxid.gz | shrinkaccession.sh in=stdin.txt.gz out=shrunk.prot.accession2taxid.gz zl=9 t=10

if [[ $NERSC_HOST == genepool ]]; then
	#Via ascp (Not available on Denovo):
	module load aspera
	time ascp -T -k2 -l 1000m -i /usr/common/jgi/utilities/aspera/2.4.7/connect/etc/asperaweb_id_dsa.openssh anonftp@ftp.ncbi.nlm.nih.gov://pub/taxonomy/gi_taxid_nucl.dmp.gz .
	time ascp -T -k2 -l 1000m -i /usr/common/jgi/utilities/aspera/2.4.7/connect/etc/asperaweb_id_dsa.openssh anonftp@ftp.ncbi.nlm.nih.gov://pub/taxonomy/gi_taxid_prot.dmp.gz .
	time ascp -T -k2 -l 1000m -i /usr/common/jgi/utilities/aspera/2.4.7/connect/etc/asperaweb_id_dsa.openssh anonftp@ftp.ncbi.nlm.nih.gov://pub/taxonomy/taxdmp.zip .
else
	wget -nv ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdmp.zip &
	wget -nv ftp://ftp.ncbi.nih.gov/pub/taxonomy/gi_taxid_nucl.dmp.gz &
	wget -nv ftp://ftp.ncbi.nih.gov/pub/taxonomy/gi_taxid_prot.dmp.gz
fi

unzip -o taxdmp.zip
time taxtree.sh names.dmp nodes.dmp merged.dmp tree.taxtree.gz -Xmx16g 1>tt.o 2>&1 &
time gitable.sh gi_taxid_nucl.dmp.gz,gi_taxid_prot.dmp.gz gitable.int1d.gz -Xmx16g &
time analyzeaccession.sh shrunk.*.accession2taxid.gz out=patterns.txt

#ln -s ../taxsize.tsv.gz .
#time taxsize.sh in=/global/projectb/sandbox/gaag/bbtools/refseq/current/sorted.fa.gz out=taxsize.tsv.gz zl=9 ow tree=tree.taxtree.gz

#rm -f dead_*.accession2taxid.gz
#rm -f nucl_*.accession2taxid.gz
#rm -f pdb.accession2taxid.gz
#rm -f prot.accession2taxid.gz
rm -f gi_*.dmp.gz
rm -f *.dmp
rm -f gc.prt
rm -f readme.txt