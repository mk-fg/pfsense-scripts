#!/bin/sh

# PFx_CHECK_IFACE must be pfSense interface
#  'Name' (as shown in WebUI), NOT e.g. em0 or internal id.

PFx_CHECK_IFACE=$1
PFx_CHECK_INTERVAL=${2:-60}

####################

usage() {
	bin=$(basename "$0")
	echo >&2 "Usage: $bin interface_label [check_interval]"
	echo >&2
	echo >&2 "Script to detect when interface goes down and restart it."
	echo >&2 "Restart is done via interface_reconfigure(), which cycles iface state down/up."
	echo >&2
	echo >&2 "Note that 'interface_label' must be pfSense interface"
	echo >&2 " 'Name' (as shown in WebUI), NOT e.g. em0 or internal id."
	echo >&2 "Default check_interval: 60"
	exit 1
}
[ -z "$PFx_CHECK_IFACE" -o "$1" = -h -o "$1" = --help ] && usage

PFx_NOBG=t
[ -z "$PFx_NOBG" ] && {
	export PFx_NOBG=t
	nohup "$0" "$@" >/dev/null &
	exit
}

export PFx_CHECK_IFACE
export PFx_CHECK_INTERVAL

while true; do
	touch /tmp/.run_check."$(basename "$0")"
	sleep "$PFx_CHECK_INTERVAL"
	sed '1,/^exit # php-script-start$/d' "$0" | php -q
done


exit # php-script-start
<?php

require_once('globals.inc');
require_once('functions.inc');
require_once('config.inc');
require_once('util.inc');

require_once('interfaces.inc');
require_once('filter.inc');


# PFx_DEBUG=t PFx_CHECK_IFACE=WAN script.php
$pfx_env_if_to_check = 'PFx_CHECK_IFACE';
$pfx_env_debug = 'PFx_DEBUG';


$pfx_debug = getenv($pfx_env_debug);
function echo_out($stuff) { echo "$stuff\n"; }
function echo_err($stuff) {
	global $echo_err_stream;
	if (!$echo_err_stream) $echo_err_stream = fopen('php://stderr', 'w+');
	fwrite($echo_err_stream, "$stuff\n"); }
function echo_debug($stuff) {
	global $pfx_debug;
	if ($pfx_debug) echo_err(is_string($stuff) ? $stuff : implode(' :: ', $stuff)); }


function pfx_main() {
	global $pfx_env_if_to_check;

	$if_to_check = getenv($pfx_env_if_to_check);
	if (!$if_to_check) { echo_err("ERROR: no $pfx_env_if_to_check defined in env"); exit; }

	$if_descrs = get_configured_interface_with_descr(false, true);
	foreach ($if_descrs as $if => $if_label) {
		if ($if_label !== $if_to_check) continue;

		$if_info = get_interface_info($if);
		$status = ($if_info['status'] == 'up' || $if_info['status'] == 'associated') && $if_info['ipaddr'] ? 'check-up' : 'check-down';
		echo_debug(array('iface_state_check', $if, $if_label, $status, $if_addr, $if_info['status']));

		if ($status !== 'check-up') {
			echo_debug(array('iface_restart', $if));
			interface_reconfigure($if, true); // reloadall=true
			filter_configure(); } } }

pfx_main();
