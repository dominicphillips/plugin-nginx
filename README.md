Boundary Elasticsearch Plugin
-------------------------

Collects metrics from a nginx instance.

### Prerequisites

|     OS    | Linux | Windows | SmartOS | OS X |
|:----------|:-----:|:-------:|:-------:|:----:|
| Supported |   v   |    v    |    v    |  v   |

|  Runtime | LUA/luvit |
|:---------|:-------:|:------:|:----:|
| Required |    +    |        |      |

### Plugin Setup

To collect statistics from nginx, it needs to built with the [nginx HttpStubStatusModule](http://nginx.org/en/docs/http/ngx_http_stub_status_module.html). If you used a package manager to install Nginx, it should be compiled by default, if you built Nginx yourself, you may need to recompile it.

#### Verify That `nginx` Includes `HttpStubStatusModule`

1. To check if your nginx has been build with the [nginx HttpStubStatusModule](http://nginx.org/en/docs/http/ngx_http_stub_status_module.html) run the following command, which will display the modules that are compiled in your version of `nginx`:
     ```bash
  $ nginx -V
    ```
2. If the string `--with-http_stub_status_module` is in the output then the installed `nginx` includes the `HttpStubStatusModule`. If the string is not there, you will need to install a package that includes the module or compile a version that includes it. Information on installing and/or compiling `nginx` can found here: [http://nginx.org/en/docs/install.html](http://nginx.org/en/docs/install.html)

#### `HttpStubStatusModule` Configuration

`nginx` requires configuration to provide URL path which will present the `nginx` statistics.

1. Edit your default `/etc/nginx/conf.d/virtual.conf` file (or whatever `.conf` file you are using) and add the following configuration in your `server {}` block:

     ```
  location /nginx_status {
    # activate stub_status module
    stub_status on;

    # do not log graphdat polling the endpoint
    access_log off;

    # restrict access to local only
    allow 127.0.0.1;
    deny all;

    # optional, should be JSON by default
          status_format json;
  }
     ```
2. Ensure that a listen address is configured in /etc/nginx/conf.d/virtual.conf under the server {} block as well. An complete example that configures the `HttpStubStatusModule` is shown here:

     ```
     server {
       listen       8000;
       location /nginx_status {
       # activate stub_status module
       stub_status on;

       # do not log graphdat polling the endpoint
       access_log off;

       # restrict access to local only
       allow 127.0.0.1;
       deny all;
       }
    }
    ```
3. (Only relevant for Nginx Plus) To enable collecting metrics per virtual server, you need to enable zones. See Nginx documentation for more details about [status_zone](http://nginx.org/en/docs/http/ngx_http_status_module.html#status_zone) directive. Several virtual servers may share the same zone.

    ```
    status_zone <your-zone-goes-here>;
    ```


4. Once you make the update, reload your nginx configuration:
    ```bash
     $ sudo service nginx reload
    ```

#### Verify `HttpStubStatusModule` is Collecting Statistics

1. Run the following command, which shows the expected output:
    ```bash
    $ curl http://localhost:8000/nginx_status
    Active connections: 1
    server accepts handled requests
    5 5 5
    Reading: 0 Writing: 1 Waiting: 0
    ```


#### Plugin Configuration Fields

|Field Name|Description                                                |
|:---------|:----------------------------------------------------------|
|Port      |The NGINX port.                                        |
|Host      |The NGINX hostname.                                    |
|Path      |The status path.                                    |

### Metrics Collected
|Metric Name          |Description                       |
|:--------------------|:---------------------------------|
|_Nginx Free (Open Source)_                                                                                                  |
|                                                                                                                            |
|Nginx Active Connections     |Active connections to nginx                                                                   |
|Nginx Reads                  |Connections with Nginx reading request headers                                                |
|Nginx Writes                 |Connections with Nginx reading request body, processing request or writing response to client.|
|Nginx Waiting                |Keep-alive connections with Nginx in a wait state                                             |
|Nginx Connections Handled    |Connections handled by nginx                                                                  |
|Nginx Connections Not Handled|Connections accepted, but not handled                                                         |
|Nginx Requests               |Requests to nginx                                                                             |
|Nginx Requests per Connection|Requests per handled connections for nginx                                                    |
|                                                                                                                            |
|_Nginx Plus (Commercial) - Metrics per zone_                                                                                 |
|                                                                                                                            |
|Nginx Responses              |The total number of responses sent to clients.                                                |
|Nginx Traffic Sent           |The total number of bytes sent to clients.                                                    |
|Nginx Traffic Received       |The total number of bytes received from clients.