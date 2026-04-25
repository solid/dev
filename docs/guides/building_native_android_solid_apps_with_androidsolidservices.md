# Building Native Android Solid Apps with AndroidSolidServices

[AndroidSolidServices (ASS)](https://github.com/pondersource/Android-Solid-Services) is an open-source project that brings Solid support to native Android development. It solves a core problem in the Android ecosystem: without it, every Solid-enabled app has to build its own authentication flow and token management from scratch, and users must log in separately to each app.

ASS acts as a **centralised Solid identity layer** on the device. Users authenticate once inside the ASS host app; any other app that integrates with ASS can then reuse that session without ever touching the user's credentials.

## The Two Libraries

ASS ships two independent libraries. Pick the one that fits your use-case:

|  | **SolidAndroidClient**  | **SolidAndroidApi**  |
|---  |--- |--- |
| **How it works** | Talks to the ASS host app via IPC | Communicates directly with the Solid IDP and pod server |
| **Auth management** | Handled by ASS — your app never sees tokens | Your app manages its own OIDC + DPoP session |
| **Requires ASS app** | Yes | No |
| **Best for** | Most third-party apps | Apps that need full auth control or run without ASS |
| **Artifact** | `com.pondersource.solidandroidclient:solidandroidclient` | `com.pondersource.solidandroidapi:solidandroidapi` |

## Prerequisites

- Android Studio with a project targeting **API level 26+**
- **JDK 17** (JBR v17.0.9 is recommended)
- A Solid account and Pod — create a free one at [solidcommunity.net](https://solidcommunity.net)
- *(SolidAndroidClient only)* The [ASS host app](https://github.com/pondersource/Android-Solid-Services/releases) installed on the target device (if using SolidAndroidClient)

## 1. Install the Android Solid Services App

If you are using **SolidAndroidClient**, the ASS host app must be installed on the device. Download the latest APK from the [GitHub Releases](https://github.com/pondersource/Android-Solid-Services/releases) page, enable *Install from unknown sources* in device settings, and install it. Launch the app and sign in with your Solid pod credentials.

If you are using **SolidAndroidApi** only, this step is not required.

## 2. Add the Dependency

Open your module-level `build.gradle.kts` and add the library you need:

=== "SolidAndroidClient"

    ```kotlin
    // build.gradle.kts (module level)
    android {
        defaultConfig {
            manifestPlaceholders["appAuthRedirectScheme"] = "YOUR_APP_PACKAGE_NAME"
        }
    }
    
    dependencies {
        implementation("com.pondersource.solidandroidclient:solidandroidclient:0.3.1")
    }
    ```

=== "SolidAndroidApi"

    ```kotlin
    // build.gradle.kts (module level)
    android {
        defaultConfig {
            manifestPlaceholders["appAuthRedirectScheme"] = "YOUR_APP_PACKAGE_NAME"
        }
    }

    dependencies {
        implementation("com.pondersource.solidandroidapi:solidandroidapi:0.3.1")
    }
    ```

Both libraries are published to **Maven Central**, so no additional repository configuration is needed.

## 3. Authenticate with Solid

=== "SolidAndroidClient"

    All three SDK clients are singletons returned by the `Solid` companion object. Start by obtaining a `SolidSignInClient` and waiting for the IPC connection to the ASS host app to become ready:

    ```kotlin
    import com.pondersource.solidandroidclient.sdk.Solid
    import com.pondersource.solidandroidclient.sdk.SolidSignInClient
    import kotlinx.coroutines.flow.collectLatest

    class MyViewModel(context: Context) : ViewModel() {

        private val signInClient: SolidSignInClient = Solid.getSignInClient(context)

        fun connectAndLogin() {
            viewModelScope.launch {
                // Wait until the IPC channel to ASS is established
                signInClient.authServiceConnectionState().collectLatest { connected ->
                    if (connected) {
                        val account = signInClient.getAccount()
                        if (account == null) {
                            // No access grant yet — ask the user to approve
                            signInClient.requestLogin { granted, error ->
                                if (granted) {
                                    // Your app now has an authorised session
                                } else {
                                    // User denied access or an error occurred
                                }
                            }
                        }
                        // account != null means we already have a grant
                    }
                }
            }
        }

        fun logout() {
            viewModelScope.launch {
                signInClient.disconnectFromSolid { success, error ->
                    // Access grant revoked
                }
            }
        }
    }
    ```

    !!! note
        Always await a `true` emission from `authServiceConnectionState()` before calling any other client method. The IPC binding to the ASS host app is asynchronous.

=== "SolidAndroidApi"

    The `Authenticator` class manages an OpenID Connect session with DPoP support. It opens a browser tab for the user to log in, then processes the authorization callback your app receives.

    ```kotlin
    import com.pondersource.solidandroidapi.Authenticator

    class MyViewModel(context: Context) : ViewModel() {

        private val authenticator: Authenticator = Authenticator.getInstance(context)

        // Step 1 — launch browser login
        fun startLogin(issuerUri: String): Intent {
            val intent = authenticator.createAuthenticationIntent(
                oidcIssuer = issuerUri, //https://login.inrupt.com for example
                appName = YOUR_APP_NAME,
                redirectUri = AUTH_APP_REDIRECT_URL //YOUR_APP_PACKAGE_NAME:/oauth2redirect
            )
            return intent
            //Handle the intent in your ComposeComponent/Activity/Fragment.
        }

        // Step 2 — call this from your ComposeComponent/Activity/Fragment after the browser redirects back
        fun handleCallback(
            authorizationResponse: AuthorizationResponse?,
            authorizationException: AuthorizationException?
        ) {
            viewModelScope.launch {
                try {
                    authenticator.submitAuthorizationResponse(
                        authorizationResponse,
                        authorizationException
                    )

                } catch (_: Exception) {}    

                if(authenticator.isUserAuthorized()) {
                    //User logged-in
                } else {
                    //Authentication failed
                }
            }
        }

        fun logout(webId: String): Intent? {
            val (intent, errorMessage)  = authenticator.getTerminationSessionIntent(
                webId = webId,
                logoutRedirectUrl = YOUR_LOGOUT_REDIRECT_URL
            )
            return intent
            //intent would be null if failed to make the intent and can read errorMessage.
            //Handle the intent in your ComposeComponent/Activity/Fragment.
        }
    }
    ```

    Once authenticated, you can inspect the active session:

    ```kotlin
    // Observe the active user's WebID as a Flow
    authenticator.activeWebIdFlow.collect { webId ->
        println("Logged in as: $webId")
    }

    // Check auth status
    authenticator.isAuthorizedFlow.collect { authorised ->
        if (authorised) {
            // Safe to make pod requests
        }
    }
    ```

## 4. Read and Write Pod Resources

Both libraries expose the same conceptual resource types:

- **`RDFSource`** — structured Turtle / JSON-LD data
- **`NonRDFSource`** — raw files (images, binaries, plain text)
- **`SolidContainer`** — LDP container (directory)

=== "SolidAndroidClient"

    Obtain a `SolidResourceClient` from the `Solid` companion object. All operations are `suspend` functions and throw subclasses of `SolidException` on failure.

    ```kotlin
    import com.pondersource.solidandroidclient.sdk.Solid
    import com.pondersource.solidandroidclient.sdk.SolidResourceClient
    import com.pondersource.solidandroidclient.sdk.Exceptions.SolidException

    val resourceClient: SolidResourceClient = Solid.getResourceClient(context)

    viewModelScope.launch {
        try {
            resourceClient.resourceServiceConnectionState().collect { servicehasConnected ->
                if(servicehasConnected) {   
                    // Fetch the authenticated user's WebID document
                    val webId = resourceClient.getWebId()

                    // Read a resource from the pod
                    val note = resourceClient.read(
                        "https://yourpod.example/notes/note1.ttl",
                        MyNote::class.java
                    )

                    // Create a new resource on the pod
                    val newNote = MyNote(body = "Hello Solid!")
                    resourceClient.create(newNote)

                    // Update an existing resource
                    note.body = "Updated content"
                    resourceClient.update(note)

                    // Delete a resource
                    resourceClient.delete(note)
                }
            }

        } catch (e: SolidException) {
            // Handle specific subclasses as needed:
            // SolidAppNotFoundException, SolidNotLoggedInException,
            // SolidResourceException (NotPermissionException, etc.)
            Log.e("Solid", "Operation failed", e)
        }
    }
    ```

    Your data classes must extend `RDFSource` or `NonRDFSource` from the shared module:

    ```kotlin
    import com.pondersource.shared.RDFSource

    class MyNote : RDFSource {
        private val bodyKey = rdf.createIRI("body")
        var body: String = ""

        constructor(
            identifier: URI,
            mediaType: MediaType? = null,
            dataset: RdfDataset? = null,
            headers: Headers? = null
        ): super(identifier, mediaType ?: MediaType.JSON_LD, dataset, headers)
    }
    ```

    !!! note
        Always await a `true` emission from `resourceServiceConnectionState()` before calling any other client method. The IPC binding to the ASS host app is asynchronous.

=== "SolidAndroidApi"

    Obtain a `SolidResourceManager` instance. Every operation returns a `SolidNetworkResponse<T>` — a sealed class with `Success`, `Error`, and `Exception` variants, so you never deal with raw exceptions for network calls.

    ```kotlin
    import com.pondersource.solidandroidapi.SolidResourceManager
    import com.pondersource.shared.SolidNetworkResponse
    import java.net.URI

    val profile = authenticator.getActiveProfile() //or call getAllLoggedInProfiles() to get a list of loggedin profiles and use the one you need.
    val resourceManager: SolidResourceManager = SolidResourceManager.getInstance(context, profile)

    viewModelScope.launch {
        // Read a resource
        when (val response = resourceManager.read(
            resource = URI("https://yourpod.example/notes/note1.ttl"),
            clazz = MyNote::class.java
        )) {
            is SolidNetworkResponse.Success -> display(response.data)
            is SolidNetworkResponse.Error   -> showError(response.errorCode, response.errorMessage)
            is SolidNetworkResponse.Exception -> handleException(response.exception)
        }

        // Create a resource
        val newNote = MyNote(body = "Hello Solid!")
        when (val response = resourceManager.create(resource = newNote)) {
            is SolidNetworkResponse.Success -> { /* created */ }
            is SolidNetworkResponse.Error   -> showError(response.errorCode, response.errorMessage)
            is SolidNetworkResponse.Exception -> handleException(response.exception)
        }

        // Update a resource
        newNote.body = "Updated content"
        resourceManager.update(newResource = newNote)

        // Delete a resource
        resourceManager.delete(resource = newNote)

        // Delete an entire container recursively
        resourceManager.deleteContainer(
            containerUri = URI("https://yourpod.example/notes/")
        )
    }
    ```

## 5. Work with Contacts

Both libraries provide a Solid Contacts data module that manages address books, contacts, and groups on the pod according to the [Solid Contacts specification](https://solid.github.io/contacts/).

=== "SolidAndroidClient"

    ```kotlin
    import com.pondersource.solidandroidclient.sdk.Solid
    import com.pondersource.solidandroidclient.sdk.SolidContactsDataModule

    val contactsModule: SolidContactsDataModule = Solid.getContactsDataModule(context)

    viewModelScope.launch {
        contactDataModule.contactsDataModuleServiceConnectionState().collect{ hasServiceConnected -> 
            if(hasServiceConnected) {
                // List all address books
                val books = contactsModule.getAddressBooks()

                // Create a new address book
                contactsModule.createAddressBook(
                    title = "Work Contacts",
                    isPrivate = false,
                    storage = "https://yourpod.example/",
                    ownerWebId = "https://yourpod.example/profile/card#me",
                    container = "https://yourpod.example/contacts/"
                )

                // Add a contact to an address book
                val newContact = NewContact(
                    name = "Alice Smith",
                    email = "alicesmith@gmail.com",
                    phoneNumber = "+1 555 0000",
                )
                contactsModule.createNewContact(
                    addressBookUri = books.first().uri,
                    newContact = newContact,
                    groupUris = emptyList()
                )

                // Fetch a contact
                val contact = contactsModule.getContact(contactUri = newContact.uri)

                // Add a phone number
                contactsModule.addNewPhoneNumber(contactUri = contact.uri, newPhoneNumber = "+1 555 0100")

                // Remove a contact
                contactsModule.deleteContact(
                    addressBookUri = books.privateAddressBookUris.first(),
                     contactUri = contact.uri
                )
            }
        }
    }
    ```

    !!! note
        Always await a `true` emission from `contactsDataModuleServiceConnectionState()` before calling any other client method. The IPC binding to the ASS host app is asynchronous.


=== "SolidAndroidApi"

    ```kotlin
    import com.pondersource.solidandroidapi.datamodule.SolidContactsDataModule

    val contactsModule: SolidContactsDataModule = SolidContactsDataModule.getInstance(context)
    val activeWebId = authenticator.getActiveWebId()

    viewModelScope.launch {
        // List all address books
        val addressBooks = contactsModule.getAddressBooks(ownerWebId = activeWebId)

        // Create a new address book
        contactsModule.createAddressBook(
            ownerWebId = activeWebId,
            title = "Work Contacts",
            isPrivate = false,
            storage = YOUR_POD_STORAGE
        )

        // Add a contact
        val newContact = NewContact(name = "Alice Smith")
        contactsModule.createNewContact(
            webid = activeWebId,
            addressBookUri = books.privateAddressBookUris.first(),
            newContact = newContact,
            groupUris = emptyList()
        )

        // Fetch a contact
        val contact = contactsModule.getContact(ownerWebId = activeWebId, uri = newContact.uri)

        // Manage groups
        val newGroup = contactsModule.createNewGroup(
            ownerWebId = activeWebId,
            addressBookUri = books.privateAddressBookUris.first(),
            title = "Colleagues",
            contactUris = listOf(contact.uri)
        )

        // Delete a contact
        contactsModule.deleteContact(
            ownerWebId = activeWebId,
            addressBookUri = books.privateAddressBookUris.first(),
            groupString = newGroup.uri
        )
    }
    ```

## Exception Handling (SolidAndroidClient)

The client library uses a structured exception hierarchy so you can handle failure cases precisely:

```kotlin
import com.pondersource.solidandroidclient.sdk.Exceptions.*

try {
    //Authentication or ResourceManagment action
} catch (e: SolidAppNotFoundException) {
    // The ASS host app is not installed — prompt the user to install it
} catch (e: SolidServiceConnectionException) {
    // IPC binding failed — retry or check that ASS is running
} catch (e: SolidNotLoggedInException) {
    // No authenticated session — redirect to login
} catch (e: NotPermissionException) {
    // The pod server rejected the request (403) — check ACL settings
} catch (e: SolidException) {
    // Catch-all for any other Solid error
}
```

## Further Reading

- [AndroidSolidServices documentation](https://androidsolidservices.erfangholami.com)
- [API Library reference](https://androidsolidservices.erfangholami.com/api-library/)
- [Client Library reference](https://androidsolidservices.erfangholami.com/client-library/)
- [GitHub repository](https://github.com/pondersource/Android-Solid-Services)
- [Solid Contacts — reference app using SolidAndroidClient](https://github.com/pondersource/Solid-Contacts)
- [Solid specification](https://solidproject.org/TR/)
