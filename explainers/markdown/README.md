# **Guide to Building Your First Solid App**

Welcome to Solid! The ecosystem has dozens of excellent tools to help you build your first application. This guide provides a clear, step-by-step path using one popular and powerful combination: **React** for the user interface and **Linked Data Objects (LDO)** to handle data.

## **What is Solid?**

The Solid ecosystem is built on a simple but powerful idea: separating applications from the data they create. This gives users control over their own information. It consists of three main parts:

1. **Solid Identity:** This is your universal login for the decentralized web. Instead of creating a new account for every app, you use your single Solid Identity.
2. **Solid Pod (Storage):** A Pod is your personal online datastore. It's where all your data—photos, contacts, blog posts, etc.—is kept securely. You can choose where your Pod is hosted, and you grant apps permission to access its data.
3. **Solid App:** These are the applications you use. The key difference is that Solid apps don't have their own databases. Instead, they read from and write to your Pod, based on the permissions you've given them.

This model means you can use multiple apps to manage the same data, and you can switch apps without losing your information.

## **What is Linked Data and LDO?**

To make sure different apps can understand the same data, Solid uses a standard called the **Resource Description Framework (RDF)**. RDF, often called "Linked Data," is a flexible way to describe things and the relationships between them.

While powerful, working directly with RDF can be complex. That's where [**Linked Data Objects (LDO)**](https://ldo.js) comes in. LDO is a library that lets you interact with the data in your Pod as if it were a regular JavaScript object. It simplifies data handling, so you can focus on building your app.

LDO uses **ShEx (Shape Expressions)** to define the "shape" of your data. Think of a ShEx shape as a blueprint or a schema that describes what a piece of data (like a user profile or a blog post) should look like. This ensures your data is consistent and predictable.

In this tutorial, we'll build a simple micro-blogging web app that allows you to write notes and upload photos to your Solid Pod.

## **1. Getting Your Solid Identity and Pod**

Before you can build an app, you need a place to store your data. We'll get you set up with a free Solid Identity and Pod from solidcommunity.net.

