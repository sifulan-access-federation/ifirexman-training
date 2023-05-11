# Azure AD Integration

## Overview

This tutorial provides step-by-step instructions on how to integrate Azure AD with the Shibboleth IdP.

You are only required to follow this tutorial if you intend on using Azure AD as the backend authenticator for an IdP.

## Prerequisites

You need to have the following setup before you can proceed with this tutorial:

- A domain to be used to create a sub-domain for the IdP. For example, `ifirexman.edu`.

## Acquiring Azure AD Metadata File

Below are the steps to integrate Azure AD with the IdP and acquire the `azure.xml` file required in the [Shibboleth IdP Installation and Configuration](idp.md#shibboleth-idp-installation-and-configuration) section:

1. Register the IdP's sub-domain (e.g. `idp.ifirexman.edu`) to your public DNS server and point it to the IP address `X.X.X.X`.

2. Visit the [Azure Portal](https://portal.azure.com) and login with your Azure AD account.

3. At the **Azure Portal Dashboard**, click the **Enterprise applications** button under the **Azure services** menu.

4. At the **Enterprise applications** page, click the **New application** button.

5. Next, click the **Create your own application** button.

6. Set `iFIRExMAN Proxy` as the name of the application, and select the **Integrate any other application you don't find in the gallery (Non-gallery)** option. Then, click the **Create** button.

7. At the `iFIRExMAN Proxy` application page, click the **Set up single sign on** button under the **Getting Started** menu.

8. Under **Select single sign-on method**, select the **SAML** option.

9. Click the **Edit** link in the **Basic SAML Configuration** section.

10. Here, you need to set the following values:

    - **Identifier (Entity ID)**. Example: `https://idp.ifirexman.edu/idp/shibboleth`

    - **Reply URL (Assertion Consumer Service URL)**. Example: `https://idp.ifirexman.edu/idp/profile/Authn/SAML2/POST/SSO`

11. Delete the sample Entity ID value by clicking the trash icon next to the entry. Then, click the **Save** button at the top.

12. Within the **SAML Signing Certificate** section, click the **Download** button corresponding to the **Federation Metadata XML**. Save the file as `azure.xml`.

## Assigning Users/Groups to the Application

To assign users or groups to the `iFIRExMAN Proxy` application:

1. Click the **Users and groups** link under the **Manage** section found in the sidebar.

2. Click the **Add user/group** button in the **Users and groups** page.

3. Click the **None Selected** button and select all the users or groups you wish to assign to the application.

4. After doing so, click the **Select** button, then the **Assign** button.
