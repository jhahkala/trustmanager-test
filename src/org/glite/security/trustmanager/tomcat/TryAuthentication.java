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

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.security.Principal;
import java.security.cert.TrustAnchor;
import java.security.cert.X509Certificate;
import java.util.Arrays;
import java.util.Iterator;
import java.util.List;

import javax.net.ssl.SSLSession;
import javax.net.ssl.SSLSocket;
import javax.net.ssl.SSLSocketFactory;
import javax.net.ssl.X509KeyManager;

import org.apache.log4j.ConsoleAppender;
import org.apache.log4j.Layout;
import org.apache.log4j.Level;
import org.apache.log4j.Logger;
import org.apache.log4j.PatternLayout;
import org.glite.security.SecurityContext;
import org.glite.security.trustmanager.ContextWrapper;
import org.glite.security.util.CaseInsensitiveProperties;
import org.glite.security.util.DNHandler;

/**
 * A test client to test and give an example of the java authentication system usage.
 * 
 * @author Joni Hahkala <joni.hahkala@cern.ch> Created on April 15, 2003, 5:40 PM
 */
public class TryAuthentication implements org.bouncycastle.openssl.PasswordFinder {
	/** Creates a new instance of TestAuthentication. */
	public TryAuthentication() {
	    //
	}

	/**
	 * A helper method to read the password.
	 * 
	 * @return The password
	 */
	public char[] getPassword() {
		BufferedReader reader = new BufferedReader(new InputStreamReader(System.in));

		String password;

		try {
			password = reader.readLine();
		} catch (IOException e) {
			System.out.println("Error while reading password, error was: " + e.getMessage());

			return null;
		}

		return password.toCharArray();
	}

