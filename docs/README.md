# Docker networking and volumes

## Default bridge vs. your own bridge network

List Docker networks available by default:

```bash
docker network ls
```

Run two containers:

```bash
docker run -itd --rm --name box busybox
docker run -itd --rm --name web nginx
docker container ls
docker network inspect bridge
```

### Ping in the default bridge network

Check the IP address of `nginx`:

```bash
docker network inspect bridge
```

Open shell in `box`:

```bash
docker exec -it box sh
```

Ping the `web` container by IP address:

```bash
ping 172.168.0.3
```

This works, but pinging by container name does not:

```bash
ping web
```

DNS does not work in the default bridge network.

## Ping in created network-1

Create your own bridge network:

```bash
docker network create network-1
docker network connect network-1 box
docker network connect network-1 web
docker network inspect network-1
docker exec -it box sh
ping 172.167.0.3
ping web
```

DNS works in the created network.

Stop containers:

```bash
docker container stop box web
docker container ls
```

The container list should now be empty.

## How do I open container app from my computer?

Run `nginx` and publish port 80:

```bash
docker run -itd --rm --network network-1 --name web -p 80:80 nginx
docker container ls
```

Open in browser:

```text
http://localhost:80
```

Stop container:

```bash
docker container stop web
docker container ls
```

The container list should now be empty.

You can remove the network now:

```bash
docker network rm network-1
```

## Host networking: direct access, less isolation

Run container with host networking:

```bash
docker run -itd --rm --network host --name web nginx
docker container ls
```

Open in browser:

```text
http://localhost:80
```

Stop container:

```bash
docker container stop web
docker container ls
```

The container list should now be empty.

## Share data from local machine with container

List volumes:

```bash
docker volume ls
```

Create a volume:

```bash
docker volume create my-volume
docker volume ls
docker volume inspect my-volume
```

Go to volume mount point:

```text
/var/lib/docker/volumes/my-volume/_data
```

Add a file with some text:

```bash
echo "my text" > file.txt
```

Mount it into a container:

```bash
docker run -itd --rm -v my-volume:/data --name box busybox
docker container inspect box
docker exec -it box sh
```

Inside the container:

```bash
cd data
cat file.txt
```

You should see the text from the host.

Add more text and exit the container.

Stop container.

Check the mount point again:

```text
/var/lib/docker/volumes/my-volume/_data
```

Read the file:

```bash
cat file.txt
```

The data is still there, even though the container is gone.

You can remove the volume now:

```bash
docker volume rm my-volume
```