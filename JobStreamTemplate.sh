#!/bin/sh
#
#  $Header$
#  $Name$
#
#  LOADNAME.sh
###########################################################################
#
#  Purpose:  This script controls the execution of the load.
#
#  Usage:
#
#      LOADNAME.sh
#
#  Env Vars:
#
#      See the configuration file
#
#  Inputs:
#
#      - Common configuration file (common.config.sh)
#      - Load configuration file (LOADNAME.config)
#
#  Outputs:
#
#      - An archive file
#      - Log files defined by the environment variables ${LOG_PROC},
#        ${LOG_DIAG}, ${LOG_CUR} and ${LOG_VAL}
#      - BCP files for each database table to be loaded
#      - Records written to the database tables
#      - Exceptions written to standard error
#      - Configuration and initialization errors are written to a log file
#        for the shell script
#
#  Exit Codes:
#
#      0:  Successful completion
#      1:  Fatal error occurred
#      2:  Non-fatal error occurred
#
#  Assumes:  Nothing
#
#  Implementation:  Description
#
#  Notes:  None
#
###########################################################################

#
#  Set up a log file for the shell script in case there is an error
#  during configuration and initialization.
#
cd `dirname $0`/..
LOG=`pwd`/LOADNAME.log
rm -f ${LOG}

#
#  Verify the argument(s) to the shell script.
#
if [ $# -ne 0 ]
then
    echo "Usage: $0" | tee -a ${LOG}
    exit 1
fi

#
#  Establish the configuration file names.
#
COMMON_CONFIG=`pwd`/common.config.sh
LOAD_CONFIG=`pwd`/LOADNAME.config

#
#  Make sure the configuration files are readable.
#
if [ ! -r ${COMMON_CONFIG} ]
then
    echo "Cannot read configuration file: ${COMMON_CONFIG}" | tee -a ${LOG}
    exit 1
fi
if [ ! -r ${LOAD_CONFIG} ]
then
    echo "Cannot read configuration file: ${LOAD_CONFIG}" | tee -a ${LOG}
    exit 1
fi

#
#  Source the common configuration file.
#
. ${COMMON_CONFIG}

#
#  Source the common DLA functions script.
#
if [ "${DLAJOBSTREAMFUNC}" != "" ]
then
    if [ -r ${DLAJOBSTREAMFUNC} ]
    then
        . ${DLAJOBSTREAMFUNC}
    else
        echo "Cannot source DLA functions script: ${DLAJOBSTREAMFUNC}"
        exit 1
    fi
else
    echo "Environment variable DLAJOBSTREAMFUNC has not been defined."
    exit 1
fi

#
#  Source the load configuration file.
#
. ${LOAD_CONFIG}

#
#  Function that performs cleanup tasks for the job stream prior to
#  termination.
#
shutDown ()
{
    #
    #  Perform post-load tasks.
    #
    postload

    #
    #  Mail the logs to the support staff.
    #
    mailLog "LOADNAME Load" | tee -a ${LOG}
}

#
#  Perform pre-load tasks.
#
preload

#
#  Run the data load.
#
echo "\n`date`" >> ${LOG_PROC}
echo "Run data load" >> ${LOG_PROC}
${JAVA} ${JAVARUNTIMEOPTS} -classpath ${CLASSPATH} \
        -DCONFIG=${COMMON_CONFIG},${LOAD_CONFIG} \
        -DJOBKEY=${JOBKEY} ${LOADNAME_APP}
STAT=$?
if [ ${STAT} -ne 0 ]
then
    echo "Data load failed.  Return status: ${STAT}" >> ${LOG_PROC}
    shutDown
    exit 1
fi
echo "Data load completed successfully" >> ${LOG_PROC}

shutDown

exit 0


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