	/**
	 * @param args the command line arguments
	 */
	@SuppressWarnings("null")
    public static void main(final String[] args) {
		Layout lay = new PatternLayout("%d{ISO8601} %-5p [%t] %c{2} %x - %m%n");

		// output to console
		// BasicConfigurator.configure(new ConsoleAppender(lay));
		// disable the debug messages in this package by default
		Logger parent = Logger.getLogger("org.glite.security");
		parent.setLevel(Level.WARN);
		parent.addAppender(new ConsoleAppender(lay));

		Logger util = Logger.getLogger("org.glite.security.util");
		util.setLevel(Level.WARN);

		SSLSocket socket = null;
		String server = null;
		String path = null;
		int port = 0;

		if (args.length < 2) {
			System.out.println("Not enought arguments given ");
			System.out
					.println("Usage: java org.glite.security.trustamanager.tomcat.TestAuthentication server port [path]");
			System.exit(-1);
		} else {
			server = args[0];
			port = Integer.parseInt(args[1]);

			if (args.length >= 3) {
				path = args[2];
			}
		}

		System.out.println("Connecting server " + server + " port " + port + " using SSL");

		CaseInsensitiveProperties props = new CaseInsensitiveProperties(System.getProperties());

		System.out.println("\nThe java environment variables are:");
		System.out.println(props);
		try {
			ContextWrapper context = new ContextWrapper(props);

			// ******************** The credential info for the client
			// ************************************
			X509KeyManager manager = context.getKeyManager();

			String[] aliases = manager.getClientAliases("RSA", null);

			if ((aliases == null) || (aliases.length == 0)) {
				System.out.println("\nThe user credentials loading failed");
				System.exit(1);
			}

			X509Certificate[] chain = manager.getCertificateChain(aliases[0]);

			System.out.println("\nThe user credentials cert chain contains the certificates:");

			int i;

			for (i = 0; i < chain.length; i++) {
				System.out.println(DNHandler.getSubject(chain[i]));
			}

			try {
				if (context.trustManager != null) {
					context.trustManager.checkClientTrusted(chain, null);
				} else {
					context.m_trustmanager.checkClientTrusted(chain, null);
				}
			} catch (Exception e) {
				System.out.println("Warning the user credentials would not be accepted in this machine, reason: "
						+ e.getMessage());
				e.printStackTrace(System.out);
			}

			/*
			 * VOMSExtension voms = VOMSExtension.fromCert(chain[0]); if (voms != null) { System.out.println("\nThe
			 * default VOMS credentials of the certificate are:"); System.out.println(voms);
			 * System.out.println("\nThe VO is " + voms.getDefaultVOMSInfo().getVO()); } else {
			 * System.out.println("\nThe client cert chain does not contain a VOMS credentials"); }
			 */
			SecurityContext.clearCurrentContext();

			// ******************** The CA info for the client
			// ************************************
			if (context.trustAnchors == null && context.trustManager != null) {
				System.out.println("\nError, no CA certificates could be found from: "
						+ props.getProperty(ContextWrapper.CA_FILES, ContextWrapper.CA_FILES_DEFAULT));

				// return;
			} else {

				if (context.trustAnchors != null) {
					Iterator anchors = context.trustAnchors.iterator();

					System.out.println("\nThe CAs this client accepts are:");

					while (anchors.hasNext()) {
						System.out.println(((TrustAnchor) anchors.next()).getTrustedCert().getSubjectDN().toString());
					}

					// ******************** The CRL info for the client
					// ************************************
					if (context.crls == null) {
						System.out.println("\nWarning, no CRLs could be found from: "
								+ props.getProperty(ContextWrapper.CRL_FILES, "undefined"));
					} else {
						Iterator crls = context.crls.iterator();

						System.out.println("\nThe CRLs this client is aware of are:");

						while (crls.hasNext()) {
							System.out.println(((TrustAnchor) crls.next()).getTrustedCert().getSubjectDN().toString());
						}
					}
				} else {
					if (context.m_trustmanager != null) {
						System.out.println("\nThe CAs this client is aware of are:");

						X509Certificate[] certs = context.m_trustmanager.getAcceptedIssuers();
						for (int x = 0; x < certs.length; x++) {
							System.out.println(x + ": " + certs[x].getSubjectDN());
						}
					}
				}
			}
			SSLSocketFactory sslFactory = context.getSocketFactory();

			// ******************** The cipher info for the client
			// ************************************
			System.out.println("\nThe default cipher suites are:");

			String[] suites = sslFactory.getDefaultCipherSuites();

			for (i = 0; i < suites.length; i++) {
				System.out.println(suites[i]);
			}

			socket = (SSLSocket) sslFactory.createSocket(server, port);

			String[] protocols = socket.getSupportedProtocols();

			System.out.println("\nSupported protocols are:");
			for (i = 0; i < protocols.length; i++) {
				System.out.println("\n" + protocols[i]);
			}

			protocols = socket.getEnabledProtocols();

			System.out.println("\nEnabled protocols are:");
			for (i = 0; i < protocols.length; i++) {
				System.out.println("\n" + protocols[i]);
			}

			System.out.println("\nSLLContext protocol is: " + context.getContext().getProtocol());

			socket.startHandshake();

			SSLSession session = socket.getSession();

			System.out.println("\nCipher being used = " + session.getCipherSuite());

			javax.security.cert.X509Certificate[] serverChain = session.getPeerCertificateChain();

			System.out.println("\nThe server credentials cert chain contains the certificates:");

			for (i = 0; i < serverChain.length; i++) {
				System.out.println(serverChain[i].getSubjectDN().toString());
			}

			SecurityContext sc = SecurityContext.getCurrentContext();

			if (sc == null) {
				System.out.println("\nThe SSL handshake did not "
						+ "proceed to the point of server sending a certificate");
			} else {
				Principal[] principals = sc.getPeerCas();

				if (principals == null) {
					System.out.println("\nDid not receive any CA names for handshake");
				} else {
					System.out.println("\nServer accepts certificates signed by:");

					for (int n = 0; n < principals.length; n++) {
						System.out.println(DNHandler.getDN(principals[n]));
					}
				}
			}

			System.out.println("\nHandshake succesful");

			connectPlain(socket, path);
		} catch (Exception e) {
			e.printStackTrace(System.out);
			System.out.println("\nSSL handshake failed, reason: " + e.getMessage());
			System.out.println("\nTrying to find more info...");

			try {
				SecurityContext sc = SecurityContext.getCurrentContext();

				if (sc == null) {
					System.out.println("\nDid SSL handshake did not proceed to the "
							+ "point of server sending a certificate");
				} else {
					X509Certificate[] unverifiedChain = sc.getUnverifiedCertChain();

					if (unverifiedChain == null) {
						System.out.println("\nDid not receive any cert chain for handshake");
					} else {
						System.out.println("\nServer sent cert chain:");

						for (int n = 0; n < unverifiedChain.length; n++) {
							System.out.println(DNHandler.getSubject(unverifiedChain[n]));
						}
					}

					Principal[] principals = sc.getPeerCas();

					if (principals == null) {
						System.out.println("\nDid not receive any CA names for handshake");
					} else {
						System.out.println("\nServer accepts certificates signed by:");

						for (int n = 0; n < principals.length; n++) {
							System.out.println(DNHandler.getDN(principals[n]));
						}
					}
				}

				SSLSession session = socket.getSession();
				System.out.println("\nCipher being used = " + session.getCipherSuite());

				javax.security.cert.X509Certificate[] serverChain = session.getPeerCertificateChain();

				System.out.println("\nThe server credentials cert chain contains the certificates:");

				for (int i = 0; i < serverChain.length; i++) {
					System.out.println(serverChain[i].getSubjectDN().toString());
				}
			} catch (Exception e2) {
				System.out.println("\nInfo finding failed, reason: " + e2.getMessage());
				e2.printStackTrace(System.out);
			}

			// }catch(Exception e){
			// System.out.println("Connection failed, reason: " +
			// e.getMessage());
			// e.printStackTrace(System.out);
			System.exit(1);
		}
	}

