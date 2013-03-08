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

import java.net.URL;

import org.apache.axis.configuration.SimpleProvider;

/**
 * A simple web service client to call the test web application.
 * @author Joni Hahkala
 *
 */

public class CallEchoService {
    /**
     * The client program that contacts the test web application and prints out what the server responded.
     *
     * @param args the endpoint address of the web application to contact.
     */
    public static void main(final String[] args) {
        System.out.println(System.getProperties().toString());
        try {
            EchoServiceServiceLocator locator = new EchoServiceServiceLocator();
            EchoService service = locator.getEchoService(new URL(args[0]));
            System.out.println("calling webapp");
            System.out.println(service.getAttributes());
            System.out.println("finished calling webapp");
            
/*            for(int i = 0; i < 200; i++){
                System.out.println("interation: " + i);
                service.getAttributes();
            }
*/            
            SimpleProvider provider = SSLConfigSender.getTransportProvider(System.getProperties());
            locator = new EchoServiceServiceLocator(provider);
            service = locator.getEchoService(new URL(args[0]));
            System.out.println(service.getAttributes());
            
/*            for(int i = 0; i < 200; i++){
                System.out.println("interation2: " + i);
                service.getAttributes();
            }           
*/            
//            java.lang.Thread.sleep(10000000);
           
        } catch (Exception e) {
            e.printStackTrace(System.out);
            System.exit(1);
        }
    }
}
