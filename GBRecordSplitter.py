#!/usr/local/bin/python
#
#  $Header$
#  $Name$
#
#  GBRecordSplitter.py
###########################################################################
#
#  Purpose:
#
#      This script reads GenBank records from stdin and writes them to one
#      or more sequentially numbered output files. The count and/or type of
#      records that are written to each output file can be restricted using
#      the options described below.
#            
#  Usage:
#
#      GBRecordSplitter.py  [ -r RecordCount ]
#                           [ -d DivisionList ]
#                           [ -m ]
#                           OutputFile  FileNum
#
#      where
#
#          -r RecordCount sets the maximum number of records that are written
#                         to an output file before starting a new one. The
#                         default is 1,000,000,000.
#
#          -d DivisionList provides a comma-separated list of 3-character
#                          GenBank division abbreviations to look for. If this
#                          option is used, only records with one of the given
#                          division abbreviations will be included in the
#                          output file.
#
#          -m indicates that only mouse sequence records should be included
#             in the output file.
#
#          OutputFile is the path name for the output files. Each output file
#                     that is created will begin with this path name and
#                     have a sequential number appended to it.
#
#          FileNum is the number to be included as the first part of the
#                  suffix of each output file created by the split.
#
#  Env Vars:  None
#
#  Inputs:
#
#      stdin - GenBank record are read from stdin.
#
#  Outputs:
#
#      One or more output files containing the records from stdin. Each
#      output file will have the following naming convention:
#
#      OutputFile.FileNum.FileSeqNum
#
#      where
#
#          OutputFile is one of the arguments to the script.
#
#          FileNum is one of the arguments to the script, zero-filled on the
#                  left to make it 3 digits (e.g. "001" or "999").
#
#          FileSeqNum is a 3-digit sequential number that is zero-filled on
#                     the left (e.g. "001" or "999"). It is incremented for
#                     each additional output file created by the split.
#
#  Exit Codes:
#
#      0:  Successful completion
#      1:  An exception occurred
#
#  Assumes:  Nothing
#
#  Notes:  None
#
###########################################################################
#
#  Modification History:
#
#  Date        SE   Change Description
#  ----------  ---  -------------------------------------------------------
#
#  10/05/2004  DBM  Initial development
#
###########################################################################

import sys
import os
import string

#
#  Global Variables
#
usage = "Usage: " + sys.argv[0] + "\n" + \
        "       [ -r RecordCount ] [ -d DivisionList ] [ -m ]\n" + \
        "       OutputFile FileNum"

recordCount = 1000000000
divisionList = ""
mouseOnly = 0
outputFile = ""
fileNum = 0

#
#  Check all the arguments to the script.
#
while len(sys.argv) >= 3:
    if sys.argv[1] == "-r":
        if len(sys.argv) > 2:
            recordCount = string.atoi(sys.argv[2])
        else:
            print usage
            sys.exit(1)
        del sys.argv[1:3]
    elif sys.argv[1] == "-d":
        if len(sys.argv) > 2:
            divisionList = sys.argv[2]
        else:
            print usage
            sys.exit(1)
        del sys.argv[1:3]
    elif sys.argv[1] == "-m":
        mouseOnly = 1
        del sys.argv[1]
    else:
        break

if len(sys.argv) == 3:
    outputFile = sys.argv[1]
    fileNum = string.atoi(sys.argv[2])
else:
    print usage
    sys.exit(1)

#print "recordCount=" + str(recordCount)
#print "divisionList=" + divisionList
#print "mouseOnly=" + str(mouseOnly)
#print "outputFile=" + outputFile
#print "fileNum=" + str(fileNum)

#
#  If a division list was provided, split it into a list of abbreviations
#  to check against each input record.
#
if divisionList != "":
    divisionList = string.splitfields(divisionList,",")
else:
    divisionList = []

#
#  Initialize variables.
#
count = 0
fileSeqNum = 0
goodRecord = 0
badRecord = 0
recordLines = ""

#
#  Read the first line from stdin.
#
line = sys.stdin.readline()

