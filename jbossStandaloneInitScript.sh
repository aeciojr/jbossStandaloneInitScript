#!/bin/bash
 
JAVA_HOME="/opt/java/jdk1.7.0_79"
PATH=$JAVA_HOME:$PATH
JBOSS_HOME=/opt/jboss
export JAVA_HOME PATH JBOSS_HOME
 
 
_Usage(){
   echo '
   /etc/init.d/gerenciadorJboss.sh {stop|start|status|restart|log}
    .                .                           .
    .                .                           .
    .                .                           .
    .                .                           ........................ Operacao
    .                .................................................... Script
    ..................................................................... Executa como superuser
'
}
 
_Start(){
   echo Starting..
   /usr/bin/sudo -u jboss $JBOSS_HOME/bin/standalone.sh -Djboss.bind.address=0.0.0.0 -Djboss.bind.address.management=0.0.0.0 &
}
 
_StopDefault(){
   echo Stopping..
   /usr/bin/sudo -u jboss $JBOSS_HOME/bin/jboss-cli.sh --connect --controller=127.0.0.1:8888 command=:shutdown
}
 
_Process(){ ps aux|grep -v grep |grep "java.*jboss"; }
 
_Status(){
   local RC=0
   ps aux|grep -v grep |grep "java.*jboss" || local RC=$?
   if [ $RC -eq 0 ]; then
      echo Jboss is running...
   else
      echo Jboss is NOT running...
   fi
   return $RC
}
 
_Kill(){
   local Signal=$1
   local RC=1
   local Retry=5
   local Count=1
   local Processo=$( _Status > /dev/null 2>&1; echo $? )
   while [ $Processo -eq 0 -a $Count -lt $Retry ]
   do
      local PID="$( _Process | awk '{ print $2 }'|tr -s '\n' ' ' )"
      kill $Signal "$PID"
      let Count++
      sleep 10
      local Processo=$( _Status > /dev/null 2>&1; echo $? )
   done
   local Processo=$( _Status > /dev/null 2>&1; echo $? )
   [[ $Processo -eq 0 ]] || local RC=0
   return $RC
}
 
_Stop(){
   local RC=0
   TimeWait=30
   _StopDefault
   sleep $TimeWait
   local Processo=$( _Status > /dev/null 2>&1; echo $? )
   if [ $Processo -eq 0 ]; then
      _Kill -15 || local RC=$?
   fi
   if [ $RC -ne 0 ]; then
      sleep $TimeWait
     _Kill -9
     local RC=0
   fi
   return $RC
}
 
_Restart(){
   local RC=0
   { _Stop || local RC=$?; } && { _Start || local RC=$?; }
   return $RC
}
 
_Log(){
   local LogFile=/opt/jboss/standalone/log/server.log
   tail -f $LogFile | awk '/INFO/ {print "\033[32m" $0 "\033[39m"} /ERROR/ {print "\033[31m" $0 "\033[39m"} /WARNING/ {print "\033[33m" $0 "\033[39m" }'
}
 
 
if [ $# -eq 1 ]
then
   Comando=$1
   case $Comando in
      status)  { _Status;      } ;;
      start)   { _Start;       } ;;
      stop)    { _Stop;        } ;;
      log)     { _Log;         } ;;
      restart) { _Restart;     } ;;
      *)       { _Usage;       } ;;
   esac
else
   _Usage
fi
