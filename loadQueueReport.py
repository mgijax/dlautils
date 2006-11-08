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

import sys 
import db
import string
import os


print "This report provides a list of files that are currently waiting to be"
print "processed by each job stream."

#
# Connect to the database.
#
dbServer = os.environ['RADAR_DBSERVER']
dbName = os.environ['RADAR_DBNAME']
dbUser = os.environ['RADAR_DBUSER']
dbPasswordFile = os.environ['RADAR_DBPASSWORDFILE']
dbPassword = string.strip(open(dbPasswordFile,'r').readline())
db.set_sqlLogin(dbUser, dbPassword, dbServer, dbName)

#
# Create a temp table that maps file types to job stream names.
#
cmd = []
cmd.append(
    'select distinct fm.fileType, js.jobStreamName ' + \
    'into #FileTypes ' + \
    'from APP_FilesMirrored fm, ' + \
         'APP_FilesProcessed fp, ' + \
         'APP_JobStream js ' + \
    'where fm._File_key = fp._File_key and ' + \
          'fp._JobStream_key = js._JobStream_key')

#
# Get all the files that are waiting to be process by each job stream.
# The outer join will make sure each job stream is listed, even if there
# are no files waiting.
#
cmd.append(
    'select ft.jobStreamName, fm.fileType, fm.fileName ' + \
    'from #FileTypes ft, APP_FilesMirrored fm ' + \
    'where ft.fileType *= fm.fileType and ' + \
          'not exists (select 1 ' + \
                      'from APP_FilesProcessed fp ' + \
                      'where fp._File_key = fm._File_key) ' + \
    'order by ft.jobStreamName, fm.fileName')

results = db.sql(cmd, 'auto')

lastJobStream = ""
for r in results[1]:
    jobStream = r['jobStreamName']
    fileType = r['fileType']
    fileName = r['fileName']

    #
    # Print the job stream name if this is the first record for a new
    # job stream.
    #
    if jobStream != lastJobStream:
        print "\n\nJob Stream: " + jobStream + "\n"
        lastJobStream = jobStream

    #
    # Print the file name and file type if they exist.  Otherwise, indicate
    # that there are no files queued for the current job stream.
    #
    if fileName != None:
        print fileName + " (" + fileType + ")"
    else:
        print "****  No Files Queued  ****"

sys.exit(0)
