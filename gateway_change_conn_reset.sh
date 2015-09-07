#!/bin/sh

PFx_CHECK_INTERVAL=${1:-60}
PFx_STATE_FILE=/tmp/.run_check."$(basename "$0")"

####################

usage() {
	bin=$(basename "$0")
	echo >&2 "Usage: $bin [check_interval]"
	echo >&2
	echo >&2 "Script to detect gateway change events and kill all"
	echo >&2 " connections going through the old one after that happens."
	echo >&2
	echo >&2 "Default check_interval: 60"
	exit 1
}
[ "$1" = -h -o "$1" = --help ] && usage

PFx_NOBG=t
[ -z "$PFx_NOBG" ] && {
	export PFx_NOBG=t
	nohup "$0" "$@" >/dev/null &
	exit
}

export PFx_CHECK_INTERVAL
export PFx_STATE_FILE

true >"$PFx_STATE_FILE"
while true; do
	sleep "$PFx_CHECK_INTERVAL"
	export PFx_IFACE_EXPECT="$(cat "$PFx_STATE_FILE")"
	gw_ifaces_new=$(sed '1,/^exit # php-script-start$/d' "$0" | php -q)
	echo "$gw_ifaces_new" >"$PFx_STATE_FILE"
done


exit # php-script-start
<?php

require_once('globals.inc');
require_once('functions.inc');
require_once('config.inc');
require_once('util.inc');

require_once('interfaces.inc');


# PFx_DEBUG=t PFx_IFACE_EXPECT='em0 em1' script.php
$pfx_env_iface_expect = 'PFx_IFACE_EXPECT';
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
	global $pfx_env_iface_expect;

	$iface_expect = getenv($pfx_env_iface_expect);

	$gw_def_ifaces = array();
	$gw_arr = return_gateways_array();
	foreach ($gw_arr as $gw_idx => $gw)
		if ($gw['defaultgw']) array_push($gw_def_ifaces, $gw['interface']);
	$gw_def_ifaces = array_unique($gw_def_ifaces);
	sort($gw_def_ifaces);

	echo_debug(array_merge(array('gw_ifaces'), $gw_def_ifaces));

	if ($iface_expect) {
		$gw_def_ifaces_old = explode(' ', $iface_expect);
		echo_debug(array_merge(array('gw_ifaces_old'), $gw_def_ifaces_old));
		$gw_ifaces_kill = array_diff($gw_def_ifaces_old, $gw_def_ifaces);
		foreach ($gw_ifaces_kill as $iface)
			echo_debug(array('rc.kill_states', $iface));
			shell_exec('/etc/rc.kill_states '.escapeshellarg($iface)); }

	echo_out(implode(' ', $gw_def_ifaces)); }

pfx_main();
