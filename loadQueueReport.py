#!/usr/local/bin/python

#
#  loadQueueReport.py
###########################################################################
#
#  Purpose:
#
#      This script will generate a report of files that waiting to be
#      processed by each data load.  It looks for files that have been
#      logged in radar..APP_FilesMirrored that have not been logged in
#      radar..APP_FilesProcessed.
#
#  Usage:
#
#      loadQueueReport.py
#
#  Env Vars:  None
#
#  Inputs:  None
#
#  Outputs:
#
#      Report written to standard out
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
#  11/08/2006  DBM  Initial development
#
###########################################################################

import os
import sys 
import string
import mgi_utils
import db

db.setTrace()
db.setAutoTranslate(False)
db.setAutoTranslateBE(False)
dbPasswordFile = os.environ['MGD_DBPASSWORDFILE']
dbServer = os.environ['RADAR_DBSERVER']
dbName = os.environ['RADAR_DBNAME']
dbUser = os.environ['RADAR_DBUSER']
dbPasswordFile = os.environ['RADAR_DBPASSWORDFILE']

#
# Connect to the database.
#
dbPassword = string.strip(open(dbPasswordFile,'r').readline())
db.set_sqlLogin(dbUser, dbPassword, dbServer, dbName)

#
# Create a temp table that maps file types to job stream names.
#
cmd = []
cmd.append(
    'select distinct fm.fileType, js.jobStreamName ' + \
    'INTO TEMPORARY TABLE FileTypes ' + \
    'from APP_FilesMirrored fm, ' + \
         'APP_FilesProcessed fp, ' + \
         'APP_JobStream js ' + \
    'where fm._File_key = fp._File_key and ' + \
          'fp._JobStream_key = js._JobStream_key')

#
# Get a list of all job stream names that should appear in the report.
#
cmd.append(
    'select distinct jobStreamName ' + \
    'from FileTypes ' + \
    'order by jobStreamName')

#
# Get all the files that are waiting to be process by each job stream.
#
cmd.append(
    'select ft.jobStreamName, fm.fileType, fm.fileName, fileSize ' + \
    'from FileTypes ft, APP_FilesMirrored fm ' + \
    'where ft.fileType = fm.fileType and ' + \
          'not exists (select 1 ' + \
                      'from APP_FilesProcessed fp ' + \
                      'where fp._File_key = fm._File_key) ' + \
    'order by ft.jobStreamName, fm.fileType, fm.fileName')

results = db.sql(cmd, 'auto')

#
# Create a dictionary of all of the files that need to be processed.
# Each key is the job stream that will process the files and the value is
# a list of tuples. Each tuple contains the name, type and size of a file
# that needs to be processed by the corresponding job stream.
#
fileDict = {}
for r in results[2]:
    jobStream = r['jobStreamName']
    fileType = r['fileType']
    fileName = r['fileName']
    fileSize = r['fileSize']

    #
    # If there is already a list of files for this job stream, get the list
    # so a new file can be added to it. Otherwise, start a new list.
    #
    if fileDict.has_key(jobStream):
        list = fileDict[jobStream]
    else:
        list = []

    #
    # Append the new file to the list and update the dictionary.
    #
    list.append((fileType,fileName,fileSize))
    fileDict[jobStream] = list

#
# Print a heading for the report.
#
print "This report provides a list of files that are currently waiting"
print "to be processed by each job stream. The files in this report have"
print "been logged in radar..APP_FilesMirrored, but have not been logged"
print "in radar..APP_FilesProcessed."
print "\nDate: " + mgi_utils.date()
print "-"*80

#
# Create a new section in the report for each job stream.
#
for r in results[1]:
    jobStream = r['jobStreamName']

    #
    # Print the name of the current job stream.
    #
    print "\n\nJob Stream: " + jobStream + "\n"

    #
    # If there is at least one file in the dictionary for this job stream,
    # get each tuple of file information from the list and print an entry
    # in the report. Otherwise, indicate that no files are in the queue
    # for this job stream.
    #
    if fileDict.has_key(jobStream):
        for (fileType,fileName,fileSize) in fileDict[jobStream]:
            print fileName + " (" + fileType + ") (" + str(fileSize) + ")"
    else:
        print "****  No Files Queued  ****"

sys.exit(0)
