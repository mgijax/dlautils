#!/bin/sh
#
#  $Header$
#  $Name$
#
#  DLAJobStreamFunctions.sh
###########################################################################
#
#  Purpose:  This script provides shell script functions to any script that
#            executes it.
#
#  Usage:
#
#      . DLAJobStreamFunctions.sh
#
#  Env Vars:  None
#
#  Inputs:  See individual functions
#
#  Outputs:  See individual functions
#
#  Exit Codes:  See individual functions
#
#  Assumes:
#
#      - Bourne shell is being used.
#
#  Implementation:  See individual functions
#
#  Notes:  None
#
###########################################################################


###########################################################################
#
#  Function:  createArchive
#
#  Usage:  createArchive  archiveDir  sourceDir1  ...  sourceDirN
#
#          where
#              archiveDir is the directory where the archive file is to be
#                         created.
#              sourceDirs are the directories where the function will
#                         look for files to include in the archive.
#
#  Purpose:  Create an archive of all files in the given source directories
#            and any subdirectories.
#
#  Returns:
#
#      Nothing = Successful completion
#      1 = An error occurred
#
#  Assumes:  Nothing
#
#  Effects:
#
#      - Creates the archive directory if it does not already exist.
#      - Creates an archive file in the archive directory.
#
#  Throws:  Nothing
#
#  Notes:  None
#
###########################################################################
createArchive ()
{
    #
    #  Make sure the archive directory was passed to the function, along
    #  with at least one source directory to create the archive from.
    #
    if [ $# -lt 2 ]
    then
        echo "Usage:  createArchive  archiveDir  sourceDir(s)"
        exit 1
    fi

    #
    #  If the archive directory does not exist, it should be created.
    #
    ARC_DIR=$1
    shift

    if [ ! -d ${ARC_DIR} ]
    then
        mkdir ${ARC_DIR}
        if [ $? -ne 0 ]
        then
            echo "Cannot create archive directory: ${ARC_DIR}"
            exit 1
        fi
    fi

    #
    #  Get the date and time to use for archiving the files.
    #
    ARC_FILE=${ARC_DIR}/arc`date '+%Y%m%d.%H%M'`.jar

    #
    #  Archive the files.
    #
    LIST=`find $* -type f -print 2>/dev/null`
    if [ `echo ${LIST} | wc -l` -gt 0 ]
    then
        for FILE in `echo ${LIST}`
        do
            if [ -f ${ARC_FILE} ]
            then
                jar -uvfM ${ARC_FILE} ${FILE} >/dev/null 2>&1
            else
                jar -cvfM ${ARC_FILE} ${FILE} >/dev/null 2>&1
            fi
        done
    fi
}


###########################################################################
#
#  Name:  getConfigEnv
#
#  Usage:  getConfigEnv  [-e]
#
#          where
#              -e is an option to display all environment variables.
#
#  Purpose:  Write the basic configuration settings and the complete
#            list of environment variables (optional) to stdout.
#
#  Returns:
#
#      Nothing = Successful completion
#      1 = An error occurred
#
#  Assumes:  Nothing
#
#  Effects:  Nothing
#
#  Throws:  Nothing
#
#  Notes:  None
#
###########################################################################
getConfigEnv ()
{
    #
    #  Check for the environment option.
    #
    if [ $# -eq 1 -a "$1" = "-e" ]
    then
        ENV_OPT="YES"
    elif [ $# -eq 0 ]
    then
        ENV_OPT="NO"
    else
        echo "Usage:  getConfigEnv  [-e]"
        exit 1
    fi

    echo "============================================================"
    echo "Platform: `hostname`"
    echo "Job Stream: $0"

    if [ "${ENV_OPT}" = "YES" ]
    then
        echo "\n**** Environment Variables ****"
        env | pg | sort
    fi
    echo "============================================================"
}


###########################################################################
#
#  Name:  mailLog
#
#  Usage:  mailLog
#
#  Purpose:  Send the Process Summary Log and Curator Summary Log to any
#            recipients that have been defined to receive them.
#
#  Returns:
#
#      Nothing = Successful completion
#      1 = An error occurred
#
#  Assumes:  Nothing
#
#  Effects:  Nothing
#
#  Throws:  Nothing
#
#  Notes:  None
#
###########################################################################
mailLog ()
{
    #
    #  If any recipients have been defined for the Process Summary Log,
    #  mail it to them.
    #
    if [ "${MAIL_LOG_PROC}" != "" ]
    then
        for i in `echo ${MAIL_LOG_PROC} | sed 's/,/ /g'`
        do
            mailx -s "${MAIL_LOADNAME} - Process Summary Log" ${i} < ${LOG_PROC}
        done
    fi

    #
    #  If any recipients have been defined for the Curator Summary Log,
    #  mail it to them.
    #
    if [ "${MAIL_LOG_CUR}" != "" ]
    then
        for i in `echo ${MAIL_LOG_CUR} | sed 's/,/ /g'`
        do
            mailx -s "${MAIL_LOADNAME} - Curator Summary Log" ${i} < ${LOG_CUR}
        done
    fi
}


###########################################################################
#
#  Name:  startLog
#
#  Usage:  startLog  logFile1  logFile2  ...  logFileN
#
#          where
#              logFiles are the log files that need to be initialized
#                  for use with this job stream.
#
#  Purpose:  Clear the given log files and write a startup timestamp to
#            each one.
#
#  Returns:
#
#      Nothing = Successful completion
#      1 = An error occurred
#
#  Assumes:  Nothing
#
#  Effects:  Removes any prior contents of the given log files.
#
#  Throws:  Nothing
#
#  Notes:  None
#
###########################################################################
startLog ()
{
    #
    #  Make sure at least one log file was passed to the function.
    #
    if [ $# -eq 0 ]
    then
        echo "Usage:  startLog  logFile(s)" | tee -a ${LOG}
        exit 1
    fi

    while [ "$1" != "" ]
    do
        if [ ! -f $1 -o -w $1 ]
        then
            echo "Start Log: `date`" > $1
        else
            echo "Cannot write to log file: $1" | tee -a ${LOG}
            exit 1
        fi
        shift
    done
}


###########################################################################
#
#  Name:  stopLog
#
#  Usage:  stopLog  logFile1  logFile2  ...  logFileN
#
#          where
#              logFiles are the log files that need to be stopped.
#
#  Purpose:  Append a timestamp to signal the end of each of the given
#            log files.
#
#  Returns:
#
#      Nothing = Successful completion
#      1 = An error occurred
#
#  Assumes:  Nothing
#
#  Effects:  Nothing
#
#  Throws:  Nothing
#
#  Notes:  None
#
###########################################################################
stopLog ()
{
    #
    #  Make sure at least one log file was passed to the function.
    #
    if [ $# -eq 0 ]
    then
        echo "Usage:  stopLog  logFile(s)" | tee -a ${LOG}
        exit 1
    fi

    while [ "$1" != "" ]
    do
        if [ -w $1 ]
        then
            echo "\nStop Log: `date`" >> $1
        else
            echo "Cannot write to log file: $1" | tee -a ${LOG}
            exit 1
        fi
        shift
    done
}


###########################################################################
#
#  Name:  preload
#
#  Usage:  preload [ list of other dirs to archive ]
#
#  Purpose:  Runs createArchive, startLog, getConfigEnv and gets the next
#            available job stream key.
#
#  Returns:
#
#	Nothing = Successful completion
#	1 = An error occurred
#
#  Assumes:  Nothing
#
#  Effects:  Nothing
#
#  Throws:  Nothing
#
#  Notes:  None
#
###########################################################################
preload ()
{
    #
    #  Function that performs cleanup tasks for the job stream prior to
    #  termination.
    #
    #
    #  Archive the log and report files from the previous run.
    #
    if [ $# -gt 0 ]
    then
        createArchive ${ARCHIVEDIR} ${LOGDIR} ${RPTDIR} $* | tee -a ${LOG}
    else
	createArchive ${ARCHIVEDIR} ${LOGDIR} ${RPTDIR} | tee -a ${LOG}
    fi

    #
    #  Initialize the log files.
    #
    startLog ${LOG_PROC} ${LOG_DIAG} ${LOG_CUR} ${LOG_VAL} | tee -a ${LOG}

    #
    #  Write the configuration information to the log files.
    #
    getConfigEnv >> ${LOG_PROC}
    getConfigEnv -e >> ${LOG_DIAG}

    #
    #  Start a new job stream and get the job stream key.
    #
    echo "Start a new job stream" >> ${LOG_PROC}
    JOBKEY=`${JOBSTART_CSH} ${RADAR_DBSCHEMADIR} ${JOBSTREAM}`
    if [ $? -ne 0 ]
    then
        echo "Could not start a new job stream for this load" >> ${LOG_PROC}
        postload
        exit 1
    fi
    echo "JOBKEY=${JOBKEY}" >> ${LOG_PROC}
}


###########################################################################
#
#  Name:  postload
#
#  Usage:  postload
#
#  Purpose:  Ends the job stream and calls stopLog.
#
#  Returns:
#
#       Nothing = Successful completion
#       1 = An error occurred
#
#  Assumes:  Nothing
#
#  Effects:  Nothing
#
#  Throws:  Nothing
#
#  Notes:  None
#
###########################################################################
postload ()
{
    #
    #  End the job stream if a new job key was successfully obtained.
    #  The STAT variable will contain the return status.
    #
    if [ ${JOBKEY} -gt 0 ]
    then
	echo "End the job stream" >> ${LOG_PROC}
	${JOBEND_CSH} ${RADAR_DBSCHEMADIR} ${JOBKEY} ${STAT}
    fi

    #
    #  End the log files.
    #
    stopLog ${LOG_PROC} ${LOG_DIAG} ${LOG_CUR} ${LOG_VAL} | tee -a ${LOG}

    #
    #  Mail the logs to the support staff.
    #
    mailLog | tee -a ${LOG}
}
###########################################################################
#
#  Name:  cleanDir
#
#  Usage: clean dir1 ... dirN
#
#  Purpose: removes all files and directories in each dir on the 
#           command line
#  Returns:
#
#       Nothing = Successful completion
#       1 = An error occurred
#
#  Assumes:  Nothing
#
#  Effects:  Nothing
#
#  Throws:  Nothing
#
#  Notes:  None
#
###########################################################################
cleanDir ()
{
    for dir in $*
    do
	if [ -d ${dir} ]
	then
  	    rm -rf ${dir}/*	
	fi
    done
}

#  $Log$
#  Revision 1.3  2004/10/19 16:26:58  sc
#  added param to preload and new function cleanDir
#
#  Revision 1.2  2004/06/30 18:16:42  dbm
#  Added MAIL_LOADNAME for mailLog and call mailLog from postload
#
#  Revision 1.1  2004/06/16 15:38:37  dbm
#  New
#
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
##########################################################################
