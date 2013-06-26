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

yum install yum-priorities yum-protectbase

rpm --import http://emisoft.web.cern.ch/emisoft/dist/EMI/2/RPM-GPG-KEY-emi
rpm -ivh http://emisoft.web.cern.ch/emisoft/dist/EMI/2/sl6/x86_64/base/emi-release-2.0.0-1.sl6.noarch.rpm

#get trustmanager 3.0.3
wget https://github.com/jhahkala/trustmanager/blob/gh-pages/packages/emi-trustmanager-3.1.5-1.sl6.noarch.rpm?raw=true

cd 
# Gotta make sure the EPEL repository is enabled!
#sed -i 's/\/EMI\/1\/sl/\/EMI\/2\/RC\/sl/g' /etc/yum.repos.d/emi1-base.repo
#sed -i 's/gpgcheck=1/gpgcheck=0/g' /etc/yum.repos.d/emi1-base.repo
#sed -i 's/\/EMI\/1\/sl/\/EMI\/2\/RC\/sl/g' /etc/yum.repos.d/emi1-third-party.repo
#sed -i 's/gpgcheck=1/gpgcheck=0/g' /etc/yum.repos.d/emi1-third-party.repo
#sed -i 's/\/EMI\/1\/sl/\/EMI\/2\/RC\/sl/g' /etc/yum.repos.d/emi1-updates.repo
#sed -i 's/gpgcheck=1/gpgcheck=0/g' /etc/yum.repos.d/emi1-updates.repo

yum install emi-trustmanager-3.1.5-1.sl6.noarch.rpm

install_list="emi-trustmanager-axis emi-trustmanager-tomcat 
emi-trustmanager-test glite-yaim-core fetch-crl ca-policy-egi-core tomcat5 
git xml-commons-apis emacs"

# emacs??
echo yum install -y $install_list

    yum install -y $install_list |tee yum.log; result=$?
    if [ $result -ne 0 ]
    then
        echo "\n \n ERROR installing $target \n \n";
	exit 1;
    else 
        echo "Installed $target with return code $result."
    fi


# yum install -y emi-trustmanager
# yum install -y emi-trustmanager-axis 
# yum install -y emi-trustmanager-tomcat 
# yum install -y emi-trustmanager-test 
# yum install -y glite-yaim-core 
# yum install -y fetch-crl 
# yum install -y ca-policy-egi-core 
# yum install -y tomcat5 
# yum install -y cvs 
# yum install -y xml-commons-apis 
# yum install -y emacs

cd ~
#cp /opt/glite/yaim/examples/siteinfo/site-info.def .

# config default with yaim 
echo "#" >site-info.def
echo y|/opt/glite/yaim/bin/yaim -r -s site-info.def -f config_secure_tomcat|tee yaim.log

# add override for server credential expiration check
cp /etc/tomcat6/server.xml /etc/tomcat6/server.xml.sed
cat /etc/tomcat6/server.xml.sed | sed "s/secure=\"true\"/secure=\"true\" internalOverrideExpirationCheck=\"true\"/" >/etc/tomcat6/server.xml

#update crls
/usr/sbin/fetch-crl

#clean up tomcat logs
/sbin/service tomcat6 stop
rm -f /var/log/tomcat6/*

# check out the test cert generation stuff and generate test certs
#export CVSROOT=":pserver:anonymous@glite.cvs.cern.ch:/cvs/glite"
#export CVS_RSH=ssh

git clone https://github.com/jhahkala/trustmanager-test.git
git clone https://github.com/jhahkala/test-certs.git
cd test-certs
bin/generate-test-certificates.sh --all --voms /root/certs
cd ~

cp /usr/share/java/trustmanager-test.war /var/lib/tomcat6/webapps

cd trustmanager-test/testsuite/tests
./test-setup.sh --certdir /root/certs/

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
sleep 15
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
