# Solid + Next.js + LDO: Demo Application

This is a tutorial on how to create a Solid Application using [Next.js](https://nextjs.org/), [LDO](https://ldo.js.org/latest/) and [ACP](https://solidproject.org/TR/acp).

The following instructions are meant to guide you through running the Solid Next ldo Demo Application ([code is available on github](https://github.com/solid/solid-next-ldo-demo/)).

## Prerequisite

Download the [solid/solid-next-ldo-demo](https://github.com/solid/solid-next-ldo-demo/) code on GitHub.

## How To

Follow the [README instructions](https://github.com/solid/solid-next-ldo-demo) to setup and run the demo app.

The application code is commented to help you understand and learn a simple solid application development pattern.

## About Solid Servers

The Solid Next ldo application runs a [Community Solid Server](https://communitysolidserver.github.io/CommunitySolidServer/latest/) (CSS) instance in development.

It is easy to configure an alternative solid server via the environment variable `NEXT_PUBLIC_BASE_URI`.

When you want to run a similar application in production, you will want to configure it so that it uses a solid server available via the internet instead of localhost.

You could [create a Pod](https://solidproject.org/get_a_pod) with one of the existing providers. 

Or you could host your own Pod with the Community Solid Server. 

You can follow the instructions in [solid/css-azure-app-service](https://github.com/solid/css-azure-app-service) to deploy the CSS to Azure.