	/**
	 * A method to do the actual communication with the test servlet.
	 * 
	 * @param socket the socket to connect to
	 * @param path the path in the server to try to read
	 * @return wether the communicaiton succeeded or not
	 * @throws IOException in case of communication errors
	 */
	static boolean connectPlain(final SSLSocket socket, final String path) throws IOException {
		try {
			OutputStream out = socket.getOutputStream();

			String host = socket.getInetAddress().getCanonicalHostName();
			SSLSession session = socket.getSession();
			java.security.cert.Certificate[] array = session.getPeerCertificates();

			List list = Arrays.asList(array);

			Iterator iter = list.listIterator();

			while (iter.hasNext()) {
				System.out.println("server cert chain is " + iter.next());
			}

			System.out.println("Host: " + host);

			// out.write("GET /examples/servlet/ContextTestServlet
			// HTTP/1.1\n".getBytes());
			// out.write("GET /index.html HTTP/1.1\n".getBytes());
			if (path != null) {
				out.write(("GET " + path + " HTTP/1.1\n").getBytes());
			} else {
				out.write("GET /index.html HTTP/1.1\n".getBytes());
			}

			// out.write("GET-TEST /index.html HTTP/1.1\n".getBytes());
			out.write(("Host: " + host + "\n\n").getBytes());
			out.flush();

			// out.close();
			// ///////////////////////////////////////////////////////////
			// get path to class file from header
			BufferedReader in = new BufferedReader(new InputStreamReader(socket.getInputStream()));
			String buf;
			buf = in.readLine();

			while (buf != null) {
				System.out.println("> " + buf);

				if (!in.ready()) {
					break;
				}

				buf = in.readLine();
			}

			in.close();
		} catch (IOException e) {
			e.printStackTrace(System.out);
			throw e;
		}

		System.out.println("Success");

		return true;
	}
}
