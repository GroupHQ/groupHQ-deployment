# Setting Up TLS Certificates For Local Development
For `edge-service`, an ingress manifest is already configured to use a TLS certificate for `localhost`.
The TLS certificate required by this manifest is given through a Kubernetes TLS Secret resource.
This secret resource is created by the `create-tls-secret.sh` script in this directory. The name of the secret is `edge-service-cert`
Before running this script, you must have a TLS certificate and private key file.

The easiest way to do this is to have `mkcert` installed on your computer. Then, run the following commands:
```bash
mkcert -install # Make sure to run this in a shell with admin privileges
mkcert localhost
```
This will create a certificate and private key file in the current directory, which are referenced by the `create-tls-secret.sh` script.
Note that the name `localhost` is important, as the ingress manifest is configured to use a certificate for `localhost`, and the script
expects the default names generated by `mkcert`.

After running the script, you can verify that the secret was created by running `kubectl get secret edge-service-cert`.

If you haven't already, start up your services with the `tilt up` command in the directory containing your `Tiltfile` (currently at `kubernetes/applications/development`).
You can then access the `edge-service` at `https://localhost` and you should see no security warnings.
To verify certificate details, you can usually click on the lock icon in the address bar of your browser.
Different browser may have different ways of displaying certificate details.

**IMPORTANT: The following instructions work by default for Chromium browsers (tested with Chrome & Microsoft Edge),
but not for Firefox. See the next section for instructions on integrating your Firefox browser with mkcert certificates.**

## Integrating Firefox
Unlike most Chromium browsers, Firefox relies only on its own certificate store. 
This means it maintains a separate list of trusted certificate authorities (CAs) and does not rely on the certificate 
store provided by the operating system. Consequently, Firefox won't trust the certificates generated by `mkcert`.

However, Firefox does allow users to import their own CAs. To do this, follow these steps:
1. Find where `mkcert` is installed in your computer. Here are some examples of where it could be:
   - On Linux: `~/.local/share/mkcert`
   - On Mac: `~/Library/Application Support/mkcert`
   - On Windows: `C:\Users\<YOUR USERNAME>\AppData\Local\mkcert`
2. In the directory where `mkcert` is installed, find the file `rootCA.pem`. This is the CA certificate that Firefox needs to trust.
3. Open Firefox settings (or preferences) and use the search tool to search for `Certificates`
4. Select the `View Certificates` option
5. Under the `Authorities` tab (likely to be selected by default already), click on the `Import` button
6. Select the `rootCA.pem` file you found in step 2
7. Confirm your choice if prompted

You should now be able to access `https://localhost` (or any host authorized by mkcert) in Firefox without any security warnings.

# Next Steps