#
#  Process each input line.
#
while line != "":

    #
    #  If it has been determined that the current record is a good record,
    #  include it in the output file.
    #
    if goodRecord:

        #
        #  If the current output file already has the maximum number of
        #  records, switch to a new output file.
        #
        if count == recordCount:

            #
            #  Close the current output file.
            #
            outFile.close()
            outFile = None

            #
            #  Increment the sequential number for the output file.
            #
            fileSeqNum = fileSeqNum + 1

            #
            #  Reset the record counter.
            #
            count = 0

        #
        #  Open the next output file if this is the first record to be
        #  written to it.
        #
        if count == 0:
            outFile = open(outputFile+"."+string.zfill(str(fileNum),3)+ \
                           "."+string.zfill(str(fileSeqNum+1),3),'w')

        #
        #  Write the lines from the current record that have already
        #  been read.
        #
        outFile.write(recordLines)

        #
        #  Write the remaining lines of the current record.  The last line
        #  contains a "//".
        #
        while 1:
            line = sys.stdin.readline()
            outFile.write(line)
            if line[0:2] == "//":
                break

        #
        #  Count a new record.
        #
        count = count + 1

        #
        #  Clear the buffer of lines for the current record.
        #
        recordLines = ""

        #
        #  Reset the record flags.
        #
        goodRecord = 0
        badRecord = 0

    #
    #  If it has been determined that the current record is a bad record,
    #  skip to the next record.
    #
    elif badRecord:

        #
        #  Look for the last line of the record that contains a "//".
        #
        while line[0:2] != "//":
            line = sys.stdin.readline()

        #
        #  Clear the buffer of lines for the current record.
        #
        recordLines = ""

        #
        #  Reset the record flags.
        #
        goodRecord = 0
        badRecord = 0

    #
    #  Keep checking the lines of the record until it can be determined if
    #  the record should be included in the output file or not.
    #
    else:

        #
        #  Save the current line of the record.
        #
        recordLines = recordLines + line

        #
        #  If the "LOCUS" line is found, check the division (if needed).
        #
        if line[0:5] == "LOCUS":

            #
            #  If the division needs to be checked and the division for the
            #  current record is not in the list, it is a bad record.
            #
            if len(divisionList) > 0:
                if divisionList.count(line[64:67]) == 0:
                    badRecord = 1
                    continue

        #
        #  If the "ORGANISM" line is found, check for mouse (if needed).
        #
        elif line[2:10] == "ORGANISM":

            #
            #  If mouse records are the only ones to keep, search each line
            #  of the ORGANISM section for the mouse indicator string.
            #
            if mouseOnly:
                while line[0:9] != "REFERENCE":
                    line = sys.stdin.readline()

                    #
                    #  Save the current line of the record.
                    #
                    recordLines = recordLines + line

                    #
                    #  The mouse string was found, so it is a good record.
                    #
                    if string.find(line,"Muridae; Murinae; Mus") >= 0:
                        goodRecord = 1
                        continue

                #
                #  The mouse string was not found, so it is a bad record.
                #
                badRecord = 1
                continue

            #
            #  It must be a good record if the mouse string doesn't need
            #  to be checked.
            #
            else:
                goodRecord = 1
                continue

    #
    #  Read the next line from stdin.
    #
    line = sys.stdin.readline()

#
#  Close the current output file.
#
if count > 0:
    outFile.close()

sys.exit(0)


#  $Log$
#
###########################################################################
#
# Warranty Disclaimer and Copyright Notice
#
#  THE JACKSON LABORATORY MAKES NO REPRESENTATION ABOUT THE SUITABILITY OR
#  ACCURACY OF THIS SOFTWARE OR DATA FOR ANY PURPOSE, AND MAKES NO WARRANTIES,
#  EITHER EXPRESS OR IMPLIED, INCLUDING MERCHANTABILITY AND FITNESS FOR A
#  PARTICULAR PURPOSE OR THAT THE USE OF THIS SOFTWARE OR DATA WILL NOT
#  INFRINGE ANY THIRD PARTY PATENTS, COPYRIGHTS, TRADEMARKS, OR OTHER RIGHTS.
#  THE SOFTWARE AND DATA ARE PROVIDED "AS IS".
#
#  This software and data are provided to enhance knowledge and encourage
#  progress in the scientific community and are to be used only for research
#  and educational purposes.  Any reproduction or use for commercial purpose
#  is prohibited without the prior express written permission of The Jackson
#  Laboratory.
#
# Copyright \251 1996, 1999, 2002, 2004 by The Jackson Laboratory
#
# All Rights Reserved
#
###########################################################################
