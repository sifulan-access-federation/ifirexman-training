# Google Directory Integration

## Overview

This tutorial provides step-by-step instructions on how to integrate Google Directory with the Shibboleth IdP.

You are only required to follow this tutorial if you intend on using Google Directory as the backend authenticator for an IdP.

## Prerequisites

You need to have the following setup before you can proceed with this tutorial:

- A domain to be used to create a sub-domain for the IdP. For example, `ifirexman.edu`.

## Acquiring Google Directory Metadata File

Below are the steps to integrate Google Directory with the IdP and acquire the `GoogleIDPMetadata.xml` file required in the [Shibboleth IdP Installation and Configuration](idp.md#shibboleth-idp-installation-and-configuration) section:

1. Register the IdP's sub-domain (e.g. `idp.ifirexman.edu`) to your public DNS server and point it to the IP address `X.X.X.X`.

2. Visit the [Google Admin Console](https://admin.google.com) and login with your Google Directory's super administrator account.

3. At the Google Admin Dashboard, click the **Web and mobile apps** link under the **Apps** menu.

4. At the **Web and mobile apps** page, click the **Add app** -> **Add custom SAML app** link.

5. Set `iFIRExMAN Proxy` as the **App name**. Then, click the **Continue** button.

6. Click the **DOWNLOAD METADATA** button to download the Google Directory IdP metadata file. Save the file as `GoogleIDPMetadata.xml`. Then, click the **Continue** button.

7. Here, you need to set the following values:

    - **ACS URL**. Example: `https://idp.ifirexman.edu/idp/profile/Authn/SAML2/POST/SSO`

    - **Entity ID**. Example: `https://idp.ifirexman.edu/idp/shibboleth`

    - **Name ID format**. Set to `UNSPECIFIED`.

    - **Name ID**. Set to `Basic Information` -> `Primary Email`.

   Then, click the **Continue** button.

8. Set attribute mapping as follow:

   | Google Directory attributes | App attributes  |
   |---|---|
   | First name | givenName |
   | Last name | sn |
   | Primary email | mail |
   | Organizational unit path | memberOf |

   Then, click the **Finish** button.

9. You will be redirected to the **iFIRExMAN Proxy** page. Click the **User Access** tab and change the **Service status** to `ON for everyone`. Then, click the **Save** button.
