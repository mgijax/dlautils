#!/bin/sh
#
#  $Header$
#  $Name$
#
#  DLAInstallFunctions.sh
###########################################################################
#
#  Purpose:  This script provides shell script functions to any script that
#            executes it.
#
#  Usage:
#
#      . DLAInstallFunctions.sh
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
#  Name:  installCompleted
#
#  Usage:  installCompleted
#
#  Purpose:  Print a completion message.
#
#  Returns:  Always 0
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
installCompleted ()
{
    echo "Installation Completed: `date`"
    exit 0
}


###########################################################################
#
#  Name:  installFailed
#
#  Usage:  installFailed
#
#  Purpose:  Print a completion message.
#
#  Returns:  Always 1
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
installFailed ()
{
    echo "Installation Failed: `date`"
    exit 1
}


###########################################################################
#
#  Name:  setupFileDirectory
#
#  Usage:  setupFileDirectory
#
#  Purpose:  Sets up the directory structure under the directory defined
#            by the $FILEDIR environment variable.
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
setupFileDirectory ()
{
    #
    #  Verify that the FILE directory has been defined.
    #
    if [ "${FILEDIR}" = "" ]
    then
        echo "Environment variable FILEDIR has not been defined."
        echo "It should be set to the directory where the archive, logs"
        echo "and reports directories are created."
        installFailed
    fi
  
    #
    #  Verify that the ARCHIVE directory has been defined.
    #
    if [ "${ARCHIVEDIR}" = "" ]
    then
        echo "Environment variable ARCHIVEDIR has not been defined."
        echo "It should be set to the directory where archive files are"
        echo "created."
        installFailed
    fi

    #
    #  Verify that the LOGS directory has been defined.
    #
    if [ "${LOGDIR}" = "" ]
    then
        echo "Environment variable LOGDIR has not been defined."
        echo "It should be set to the directory where log files are"
        echo "created."
        installFailed
    fi
  
    #
    #  Verify that the REPORTS directory has been defined.
    #
    if [ "${RPTDIR}" = "" ]
    then
        echo "Environment variable RPTDIR has not been defined."
        echo "It should be set to the directory where report files are"
        echo "created."
        installFailed
    fi

    #
    #  Verify that the OUTPUT directory has been defined.
    #
    if [ "${OUTPUTDIR}" = "" ]
    then
        echo "Environment variable OUTPUTDIR has not been defined."
        echo "It should be set to the directory where output files are"
        echo "created."
        installFailed
    fi
  
    #
    #  Make the required directories if they don't already exist and
    #  set the permissions.
    #
    for i in ${FILEDIR} ${ARCHIVEDIR} ${LOGDIR} ${RPTDIR} ${OUTPUTDIR}
    do
        if [ ! -d ${i} ]
        then
            mkdir -p ${i} >/dev/null 2>&1
            if [ $? -eq 0 ]
            then
                  echo "Directory created: ${i}"
            else
                  echo "Cannot create directory: ${i}"
                  installFailed
            fi
            chmod -f 755 ${i}
        else
            echo "Directory already exists: ${i}"
        fi
    done
  
    #
    #  If there is a HTML index file, copy it to the FILE directory.
    #
    if [ "${INDEXFILE}" != "" ]
    then
        if [ -f ${INDEXFILE} ]
        then
            echo "Copy ${INDEXFILE} to ${FILEDIR}"
            chmod -f 644 ${INDEXFILE}
            cp -p ${INDEXFILE} ${FILEDIR}
        fi
    fi
}


###########################################################################
#
#  Name:  setProductPermissions
#
#  Usage:  setProductPermissions
#
#  Purpose:  Sets the appropriate permissions in the product installation
#            directory.
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
setProductPermissions ()
{
    echo "Set permissions on product installation directories and files."
    if [ -d bin ]
    then
        chmod -f 750 bin
        find bin -name "*.sh" -exec chmod -f 750 {} \;
    fi
    if [ -d system_docs ]
    then
        chmod -f 750 system_docs
        find system_docs -type f -exec chmod -f 640 {} \;
    fi
    if [ -f build.xml ]
    then
        chmod -f 640 build.xml
    fi
}


###########################################################################
#
#  Name:  runAnt
#
#  Usage:  runAnt
#
#  Purpose:  Uses the ant utility to compile the Java source code, create
#            a jar file and generate the javadocs.
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
runAnt ()
{
    #
    #  Verify that the ant utility has been defined.
    #
    if [ "${ANT}" = "" ]
    then
        echo "Environment variable ANT has not been defined."
        echo "It should be set to path of the executable for the ant utility."
        installFailed
    fi

    #
    #  Compile the source code, create a jar file and generate javadocs.
    #
    if [ -x ${ANT} ]
    then
        echo "Compile the Java source code, create a jar file and generate javadocs."
        ${ANT} all
    else
        echo "Cannot execute ant utility: ${ANT}"
        installFailed
    fi
}


###########################################################################
#
#  Name:  setJavaPermissions
#
#  Usage:  setJavaPermissions
#
#  Purpose:  Sets the appropriate permissions for the Java directories and
#            files.
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
setJavaPermissions ()
{
    echo "Set permissions on Java directories and files."
    chmod -fR 750 classes
    chmod -fR 755 javadocs
    chmod -f 750 *.jar
    find classes -type d -exec chmod -f 750 {} \;
    find classes -name "*.class" -exec chmod -f 640 {} \;
    find javadocs -type d -exec chmod -f 755 {} \;
    find javadocs -type f -exec chmod -f 644 {} \;
    find java -type d -exec chmod -f 750 {} \;
    find java -name "*.java" -exec chmod -f 640 {} \;
}


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
##########################################################################
