/*
 * Copyright (c) Members of the EGEE Collaboration. 2004. See
 * http://www.eu-egee.org/partners/ for details on the copyright holders.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy of
 * the License at
 * 
 * http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations under
 * the License.
 */

package org.glite.security.trustmanager.axis;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.security.cert.X509Certificate;

import org.glite.security.SecurityInfo;
import org.glite.security.SecurityInfoContainer;
import org.glite.security.util.CertUtil;
import org.glite.security.util.DNHandler;
import org.glite.security.util.axis.InitSecurityContext;


/**
 * Implements a security test and example web service.
 *
 * @author Joni Hahkala <joni.hahkala@cern.ch>
 */
public class EchoServiceSoapBindingImpl implements EchoService {
    /**
     * The main method of the test web application.
     *
     * @return a string that contains a lot of information that is digged from the user credentials etc.
     *
     * @throws java.rmi.RemoteException in case of problems returns an exception that
     * contains the information so far and the information of the error
     */
    @SuppressWarnings("deprecation")
    public String getAttributes() throws java.rmi.RemoteException {
        //System.out.println("Entering getAttributes");

        StringBuffer buf = new StringBuffer();

        buf.append("EchoSecurityService\n\n");

        buf.append("Hello, this is the EchoService web service.\n");
        buf.append("This web service prints out all the security related info available from the client.\n");

        // Store remote address.
        //        String remote = req.getRemoteAddr();
        //        sc.setProperty("org.glite.security.remote_address", remote);

        //        buf.append("<p>You are connecting from: " + remote);
        try {
            InitSecurityContext.init();

            SecurityInfo secInfo = SecurityInfoContainer.getSecurityInfo();
            X509Certificate[] cert = secInfo.getClientCertChain();

            buf.append("You're connecting from: " + secInfo.getRemoteAddr() + "\n");
            buf.append("The session ID for this connection is: " + secInfo.getSessionId() + "\n");
            buf.append("Your DN is: " + secInfo.getClientName() + "\n");
            buf.append("Issued by: " + secInfo.getIssuerName() + "\n");
            buf.append("You authenticated with a certificate " + DNHandler.getSubject(secInfo.getClientCertChain()[0]).getRFC2253() + "\n");
            buf.append("Your final certificate subject is: " + DNHandler.getSubject(cert[0]) + "\n");
            buf.append("You end entity identity is: " + CertUtil.getUserDN(secInfo.getClientCertChain()).getRFCDN());
            boolean proxy = false;
            try{
                DNHandler.getSubject(cert[0]).withoutLastCN(true);
                proxy = true;
            }catch (Exception e){
                proxy = false;
            }
            buf.append("Your end cert is: " + (proxy ? "proxy certificate" : "end-user certificate") + "\n\n");

            buf.append("Your cert is: \n");
            buf.append(secInfo.getClientCert().toString());
        } catch (Exception e) {
            buf.append("Error while handling the certificate chain:\n");

            StringWriter sw = new StringWriter();
            PrintWriter pw = new PrintWriter(sw);
            e.printStackTrace(pw);
            e.printStackTrace();
            buf.append(sw.toString());
            throw new java.rmi.RemoteException(buf.toString());
        }

        buf.append("\nFinished\n");

        return buf.toString();

        //        return "hello";
    }
}
