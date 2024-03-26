# BMS-Build-Open

## Dockerized build script for Breeding Management System components

Requires access to the private InventoryMangement repository - contact [IBP - Integrated Breeding Platform](https://github.com/IntegratedBreedingPlatform) for access.
Once you have access, you need to follow the github ssh set up and copy your key to the local directory and name it id_rsa.


The goal is to be able to use the following command to build all, with the output going to ./out folder
```bash
# can't use (yet)
docker build --ssh default=<path to your ssh key> --output out .
```
But... there are issues with the docker ssh passthrough when calling yarn in the Workbench repo, and there are some insecure references to packages in the Workbench so the build steps are more complicated.
```bash
# first build the image
docker build -t bmsbuilder .

# "shell into" the running the imgage
docker run -it bmsbuilder bash

# change settings to allow insecure (http) maven references
# update /usr/share/maven/conf/settings.xml per Nick's answer here: https://stackoverflow.com/questions/67833372/getting-blocked-mirror-for-repositories-maven-error-even-after-adding-mirrors
# ex: install vim with 'apt update' then 'apt install vim' then edit /usr/share/maven/conf/settings.xml and change
# the <mirrorOf>external:http:*</mirrorOf> to <mirrorOf>external:dummy:*</mirrorOf>

# then from the /bmssource/Workbench directory, build Workbench
mvn clean install -DskipTests -Duser.name=template -e

# from a separate shell, copy out the war files
docker cp <your-docker-container-ref>:/bmssource/BMSAPI/target/bmsapi.war .
docker cp <your-docker-container-ref>:/bmssource/Fieldbook/target/Fieldbook.war .
docker cp <your-docker-container-ref>:/bmssource/InventoryManager/target/inventory-manager.war .
docker cp <your-docker-container-ref>:/bmssource/Workbench/target/ibpworkbench.war .
```


The build outputs .war files for:
* bmsapi.war
* Fieldbook.war
* inventory-manager.war
* ibpworkbench.war

To run a dockerized version of BMS, copy over the war files and use the docker compose in [BMS-Runtime-Open](https://github.com/jamesclevenger/BMS-Runtime-Open)
