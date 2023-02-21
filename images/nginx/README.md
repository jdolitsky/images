<!--monopod:start-->
# nginx
| | |
| - | - |
| **Status** | stable |
| **OCI Reference** | `cgr.dev/chainguard/nginx` |
| **Variants/Tags** | ![](https://storage.googleapis.com/chainguard-images-build-outputs/summary/nginx.svg) |

*[Contact Chainguard](https://www.chainguard.dev/chainguard-images) for enterprise support, SLAs, and access to older tags.*

---
<!--monopod:end-->

A minimal nginx base image rebuilt every night from source.

## Get It!

The image is available on `cgr.dev`:

```
docker pull cgr.dev/chainguard/nginx:latest
```

## Usage

To try out the image, run:

```
docker run -p 8080:80 cgr.dev/chainguard/nginx
```

If you navigate to `localhost:8080`, you should see the nginx welcome page.

To run an example Hello World app, navigate to the root of this repo and run:

```
docker run -v $(pwd)/examples/hello-world/site-content:/var/lib/nginx/html -p 8080:80 cgr.dev/chainguard/nginx
```

If you navigate to `localhost:8080`, you should see `Hello World from Nginx!`.

To use a custom `nginx.conf` you can mount the file into the container

```
docker run -v $(pwd)/$CUSTOM_NGINX_CONF_DIRECTORY/nginx.conf:/etc/nginx/nginx.conf -p 8080:80 cgr.dev/chainguard/nginx
```
