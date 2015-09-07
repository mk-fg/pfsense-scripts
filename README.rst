pfsense-scripts
===============

Misc ad-hoc helper scripts for `pfSense <https://www.pfsense.org/>`_ boxes.


.. contents::
  :backlinks: none


Installation
------------

The Right Way to install these scripts to pfSense machine is to upload them
through "Filer" package to ``/usr/local/etc/rc.d`` directory, with executable
bit and retaining ``.sh`` extension.

"Filer" package can be installed from WebUI's "System - Packages" menu.

After that, individual scripts should be uploaded through "Diagnostics - Filer"
WebUI form, with the following fields set:

* ``File: /usr/local/etc/<script_name>.sh``
* ``Permissions: 0755``
* ``File Contents: <script_contents>``
* ``Script/Command: /usr/local/etc/<script_name>.sh <script_args>``
* ``Description`` field can be filled with anything you like.

Substitute <scriptname> and <script_contents> above with name/contents for the
specific script and <script_args> with any parameters that it expects on the
command line (see script descriptions below for these).

Scripts that are configurable can also have values that can be changed when
copying script contents, usually at the very top.

Any scripts installed that way will be stored in the pfSense config, and can be
backed-up/restored along with all the other pfSense configuration parameters
(e.g. through "Diagnostics - Backup/restore" in WebUI).


Scripts
-------

Install these via "Filer" package, as described in the "Installation" section.

iface_check_restart.sh
``````````````````````

Script to detect when interface goes down and restart it::

  Usage: iface_check_restart.sh interface_label [check_interval]

Command-line arguments:

* interface_label: interface name, same as it is set/shown in pfSense WebUI.

  For example, default wan/lan interface names in pfSense are WAN and LAN.
  Upper/lower case matters.

* check_interval (optional): interval between iface state checks, in seconds.

  Default: 60

Example Filer's "Script/Command" setting (for WAN interface)::

  /usr/local/etc/iface_check_restart.sh WAN

Runs in an endless loop, checking specified interface state every N seconds and
restarting it if check fails.

Restart is done via ``interface_reconfigure($iface)`` from php, which cycles
iface state down/up.

gateway_change_conn_reset.sh
````````````````````````````

Script to detect when default gateway interface changes and forcefully kill all
connections still hanging throu old gateway interface::

  Usage: gateway_change_conn_reset.sh [check_interval]

Command-line arguments:

* check_interval (optional): interval gateway checks, in seconds.

  Default: 60

Runs in an endless loop, getting list of interfaces (os-level, e.g. em0) for
gateways marked as "defaultgw" and dumping list of these to a file in /tmp
(configurable in script via PFx_STATE_FILE), checking old contents of it against
this list and running ``/etc/rc.kill_states <iface>`` for interfaces that are
not longer used for default gw.
