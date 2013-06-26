#!/bin/bash

# Basic stuff

which sed
if [ $? -ne 0 ]
then
    echo "sed not found... exiting"
    exit 2;
fi

# setup repositories
yum install -y yum-conf-epel
cd /etc/yum.repos.d
# 
# Get rid of repos that might mess up stuff
# The concept of a "clean" SL5 does not make sense
# 
filelist="adobe.repo atrpms.repo dag.repo epel-testing.repo \
         sl-contrib.repo sl-debuginfo.repo sl-fastbugs.repo \
         sl-srpms.repo sl-testing.repo \
         glite-rip-3.* non-glite-rip-3.* \
         egi-trustanchors.repo internal.repo CERN-only.repo"
for xfile in $filelist 
do
  if [ -f $xfile ]
  then
      rm -f $xfile
  fi
done
wget http://repository.egi.eu/sw/production/cas/1/current/repo-files/EGI-trustanchors.repo


cd 
yum install -y yum-priorities yum-protectbase

rpm --import http://emisoft.web.cern.ch/emisoft/dist/EMI/2/RPM-GPG-KEY-emi
rpm -ivh http://emisoft.web.cern.ch/emisoft/dist/EMI/2/sl5/x86_64/base/emi-release-2.0.0-1.sl5.noarch.rpm

wget https://github.com/jhahkala/trustmanager/blob/gh-pages/packages/emi-trustmanager-3.1.5-1.sl5.noarch.rpm?raw=true

# Gotta make sure the EPEL repository is enabled!
#sed -i 's/\/EMI\/1\/sl/\/EMI\/2\/RC\/sl/g' /etc/yum.repos.d/emi1-base.repo
#sed -i 's/gpgcheck=1/gpgcheck=0/g' /etc/yum.repos.d/emi1-base.repo
#sed -i 's/\/EMI\/1\/sl/\/EMI\/2\/RC\/sl/g' /etc/yum.repos.d/emi1-third-party.repo
#sed -i 's/gpgcheck=1/gpgcheck=0/g' /etc/yum.repos.d/emi1-third-party.repo
#sed -i 's/\/EMI\/1\/sl/\/EMI\/2\/RC\/sl/g' /etc/yum.repos.d/emi1-updates.repo
#sed -i 's/gpgcheck=1/gpgcheck=0/g' /etc/yum.repos.d/emi1-updates.repo

yum install -y emi-trustmanager-3.1.5-1.sl6.noarch.rpm

CMD="yum install -y emi-trustmanager-axis emi-trustmanager-tomcat emi-trustmanager-test glite-yaim-core fetch-crl ca-policy-egi-core tomcat5 cvs xml-commons-apis emacs"
echo $CMD; $CMD
if [ $result -ne 0 ] ; then
    echo "\n \n ERROR installing packages \n \n";
    exit 1;
else 
    echo "Installed packages with return code $result."
fi

cd ~
#cp /opt/glite/yaim/examples/siteinfo/site-info.def .

# config default with yaim 
echo "#" >site-info.def
/opt/glite/yaim/bin/yaim -r -s site-info.def -f config_secure_tomcat

# add override for server credential expiration check
cp /etc/tomcat5/server.xml /etc/tomcat5/server.xml.sed
cat /etc/tomcat5/server.xml.sed | sed "s/secure=\"true\"/secure=\"true\" internalOverrideExpirationCheck=\"true\"/" >/etc/tomcat5/server.xml

#update crls
echo updating CRLs....
/usr/sbin/fetch-crl

#clean up tomcat logs
/sbin/service tomcat5 stop
rm -f /var/log/tomcat5/*

# check out the test cert generation stuff and generate test certs
#export CVSROOT=":pserver:anonymous@glite.cvs.cern.ch:/cvs/glite"
#export CVS_RSH=ssh

git clone https://github.com/jhahkala/test-certs.git
cd test-certs
bin/generate-test-certificates.sh --all --voms /root/certs
cd ~

cp /usr/share/java/trustmanager-test.war /var/lib/tomcat5/webapps

cd trustmanager-test/testsuite/tests
./test-setup.sh --certdir /root/certs/

/sbin/service tomcat5 start
sleep 15

echo "#run following commands:"
echo "#------------------------------------------------------"
echo cd ~/trustmanager-test/testsuite/tests
echo ./certificate-tests.sh --certdir /root/certs/
echo ./server-tests.sh --certdir /root/certs/
echo ./client-tests.sh --certdir /root/certs/

echo #set clock forward to make CRLs expire
echo "date --set='+70 minutes'"
echo ./certificate-tests+1h.sh --certdir /root/certs/
echo ./client-tests+1h.sh --certdir /root/certs/
cd ~/trustmanager-test/testsuite/tests
./certificate-tests.sh --certdir /root/certs/
RES=$?
if [ $RES -ne 0 ]; then
    echo Certificate tests failed
    exit 1
fi
./server-tests.sh --certdir /root/certs/
RES=$?
if [ $RES -ne 0 ]; then
    echo server tests failed
    exit 1
fi
./client-tests.sh --certdir /root/certs/
RES=$?
if [ $RES -ne 0 ]; then
    echo client tests failed
    exit 1
fi

echo #set clock forward to make CRLs expire
date --set='+70 minutes'
date --set='+70 minutes'
sleep 30
./certificate-tests+1h.sh --certdir /root/certs/
RES=$?
if [ $RES -ne 0 ]; then
    echo certificate +1h tests failed
    exit 1
fi
./client-tests+1h.sh --certdir /root/certs/
RES=$?
if [ $RES -ne 0 ]; then
    echo client +1h tests failed
    exit 1
fi

