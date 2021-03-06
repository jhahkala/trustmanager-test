#!/bin/sh

# Test connecting with a number of different certificates
# This assumes that the certificates were created with
# org.glite.security.test-utils

#config variables
#tomcat host and port
export HOST=`hostname -f`:8443
rpm -qa |grep tomcat5
RES=$?
if [ $RES = 0 ]; then
    export TOMCAT_SERVICE=tomcat5
else
    export TOMCAT_SERVICE=tomcat6
fi

export WEBAPPNAME=trustmanager-test
#end of config variables

SUCCESS=1
FAIL=0

function myexit() {

  if [ $1 -ne 0 ]; then
    echo " *** something went wrong *** "
    echo " *** test NOT passed *** "
    echo "Restoring original namespace files"
    cp -f $certdir/grid-security/certificates/*.namespaces /etc/grid-security/certificates/
    cp -f $certdir/grid-security/certificates/*.signing_policy /etc/grid-security/certificates/

    exit $1
  else
    echo ""
    echo "    === test PASSED === "
  fi
   
  exit 0
}

function myecho()
{
  echo "#trustmanager certificate tests# $1"
}

usage() {
 echo
 echo "Test different certificates against trustmanager"
 echo "This test assumes that you're using certificates"
 echo "by org.glite.security.test-utils"
 echo "Usage:"
 echo "======"
 echo "certificate-tests.sh --certdir <directory for test-utils certs>"
 echo ""
}

function test_cert() {
 KEY=$1
 CERT=$2
 OUTCOME=$3

 if [ x"$4" != x ] ;  then 
  CA_CMD="--cacert $4"
 else
  CA_CMD=""
 fi


echo "curl -v -s -S --cert $CERT --key $KEY $CA_CMD --capath /etc/grid-security/certificates/ https://${HOST}/trustmanager-test/services/EchoService?method=getAttributes"
curl -v -s -S --cert $CERT --key $KEY $CA_CMD --capath /etc/grid-security/certificates/ https://${HOST}/trustmanager-test/services/EchoService?method=getAttributes |grep -v "failed to load .* from CURLOPT_CAPATH"|grep "Your final certificate subject is"
# echo "openssl s_client -key $KEY -cert $CERT -CApath /etc/grid-security/certificates $CA_CMD -connect $HOST < input.txt"
# openssl s_client -key $KEY -cert $CERT -CApath /etc/grid-security/certificates $CA_CMD -connect $HOST < input.txt >out
# openssl s_client -key $KEY -cert $CERT -CApath /etc/grid-security/certificates $CA_CMD -connect $HOST < input.txt |grep "(ok)" 
 RES=$?
 echo result was $RES

 if [ $OUTCOME -eq $SUCCESS ] ; then 
  if [ $RES -ne 0 ] ; then
   myecho "Error, testing with $CERT failed when it should have suceeded"
   myexit 1
  fi
 else
  echo expected error, result is $RES
  if [ $RES -eq 0 ] ; then
   myecho "Error, testing with $CERT succeeded when it should have failed"
   myexit 1
  fi
 fi
 
}

while [ $# -gt 0 ]
do
  echo $1
 case $1 in
 --certdir | -c ) certdir=$2
  shift
  ;;
 --help | -help | --h | -h ) usage
  exit 0
  ;;
 --* | -* ) echo "$0: invalid option $1" >&2
  usage
  exit 1
  ;;
 *) break
  ;;
 esac
 shift
done

if [ x"$certdir" == x ] ; then
 usage
 exit 1
fi

myecho "Testing with normal certificate"
test_cert $certdir/trusted-certs/trusted_client_nopass.priv $certdir/trusted-certs/trusted_client.cert $SUCCESS 
myecho "Test passed"
myecho "Testing with normal sha224 certificate"
test_cert $certdir/trusted-certs/trusted_clientsha224_nopass.priv $certdir/trusted-certs/trusted_clientsha224.cert $SUCCESS 
myecho "Test passed"
myecho "Testing with normal sha256 certificate"
test_cert $certdir/trusted-certs/trusted_clientsha256_nopass.priv $certdir/trusted-certs/trusted_clientsha256.cert $SUCCESS 
myecho "Test passed"
myecho "Testing with normal sha384 certificate"
test_cert $certdir/trusted-certs/trusted_clientsha384_nopass.priv $certdir/trusted-certs/trusted_clientsha384.cert $SUCCESS 
myecho "Test passed"
myecho "Testing with normal sha512 certificate"
test_cert $certdir/trusted-certs/trusted_clientsha512_nopass.priv $certdir/trusted-certs/trusted_clientsha512.cert $SUCCESS 
myecho "Test passed"
myecho "Testing with normal proxy certificate"
test_cert $certdir/trusted-certs/trusted_client.proxy_nopass.priv $certdir/trusted-certs/trusted_client.proxy.cert $SUCCESS $certdir/trusted-certs/trusted_client.cert
myecho "Test passed"
myecho "Testing with proxy proxy certificate"
test_cert $certdir/trusted-certs/trusted_client.proxy.proxy_nopass.priv $certdir/trusted-certs/trusted_client.proxy.proxy.cert $SUCCESS $certdir/trusted-certs/trusted_client_proxy_chain
myecho "Test passed"
#myecho "Testing with legacy proxy certificate"
#test_cert $certdir/trusted-certs/trusted_client.proxy.legacy  $certdir/trusted-certs/trusted_client.proxy.legacy $SUCCESS $certdir/trusted-certs/trusted_client.cert
#myecho "Test passed"
myecho "Testing with rfc proxy certificate"
test_cert $certdir/trusted-certs/trusted_client.proxy_rfc.grid_proxy  $certdir/trusted-certs/trusted_client.proxy_rfc.grid_proxy $SUCCESS $certdir/trusted-certs/trusted_client.cert
myecho "Test passed"
myecho "Testing with rfc proxy certificate with limited proxy length"
test_cert $certdir/trusted-certs/trusted_client.proxy_rfc_plen.proxy_rfc.proxy_rfc.grid_proxy  $certdir/trusted-certs/trusted_client.proxy_rfc_plen.proxy_rfc.proxy_rfc.grid_proxy $FAIL $certdir/trusted-certs/trusted_client_rfc_proxy_chain
myecho "Test passed"
myecho "Testing with a proxy certificate with false dn"
test_cert $certdir/trusted-certs/trusted_client.proxy_dnerror_nopass.priv $certdir/trusted-certs/trusted_client.proxy_dnerror.cert $FAIL $certdir/trusted-certs/trusted_client.cert
myecho "Test passed"
myecho "Testing with expired proxy certificate"
test_cert $certdir/trusted-certs/trusted_client.proxy_exp_nopass.priv $certdir/trusted-certs/trusted_client.proxy_exp.cert $FAIL $certdir/trusted-certs/trusted_client.cert
myecho "Test passed"
myecho "Testing with expired certificate"
test_cert $certdir/trusted-certs/trusted_client_exp_nopass.priv $certdir/trusted-certs/trusted_client_exp.cert $FAIL 
myecho "Test passed"
myecho "Testing with proxy of expired certificate"
test_cert $certdir/trusted-certs/trusted_client_exp.proxy_nopass.priv $certdir/trusted-certs/trusted_client_exp.proxy.cert $FAIL $certdir/trusted-certs/trusted_client_exp.cert
myecho "Test passed"
myecho "Testing with revoked certificate"
test_cert $certdir/trusted-certs/trusted_client_rev_nopass.priv $certdir/trusted-certs/trusted_client_rev.cert $FAIL 
myecho "Test passed"
myecho "Testing with proxy of revoked certificate"
test_cert $certdir/trusted-certs/trusted_client_rev.proxy_nopass.priv $certdir/trusted-certs/trusted_client_rev.proxy.cert $FAIL $certdir/trusted-certs/trusted_client_rev.cert
myecho "Test passed"
myecho "Testing with certificate from expired CA"
test_cert $certdir/expired-certs/expired_client_nopass.priv $certdir/expired-certs/expired_client.cert $FAIL 
myecho "Test passed"
myecho "Testing with proxy of certificate from expired CA"
test_cert $certdir/expired-certs/expired_client.proxy_nopass.priv $certdir/expired-certs/expired_client.proxy.cert $FAIL $certdir/expired-certs/expired_client.cert
myecho "Test passed"
myecho "Testing with untrusted certificate"
test_cert $certdir/fake-certs/fake_client_nopass.priv $certdir/fake-certs/fake_client.cert $FAIL
myecho "Test passed"
myecho "Testing with a not yet valid certificate"
test_cert $certdir/trusted-certs/trusted_clientfuture_nopass.priv $certdir/trusted-certs/trusted_clientfuture.cert  $FAIL 
myecho "Test passed"
myecho "Testing with a certificate that doesn't match the signing policy nor namespace"
test_cert $certdir/trusted-certs/trusted_clientbaddn_nopass.priv $certdir/trusted-certs/trusted_clientbaddn.cert  $FAIL 
myecho "Test passed"
myecho "Testing with a certificate which doesn't match the namespace, and whose CA uses / characters in the common name (bug #68981)"
test_cert $certdir/slash-certs/slash_clientbaddn_nopass.priv $certdir/slash-certs/slash_clientbaddn.cert  $FAIL
myecho "Test passed"


#namespace tests
myecho "Testing with a certificates whose subca sets the correct namespace (bug #64516)"
test_cert $certdir/subsubca-certs/subsubca_client_nopass.priv $certdir/subsubca-certs/subsubca_client.cert  $SUCCESS
myecho "Test passed"
myecho "Testing with a certificates whose subca sets the correct namespace, and certificate has a bad dn"
test_cert $certdir/subsubca-certs/subsubca_clientbaddn_nopass.priv $certdir/subsubca-certs/subsubca_clientbaddn.cert  $FAIL
myecho "Test passed"
myecho "Testing with a certificates whose subca sets the correct namespace, and the certificate contains the full CA path"
test_cert $certdir/subsubca-certs/subsubca_fullchainclient.proxy.grid_proxy $certdir/subsubca-certs/subsubca_fullchainclient.proxy.grid_proxy  $SUCCESS $certdir/subsubca-certs/subsubca_fullchainclient.proxy.grid_proxy
myecho "Test passed"

myecho "Copying over new namespace files"
cp -f $certdir/grid-security/certificates-rootwithpolicy/*.namespaces /etc/grid-security/certificates/
cp -f $certdir/grid-security/certificates-rootwithpolicy/*.signing_policy /etc/grid-security/certificates/

myecho "Restarting tomcat"
/sbin/service $TOMCAT_SERVICE restart
sleep 15

myecho "Confirming that tomcat came up properly"
wget --no-check-certificate --certificate  $certdir/trusted-certs/trusted_client.cert --private-key $certdir/trusted-certs/trusted_client_nopass.priv https://$HOST/$WEBAPPNAME/servlet/EchoSecurity -O /dev/null

if [ $? -ne 0 ] ; then 
 myecho "Tomcat didn't seem to come up properly. Please check tomcat logs"
 myexit 1
fi

myecho "Testing with a certificates whose root ca sets the correct namespace"
test_cert $certdir/subsubca-certs/subsubca_client_nopass.priv $certdir/subsubca-certs/subsubca_client.cert $SUCCESS
myecho "Test passed"
myecho "Testing with a certificates whose root ca sets the correct namespace, and certificate has a bad dn"
test_cert $certdir/subsubca-certs/subsubca_clientbaddn_nopass.priv $certdir/subsubca-certs/subsubca_clientbaddn.cert  $FAIL
myecho "Test passed"
myecho "Testing with a certificates whose root ca sets the correct namespace, and the certificate contains the full CA path"
test_cert $certdir/subsubca-certs/subsubca_fullchainclient.proxy.grid_proxy $certdir/subsubca-certs/subsubca_fullchainclient.proxy.grid_proxy  $SUCCESS $certdir/subsubca-certs/subsubca_fullchainclient.proxy.grid_proxy
myecho "Test passed"


myecho "Copying over new namespace files"
cp -f $certdir/grid-security/certificates-rootallowsubsubdeny/*.namespaces /etc/grid-security/certificates/
cp -f $certdir/grid-security/certificates-rootallowsubsubdeny/*.signing_policy /etc/grid-security/certificates/

myecho "Restarting tomcat"
/sbin/service $TOMCAT_SERVICE restart
sleep 15

myecho "Confirming that tomcat came up properly"
wget --no-check-certificate --certificate  $certdir/trusted-certs/trusted_client.cert --private-key $certdir/trusted-certs/trusted_client_nopass.priv https://$HOST/$WEBAPPNAME/servlet/EchoSecurity -O /dev/null

if [ $? -ne 0 ] ; then 
 myecho "Tomcat didn't seem to come up properly. Please check tomcat logs"
 myexit 1
fi


myecho "Testing with a certificates whose subsub ca denies the namespace"
test_cert $certdir/subsubca-certs/subsubca_client_nopass.priv $certdir/subsubca-certs/subsubca_client.cert  $FAIL
myecho "Test passed"
myecho "Testing with a certificates whose subsub ca denies the namespace, and certificate has a bad dn"
test_cert $certdir/subsubca-certs/subsubca_clientbaddn_nopass.priv $certdir/subsubca-certs/subsubca_clientbaddn.cert  $FAIL
myecho "Test passed"
myecho "Testing with a certificates whose subsub ca denies the namespace, and the certificate contains the full CA path"
test_cert $certdir/subsubca-certs/subsubca_fullchainclient.proxy.grid_proxy $certdir/subsubca-certs/subsubca_fullchainclient.proxy.grid_proxy  $FAIL $certdir/subsubca-certs/subsubca_fullchainclient.proxy.grid_proxy
myecho "Test passed"

myecho "Removing a namespace file for bug testing"
rm /etc/grid-security/certificates/2d0b98c8.namespaces

myecho "Restarting tomcat"
/sbin/service $TOMCAT_SERVICE restart
sleep 15

myecho "Confirming that tomcat came up properly"
wget --no-check-certificate --certificate  $certdir/trusted-certs/trusted_client.cert --private-key $certdir/trusted-certs/trusted_client_nopass.priv https://$HOST/$WEBAPPNAME/servlet/EchoSecurity -O /dev/null

if [ $? -ne 0 ] ; then 
 myecho "Tomcat didn't seem to come up properly. Please check tomcat logs"
 myexit 1
fi

myecho "Testing with a certificates whose CA uses slashes in the name (bug ##69795)"
test_cert $certdir/slash-certs/slash_client_slash_nopass.priv $certdir/slash-certs/slash_client_slash.cert  $SUCCESS
myecho "Test passed"

myecho "Restoring original namespace files"
cp -f $certdir/grid-security/certificates/*.namespaces /etc/grid-security/certificates/
cp -f $certdir/grid-security/certificates/*.signing_policy /etc/grid-security/certificates/

myecho "Restarting tomcat"
/sbin/service $TOMCAT_SERVICE restart
sleep 15

myecho "Confirming that tomcat came up properly"
wget --no-check-certificate --certificate  $certdir/trusted-certs/trusted_client.cert --private-key $certdir/trusted-certs/trusted_client_nopass.priv https://$HOST/$WEBAPPNAME/servlet/EchoSecurity -O /dev/null

if [ $? -ne 0 ] ; then 
 myecho "Tomcat didn't seem to come up properly. Please check tomcat logs"
 myexit 1
fi


echo ""
myecho "Please run the certificate-tests+1h.sh in an hour"

myexit 0
