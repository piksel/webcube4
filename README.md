# webcube4

A Bash+Javascript script to connect/disconnect the WebCube4 (Huawei E8378) 4G/LTE router

* Version: 1.0.0
* Date: 2017-01-10
* Developer: [Alberto Pettarin](http://www.albertopettarin.it/) ([contact](http://www.albertopettarin.it/contact.html))
* License: the MIT License (MIT), see LICENSE.md


## Installation

1. Make sure you have ``curl`` and ``node`` installed and in your ``PATH``
   (any recent version will work, you do not need the exact version shown below):

    ```bash
    $ curl --version
    curl 7.51.0

    $ node --version
    v7.0.0
    ```

2. Clone this repository:

    ```bash
    $ git clone https://github.com/pettarin/webcube4.git
    $ cd webcube4
    ```

3. Put your router admin password in ``~/.webcube4``:

    ```bash
    $ echo "your_router_admin_password" > ~/.webcube4
    $ chmod 400 ~/.webcube4
    ```


## Usage

```bash
$ bash webcube4.sh

Usage:
  $ bash webcube4.sh connect [--debug]
  $ bash webcube4.sh reconnect [--debug]"
  $ bash webcube4.sh disconnect [--debug]

Notes:
  1. you need curl and node to be installed and in your PATH
  2. put your router admin password in ~/.config/webcube4/password, e.g. by running:
     $ echo "yourpass" > ~/.config/webcube4/password && chmod 400 ~/.config/webcube4/password
  3. if your router is not located at 192.168.1.1, put your router IP in ~/.config/webcube4/webroot
```

To connect:

```bash
$ bash webcube4.sh connect
[INFO] Getting index... done
[INFO] Logging in... done
[INFO] Connecting... done
[INFO] Success!
```

To disconnect:

```bash
$ bash webcube4.sh disconnect
[INFO] Getting index... done
[INFO] Logging in... done
[INFO] Disconnecting... done
[INFO] Success!
```

To reconnect:

```bash
$ bash webcube4.sh reconnect
[INFO] Getting index... done
[INFO] Logging in... done
[INFO] Disconnecting... done
[INFO] Connecting... done
[INFO] Success!
```

## License

**webcube4** is released under the MIT License.
