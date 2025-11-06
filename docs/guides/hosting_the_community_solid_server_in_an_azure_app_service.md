# Hosting the Community Solid Server in an Azure App Service

One of the challenges associated with developing applications and getting started with Solid is to have a simple Solid server hosted that you can control and customize to your needs.

The [Community Solid Server](https://communitysolidserver.github.io/CommunitySolidServer/) (CSS), [developed](https://solidlab.be/community-solid-server/) by imec research groups at Ghent University, provides a good base for experimentation.

The repository [solid/css-azure-app-service](https://github.com/solid/css-azure-app-service) provides:

1. A CSS [configuration](https://github.com/solid/css-azure-app-service/blob/main/config/config.json) that focuses on standard Solid features and provides a simple single pod hosting service (see [CSS configuration](https://github.com/CommunitySolidServer/CommunitySolidServer?tab=readme-ov-file#configure-your-server));
1. A step by step [guide](https://github.com/solid/css-azure-app-service/blob/main/README.md) to deploying CSS to an Azure App Service;
1. An infrastructure as code [template](https://github.com/solid/css-azure-app-service/blob/main/infrastructure/template.json) to facilitate deployment;
1. A few [sample files](https://github.com/solid/css-azure-app-service/tree/main/data) that can be used to setup your Solid Server (an Azure blob storage is used for Solid resources persistance, so you can upload files directly from the Azure UI when you want to setup or change your server's access control and resources).


## Note

The proposed configuration intentionally strips CSS from non-standard features as well as multipod and authentication features.

It is intended to provide you a simple to use and adequate development and experimentation environment: one hosted Solid Pod that you have full control over.

Full control in this case means that you can always access the Pod resources via the Azure Blob storage UI and completely change access control files and other resources to your needs.
