# Program: fastaDupRemover.awk
# Purpose: Remove duplicate sequence records from a FASTA
#          formatted file saving the record with the greatest
#          version number
# Usage: 1) cat ${inputFile} | awk -f fastaDupRemover.awk -v DUPSfile=${DUP_SEQ_FILE} > ${outputFile}
#        OR
#        2) awk -f fastaDupRemover.awk -v DUPSfile=${DUP_SEQ_FILE} ${inputFile} > ${outputFile}
#        Note: Use 1) for inputFile > 2G
# Envvars: none
# Inputs: * 'inputFile' - a FASTA format file
#         * 'DUPSfile' - a file containing the seqids that are duplicated in 'inputFile'
# Outputs: 'outputFile' - the non-redundant version of 'inputFile'
# Exit Codes: 
# Assumes: DUP_SEQ_FILE exists

BEGIN {  # initialization, before reading the FASTA file
    # read the file of duplicated IDs.
    # initialize two hash tables keyed on the dup'ed IDs
    #   duped_IDs_version[id] holds the highest genbank version number
    #				seen so far for 'id'
    #   duped_IDs_text[id] holds the FASTA text of the highest version
    #				seen so far for 'id'
    while (1 == getline duped_ID < DUPSfile)
    {
	duped_IDs_version[ duped_ID] = 0
	duped_IDs_text   [ duped_ID] = ""
    }		/* end while */
    close(DUPSfile)

    FS = "|"
    DUPedState = 0	# =0 if we are not reading a dup'ed rcd
			# =1 if we are reading a dup'ed rcd & its version
			#     is the latest so far (so we should save its text)
			# =2 if we are reading a dup'ed rcd, but it's not
			#     the latest version
} # end BEGIN

{	# process each line in the input file
    if (substr($0,1,1) == ">") # have a line like:
    {	    #>gi|2641960|gb|AB004255.1|AB004255 Mus musculus genomic DNA.
	split($4, IDFields, ".")
	ID = IDFields[1]
	version = IDFields[2]

	if (ID in duped_IDs_version)	# have a duped ID
	{
	    if (version > duped_IDs_version[ID]) # have newer version
	    {
		duped_IDs_version[ID] = version	# save version
		duped_IDs_text   [ID] = $0 "\n"	# save 1st line
		DUPedState = 1
	    }
	    else	# this is an earlier version
	    {
		DUPedState = 2
	    }
	}
	else		# not a duped ID
	{
	    print		# output this line
	    DUPedState = 0
	}
    }
    else # have a line of nucleotide letters
    {
	if (DUPedState == 0)	# in an undup'ed rcd
	{
	    print	# output this line
	}
	else if (DUPedState == 1)	# in a newer version of dup'ed rcd
	{				# concat line to duped_IDs_text
	    duped_IDs_text[ID] = duped_IDs_text[ID] $0 "\n"
	}
    }
} # end process each input line

END {	# dump out one copy of the dup'ed records after reading the FASTA file
    for (ID in duped_IDs_text)
    {
	printf("%s",duped_IDs_text[ID])
    }		/* end for */
}
