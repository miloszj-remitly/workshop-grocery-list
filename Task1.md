required tags:
 image - what is the image that your container is going to use and with what tag. The latter especially important for versioning
 build - the path the the directory which your Dockerfile resides, if this parameter is not provided the docker will look for the image in the registry. If not found will return an error
 ports - what ports your container uses the syntax is <external>:<internal>
