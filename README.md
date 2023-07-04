# BMS-Build-Open

## Dockerized build script for Breeding Management System components

Requires access to the private InventoryMangement repository - contact owner of [https://github.com/IntegratedBreedingPlatform] for access.
Once you have access, you need to follow the github ssh set up and copy your key to the local directory and name it id_rsa.

```bash
docker build --output out .
```

The build outputs .war files for:
* bmsapi.war
* Fieldbook.war
* inventory-manager.war
* Workbench.war