1. **Create an Account:** Go to [solidcommunity.net](https://solidcommunity.net) and click "Register." Fill out the form to create your account. This process creates your **Solid Identity**.
2. **Create a Pod:** After registering and logging in, you'll be prompted to "Create a Pod." Choose a name for your Pod. This will be your personal storage space.

That's it! You now have a Solid Identity to log in with and a Pod to store your data.

## **2. Setting Up Your React Project**

This guide assumes you are familiar with React. Let's initialize a new project using Vite, a modern and fast build tool. Since LDO works best with TypeScript, we'll use the TypeScript template.

Open your terminal and run the following commands:

```bash
npm create vite@latest my-solid-app -- --template react-ts
cd my-solid-app
```

Now, let's set up a basic component structure for our app. We'll create five components:

**src/App.tsx**: The main application component.

```typescript
import React, { FunctionComponent } from 'react';
import { Header } from './Header';import { Blog } from './Blog';

const App: FunctionComponent = () => {
  return (
    <div className="App">
      <Header />
      <Blog />
    </div>
  );
}

export default App;
```

**src/Header.tsx**: A header for handling login.

```typescript
import { FunctionComponent } from "react";

export const Header: FunctionComponent = () => {
  return (
    <header>
      <p>Header</p>
      <hr />
    </header>
  );
};
```

**src/Blog.tsx**: The main component for the blog timeline.

```typescript
import { FunctionComponent } from "react";
import { MakePost } from "./MakePost";
import { Post } from "./Post";

export const Blog: FunctionComponent = () => {
  return (
    <main>
      <MakePost />
      <hr />
      <Post />
    </main>
  );
};
```

**src/MakePost.tsx**: A form for creating new posts.

```typescript
import { FormEvent, FunctionComponent, useCallback, useState } from "react";

export const MakePost: FunctionComponent = () => {
  const [message, setMessage] = useState("");
  const [selectedFile, setSelectedFile] = useState<File | undefined>();

  const onSubmit = useCallback(
    async (e: FormEvent<HTMLFormElement>) => {
      e.preventDefault();
      // We will add upload functionality here
      console.log("Submitting:", { message, selectedFile });
    },
    [message, selectedFile]
  );

  return (
    <form onSubmit={onSubmit}>
      <input
        type="text"
        placeholder="Make a Post"
        value={message}
        onChange={(e) => setMessage(e.target.value)}
      />
      <input
        type="file"
        accept="image/*"
        onChange={(e) => setSelectedFile(e.target.files?.[0])}
      />
      <input type="submit" value="Post" />
    </form>
  );
};
```

**src/Post.tsx**: A component to render a single post.

```typescript
import { FunctionComponent } from "react";

export const Post: FunctionComponent = () => {
  return (
    <div>
      <p>A Single Post</p>
    </div>
  );
};
```

Start your application by running npm run dev. You should see a basic, unstyled page with a header, a form, and a placeholder for a post.

## **3. Integrating LDO for Solid**

With the basic structure in place, let's install LDO and connect our app to the Solid ecosystem.

```bash
npm install @ldo/solid-react
```

This library provides React hooks and components that make Solid development much easier. To use them, we need to wrap our application in a BrowserSolidLdoProvider. You can learn more about the hooks and utilities it provides in the [**LDO API Documentation**](https://ldo.js.org/latest/api/).

Modify **src/App.tsx**:

```typescript
import React, { FunctionComponent } from 'react';
import { Header } from './Header';
import { Blog } from './Blog';
import { BrowserSolidLdoProvider } from '@ldo/solid-react';

const App: FunctionComponent = () => {
  return (
    <div className="App">
      <BrowserSolidLdoProvider>
        <Header />
        <Blog />
      </BrowserSolidLdoProvider>
    </div>
  );
}

export default App;
```

## **4. Implementing Login and Logout**

Now we can implement authentication. The useSolidAuth hook from LDO gives us everything we need to manage user sessions.

Let's update **src/Header.tsx** to handle login and logout.

```typescript
import { useSolidAuth } from "@ldo/solid-react";
import { FunctionComponent, useState } from "react";

export const Header: FunctionComponent = () => {
  const { session, login, logout } = useSolidAuth();
  const [issuer, setIssuer] = useState("https://solidcommunity.net");

  return (
    <header>
      {session.isLoggedIn ? (
        // If the user is logged in
        <p>
          Logged in as {session.webId}.{" "}
          <button onClick={logout}>Log Out</button>
        </p>
      ) : (
        // If the user is not logged in
        <div>
          <p>You are not logged in.</p>
          <input 
            type="text" 
            value={issuer} 
            onChange={(e) => setIssuer(e.target.value)} 
          />
          <button onClick={() => login(issuer)}>Log In</button>
        </div>
      )}
      <hr />
    </header>
  );
};
```

Here's what's happening:

* useSolidAuth() gives us the session object (with info like isLoggedIn and webId), a login(issuer) function, and a logout() function.
* We show a "Log Out" button if session.isLoggedIn is true.
* Otherwise, we show an input field for the user's Pod provider (which we've pre-filled with solidcommunity.net) and a "Log In" button. Clicking it will redirect the user to their provider to authenticate.

Next, let's update **src/Blog.tsx** to only show the blog content if the user is logged in.

```typescript
import { FunctionComponent } from "react";
import { MakePost } from "./MakePost";
import { Post } from "./Post";
import { useSolidAuth } from "@ldo/solid-react";

export const Blog: FunctionComponent = () => {
  const { session } = useSolidAuth();
  if (!session.isLoggedIn) {
    return <p>Please log in to see your blog.</p>;
  }

  return (
    <main>
      <MakePost />
      <hr />
      <Post />
    </main>
  );
};
```

Now, try logging in. You'll be redirected to solidcommunity.net, and after you approve the application, you'll be sent back to your app, now in a logged-in state.

## **5. Defining Data Shapes with ShEx**

Before we can read or write data, we need to tell LDO what our data looks like. We do this using **ShEx**. Let's set up our project for shapes.

In your terminal, run:

```bash
npx @ldo/cli init
```

This command installs needed libraries and creates two new folders in src: .shapes (where you'll write your ShEx schemas) and .ldo (where LDO will put the auto-generated TypeScript code).

The init command creates a default foafProfile.shex. We want to define a more complete Solid Profile, so let's replace it.

1. Delete the default file: rm src/.shapes/foafProfile.shex
2. Create a new file: touch src/.shapes/solidProfile.shex
3. Paste the following ShEx schema into **src/.shapes/solidProfile.shex**:

```typescript
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
PREFIX schem: <http://schema.org/>
PREFIX vcard: <http://www.w3.org/2006/vcard/ns#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX ldp: <http://www.w3.org/ns/ldp#>
PREFIX sp: <http://www.w3.org/ns/pim/space#>

<SolidProfileShape> EXTRA a {
  a [ schem:Person foaf:Person ] ;
  vcard:fn xsd:string ? ;
  foaf:name xsd:string ? ;
  ldp:inbox IRI ;
  sp:storage IRI * ;
}
```

*Note: This is a simplified version of a full Solid Profile shape for brevity.*

Now, build the TypeScript typings from this shape:

```bash
npm run build:ldo
```

This command reads your .shex files and generates corresponding code in the .ldo folder, which we'll use in the next step.

## **6. Fetching and Displaying Profile Data**

Let's make our header more personal by displaying the user's name instead of their WebID. We can do this by fetching their profile data from their Pod.

Update **src/Header.tsx** to use the useResource and useSubject hooks.

```typescript
import { FunctionComponent, useState } from "react";
import { useResource, useSolidAuth, useSubject } from "@ldo/solid-react";
import { SolidProfileShapeShapeType } from "./.ldo/solidProfile.shapeTypes";

export const Header: FunctionComponent = () => {
  const { session, login, logout } = useSolidAuth();
  const [issuer, setIssuer] = useState("https://solidcommunity.net");

  // Fetch the resource at the user's WebID
  const webIdResource = useResource(session.webId);
  // Interpret the WebID resource using the SolidProfile shape
  const profile = useSubject(SolidProfileShapeShapeType, session.webId);

  // Determine what name to display
  const loggedInName = webIdResource?.isReading()
    ? "Loading..."
    : profile?.fn || profile?.name || session.webId;

  return (
    <header>
      {session.isLoggedIn ? (
        <p>
          Logged in as {loggedInName}.{" "}
          <button onClick={logout}>Log Out</button>
        </p>
      ) : (
        <div>
          <p>You are not logged in.</p>
          <input 
            type="text" 
            value={issuer} 
            onChange={(e) => setIssuer(e.target.value)} 
          />
          <button onClick={() => login(issuer)}>Log In</button>
        </div>
      )}
      <hr />
    </header>
  );
};
```

### **How useResource and useSubject Work Together**

This code introduces two fundamental LDO hooks that are important to understand:

* useResource(uri) tells LDO to fetch a specific document from a server (in this case, the user's profile document). It manages the network request and loading state. All the RDF data from this document is loaded into a single, in-memory graph for your application.
* useSubject(ShapeType, uri) does not fetch any data. Instead, it looks at the data *already loaded* in your app's graph. It finds the data associated with the given URI and presents it to you as a clean, typed JavaScript object based on the ShapeType you provide.

This separation is powerful. You can load multiple resources (e.g., a profile, a contacts list, and a blog post), and LDO combines them. Then, useSubject can seamlessly follow links and relationships between data, even if that data originally came from different documents. It doesn't care *where* the data came from, only that it has been loaded.

Refresh your app, and you should now see your name in the header after logging in!

## **7. Creating and Storing Posts**

Now for the core of our app: creating and saving blog posts.

### **Defining the Post Shape**

First, we need a ShEx shape for our posts. Create a new file at **src/.shapes/post.shex** and add the following:

```shex
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX ex: <https://example.com/>
PREFIX schema: <http://schema.org/>

ex:PostSh {
  a [schema:SocialMediaPosting schema:CreativeWork schema:Thing] ;
  schema:articleBody> xsd:string?
      // rdfs:label '''articleBody'''
      // rdfs:comment '''The actual body of the article. ''' ;
  schema:uploadDate> xsd:date
      // rdfs:label '''uploadDate'''
      // rdfs:comment '''Date when this media object was uploaded to this site.''' ;
  schema:image IRI ?
      // rdfs:label '''image'''
      // rdfs:comment '''A media object that encodes this CreativeWork. This property is a synonym for encoding.''' ;
  schema:publisher IRI
      // rdfs:label '''publisher'''
      // rdfs:comment '''The publisher of the creative work.''' ;
}
// rdfs:label '''SocialMediaPost'''
// rdfs:comment '''A post to a social media platform, including blog posts, tweets, Facebook posts, etc.'''
```

This shape defines a SocialMediaPosting with a body, a date, and an optional image.

Run the build command again to generate the typings for our new shape:

```bash
npm run build:ldo
```

### **Finding Where to Save Data**

A common question in Solid is: "Where do I save my app's data?" The best practice is to create a dedicated folder for your app inside the user's Pod. We can find the root of their storage space using the sp:storage property from their profile.

Let's update **src/Blog.tsx** to find the root container and create a folder for our app.

```typescript
import { FunctionComponent, useEffect, useState, Fragment } from "react";
import { MakePost } from "./MakePost";
import { Post } from "./Post";
import { useLdo, useResource, useSolidAuth, useSubject } from "@ldo/solid-react";
import { SolidProfileShapeShapeType } from "./.ldo/solidProfile.shapeTypes";
import { Container, ContainerUri } from "@ldo/solid";

export const Blog: FunctionComponent = () => {
  const { session } = useSolidAuth();
  const profile = useSubject(SolidProfileShapeShapeType, session.webId);
  const { getResource } = useLdo();
  const [mainContainerUri, setMainContainerUri] = useState<ContainerUri>();

  useEffect(() => {
    if (profile?.storage?.[0]?.["@id"]) {
      const storageUri = profile.storage[0]["@id"] as ContainerUri;
      const appContainerUri = `${storageUri}my-solid-app/`;
      setMainContainerUri(appContainerUri);
      // Create the container if it doesn't exist
      const appContainer = getResource(appContainerUri);
      appContainer.createIfAbsent();
    }
  }, [profile, getResource]);

  const mainContainer = useResource(mainContainerUri);

  if (!session.isLoggedIn) {
    return <p>Please log in to see your blog.</p>;
  }

  return (
    <main>
      <MakePost mainContainer={mainContainer} />
      <hr />
      {mainContainer
        ?.children()
        .filter((child): child is Container => child.type === "container")
        .map((child) => (
          <Fragment key={child.uri}>
            <Post postContainerUri={child.uri} />
            <hr />
          </Fragment>
        ))}
    </main>
  );
};
```

In this useEffect, we:

1. Get the user's storage location from their profile (profile.storage).
2. Define a path for our app's container (my-solid-app/).
3. Use getResource(appContainerUri).createIfAbsent() to create this container on their Pod if it's not already there.

We also started logic to render posts. mainContainer.children() gets a list of all items in our app's folder. We then filter for just the containers (since each post will be in its own container) and map over them to render a Post component for each one.

### **Creating a New Post**

Now let's wire up the **src/MakePost.tsx** component to actually create data.

```typescript
import { FormEvent, FunctionComponent, useCallback, useState } from "react";
import { Container, Leaf, LeafUri } from "@ldo/solid";
import { useLdo, useSolidAuth } from "@ldo/solid-react";
import { v4 as uuid } from "uuid";
import { PostShapeShapeType } from "./.ldo/post.shapeTypes";

export const MakePost: FunctionComponent<{ mainContainer?: Container }> = ({
  mainContainer,
}) => {
  const { session } = useSolidAuth();
  const { createData, commitData } = useLdo();
  const [message, setMessage] = useState("");
  const [selectedFile, setSelectedFile] = useState<File | undefined>();

  const onSubmit = useCallback(
    async (e: FormEvent<HTMLFormElement>) => {
      e.preventDefault();
      if (!mainContainer || !session.webId) return;

      // 1. Create a new container for the post
      const postContainerResult = await mainContainer.createChildAndOverwrite(`${uuid()}/`);
      if (postContainerResult.isError) return alert(postContainerResult.message);
      const postContainer = postContainerResult.resource;

      // 2. Upload the image file (if one was selected)
      let uploadedImage: Leaf | undefined;
      if (selectedFile) {
        const imageResult = await postContainer.uploadChildAndOverwrite(
          selectedFile.name as LeafUri,
          selectedFile,
          selectedFile.type
        );
        if (imageResult.isError) return alert(imageResult.message);
        uploadedImage = imageResult.resource;
      }

      // 3. Create the structured data (index.ttl)
      const indexResource = postContainer.child("index.ttl");
      const post = createData(PostShapeShapeType, indexResource.uri, indexResource);
      post.articleBody = message;
      post.uploadDate = new Date().toISOString();
      if (uploadedImage) {
        post.image = { "@id": uploadedImage.uri };
      }

      // 4. Commit the data to the Pod
      const commitResult = await commitData(post);
      if (commitResult.isError) return alert(commitResult.message);

      // Clear the form
      setMessage("");
      setSelectedFile(undefined);
    },
    [mainContainer, session.webId, selectedFile, message, createData, commitData]
  );

  return (
    <form onSubmit={onSubmit}>
      <input
        type="text"
        placeholder="What's on your mind?"
        value={message}
        onChange={(e) => setMessage(e.target.value)}
      />
      <input
        type="file"
        accept="image/*"
        onChange={(e) => setSelectedFile(e.target.files?.[0])}
      />
      <input type="submit" value="Post" />
    </form>
  );
};
```

This is the most complex step, so let's break it down:

1. **Create Post Container:** We create a new, uniquely named sub-container inside our main app container to hold this specific post.
2. **Upload Image:** If the user selected a file, we use uploadChildAndOverwrite to save it inside the new post's container. This is for "unstructured" data.
3. **Create Structured Data:** We define where our structured data will live (index.ttl). Then, createData(PostShapeShapeType, ...) gives us a special LDO object (post) that conforms to our PostShape. We can then set its properties (articleBody, uploadDate, image) like a normal object.
4. **Commit Data:** commitData(post) takes our local changes and sends them to the Solid Pod, creating the index.ttl file with the correct RDF data.

## **8. Displaying the Post Content**

Finally, let's update **src/Post.tsx** to fetch and display the data for each post.

```typescript
import { FunctionComponent, useMemo, useCallback } from "react";
import { ContainerUri, LeafUri } from "@ldo/solid";
import { useLdo, useResource, useSubject } from "@ldo/solid-react";
import { PostShapeShapeType } from "./.ldo/post.shapeTypes";

export const Post: FunctionComponent<{ postContainerUri: ContainerUri }> = ({
  postContainerUri,
}) => {
  const postIndexUri = `${postContainerUri}index.ttl`;
  const postResource = useResource(postIndexUri);
  const post = useSubject(PostShapeShapeType, postIndexUri);
  const { getResource } = useLdo();

  const imageResource = useResource(post?.image?.["@id"] as LeafUri | undefined);

  // Convert the fetched image blob into a URL for the <img> tag
  const imageUrl = useMemo(() => {
    if (imageResource?.isBinary()) {
      return URL.createObjectURL(imageResource.getBlob()!);
    }
  }, [imageResource]);

  const deletePost = useCallback(async () => {
    // We can just delete the entire container for the post
    const postContainer = getResource(postContainerUri);
    await postContainer.delete();
  }, [postContainerUri, getResource]);

  if (postResource?.isReading()) return <p>Loading post...</p>;
  if (!post) return null;

  return (
    <div>
      <p>{post.articleBody}</p>
      {imageUrl && <img src={imageUrl} alt="Post" style={{ maxHeight: 200 }} />}
      <p>
        <small>Posted on: {new Date(post.uploadDate!).toLocaleString()}</small>
      </p>
      <button onClick={deletePost}>Delete</button>
    </div>
  );
};
```

This component uses the same useResource and useSubject pattern we saw in the header to fetch the index.ttl for a specific post and interpret it as a PostShape object.

A key detail is how we handle images. Most data in a Pod is private. If we simply put the image's URL in an <img> tag's src, the browser's request would be unauthenticated and fail. Instead, we must:

1. Fetch the image using useResource, which makes an authenticated request.
2. Get the binary data as a Blob using imageResource.getBlob().
3. Create a local URL for that blob using URL.createObjectURL() that the <img> tag can use.

We've also added a delete button that simply deletes the entire container for the post.

## **9. Building and Deploying Your App**

Congratulations! You've built a fully functional, decentralized Solid application. To deploy it, you first need to create a production build.

```bash
npm run build
```

This command creates a dist folder (for Vite) containing static HTML, CSS, and JavaScript files. Because this is a client-side application (all the logic runs in the user's browser), you can deploy it on any static hosting service. Popular free options include:

* [Vercel](https://vercel.com)
* [Netlify](https://netlify.com)
* [GitHub Pages](https://pages.github.com/)

Simply upload the contents of your dist folder to one of these services.

The beauty of Solid is that your deployed application is completely independent of the data store. Anyone with a Solid Pod—whether it's on solidcommunity.net, a provider run by ODI, or one they host themselves—can log in and use your app to manage data on their own Pod. You've created a truly interoperable application for the decentralized web.
