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

package org.glite.security.trustmanager.tomcat;

import java.io.IOException;
import java.io.PrintWriter;
import java.security.cert.X509Certificate;
import java.util.Iterator;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.glite.security.SecurityContext;
import org.glite.security.SecurityInfo;
import org.glite.security.SecurityInfoContainer;
import org.glite.security.util.DNHandler;
import org.glite.voms.VOMSValidator;

/**
 * @author Joni Hahkala <joni.hahkala@cern.ch> Created on Oct 11, 2004
 */
public class EchoSecurity extends HttpServlet {
	/**  */
    private static final long serialVersionUID = -1385589343495255907L;

    /**
	 * A test and example servlet to test the authentication system.
	 * 
	 * @param req The request received from the servelt container
	 * @param res The output for the response to the client
	 * @throws ServletException Thrown in general error situation
	 * @throws IOException Thrown if reading or writing the request or response fails
	 * @see javax.servlet.http.HttpServlet#doGet(javax.servlet.http.HttpServletRequest,
	 *      javax.servlet.http.HttpServletResponse)
	 */
	protected void doGet(final HttpServletRequest req, final HttpServletResponse res) throws ServletException,
			IOException {
		res.setContentType("text/html");

		PrintWriter out = res.getWriter();

		out.println("<html>");
		out.println("<head>");

		out.println("<title>EchoSecurity</title>");
		out.println("</head>");
		out.println("<body bgcolor=\"white\">");

		out.println("<h1>EchoSecurity</h1>");

		out.println("<p>Hello! This is the EchoSecurity servlet.");
		out.println("<p>This servlet prints out all the security related info available from the client.");

		SecurityContext sc = new SecurityContext();
		SecurityContext.setCurrentContext(sc);

		try {
			// Interpret the client's certificate.
			X509Certificate[] cert = (X509Certificate[]) req.getAttribute("javax.servlet.request.X509Certificate");

			/* Client certificate found. */
			sc.setClientCertChain(cert);

			// get and store the IP address of the other party
			String remote = req.getRemoteAddr();
			sc.setRemoteAddr(remote);

			// trigger the initialization of the certificate stuff in request.
			req.getAttribute("javax.servlet.request.key_size");
			// get the session id
			String sslId = (String) req.getAttribute("javax.servlet.request.ssl_session");
			sc.setSessionId(sslId);

			SecurityInfo secInfo = SecurityInfoContainer.getSecurityInfo();

			out.println("<p>You're connecting from: " + secInfo.getRemoteAddr() + "\n");
			out.println("<p>The session ID for this connection is: " + secInfo.getSessionId() + "\n");
			out.println("<p>Your DN is: " + secInfo.getClientName() + "\n");
			out.println("<p>Issued by: " + secInfo.getIssuerName() + "\n");
			out.println("<p>Your final certificate subject is: " + DNHandler.getSubject(cert[0]) + "\n");

			boolean proxy = false;
			try {
				DNHandler.getSubject(cert[0]).withoutLastCN(true);
				proxy = true;
			} catch (Exception e) {
				proxy = false;
			}
			out.println("<p>Your end cert is: " + (proxy ? "proxy certificate" : "end-user certificate") + "\n");

			List attribs = VOMSValidator.parse(secInfo.getClientCertChain());
			Iterator attribIter = attribs.iterator();

			if (attribs.isEmpty()) {
				out.println("<p>No valid attributes present! \n");
			}

			int i = 0;

			while (attribIter.hasNext()) {
				out.println("<p>Attribute(" + i++ + "): " + attribIter.next() + "\n");
			}

			out.println("<p>Your cert is: ");
			out.println(secInfo.getClientCert().toString());
		} catch (Exception e) {
			out.println("<p>Error while handling the certificate chain:");
			e.printStackTrace(out);
		}

		out.println("\n<p>Finished");
		out.println("</body>");
		out.println("</html>");
		out.close();
	}
}
