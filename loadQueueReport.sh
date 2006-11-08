#!/bin/sh

cd `dirname $0`
LOG=/tmp/loadQueue.log
rm -f ${LOG}

. ./Configuration

${DLA_UTILS}/loadQueueReport.py > ${LOG}

if [ "${MAIL_LOG_PROC}" != "" ]
then
    mailx -s "Load Queue Report" ${MAIL_LOG_PROC} < ${LOG}
fi

exit 0
