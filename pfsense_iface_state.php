#!/usr/local/bin/php -f

<?php

require_once('globals.inc');
require_once('functions.inc');
require_once('config.inc');
require_once('util.inc');
require_once('interfaces.inc');


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
	if ($pfx_debug) echo_err($stuff); }


function pfx_main() {
	global $pfx_env_if_to_check;

	$if_to_check = getenv($pfx_env_if_to_check);
	if (!$if_to_check) { echo_err("ERROR: no $pfx_env_if_to_check defined in env"); exit; }

	$if_descrs = get_configured_interface_with_descr(false, true);
	foreach ($if_descrs as $if => $if_label) {
		if ($if_label !== $if_to_check) continue;

		$if_info = get_interface_info($if);
		$if_addr = get_interface_ip($if);
		$status = ($if_info['status'] == 'up' || $if_info['status'] == 'associated') && $if_addr ? 'check-up' : 'check-down';
		echo_debug(implode(' :: ', array(
			'iface_state_check', $if, $if_label, $status, $if_addr, $if_info['status'] )));

		if ($status !== 'check-up') interface_reconfigure($if); } }

pfx_main();
