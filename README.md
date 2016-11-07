# tomtom-mysports-cloud-databox-driver
> Databox driver for the TomTom MySports Cloud.

A Databox driver for the TomTom MySports Cloud. Currently in development.

## Installation

TBC.

## Development setup

There are two routes available to development. The first is via 
[Vagrant](https://www.vagrantup.com/) which will set up a complete development
environment. Once you have the vagrant box up and running, you can build
the Docker container by running ``make`` in the ``/vagrant`` directory in the
box.

If you do not wish to use Vagrant, you will need the following installed:
* GNU Make
* [Docker](https://www.docker.com/)

You are then able to run ``make`` to build the Docker container. 

## Meta

Distributed under the ISC license. See ``LICENSE`` for more information.

Third Party Component Licenses:
* ``tinycore/docker.tcz`` contains software from [Docker][docker]
licensed under the [Apache 2.0 License][apache-2.0-license].
* ``tinycore/iptables.tcz`` contains software from [Netfilter][netfilter]
licensed under the [GNU GPLv2 License][gplv2-license].
* ``tinycore/opam.tcz`` contains software from [OPAM][opam]
licensed under the [GNU LGPLv2.1 License][lgplv2.1-license].

<https://github.com/me-box/tomtom-mysports-cloud-databox-driver>

[docker]: https://www.docker.com/
[apache-2.0-license]: https://github.com/docker/docker/blob/master/LICENSE
[netfilter]: https://www.netfilter.org/
[gplv2-license]: https://www.gnu.org/licenses/old-licenses/gpl-2.0.html
[opam]: https://opam.ocaml.org/
[lgplv2.1-license]: https://github.com/ocaml/opam/blob/master/LICENSE

