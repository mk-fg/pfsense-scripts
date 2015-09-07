pfsense-scripts
===============

Misc pfSense helper scripts.


pfsense_iface_state.sh
----------------------

Script to detect when interface goes down and restart it.

::

  % ./pfsense_iface_state.sh
  Usage: pfsense_iface_state.sh interface_label [check_interval]

  Script to detect when interface goes down and restart it.
  Restart is done via interface_reconfigure(), which cycles iface state down/up.

  Note that 'interface_label' must be pfSense interface
   'Name' (as shown in WebUI), not e.g. em0 or internal id.
  Default check_interval: 60

Just runs in an endless loop, checking specified interface state every N seconds
and restarting it if check fails.
