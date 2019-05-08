<?php
	/**
		Home API
		@copyright Copyright (C) 2018, Full Theft Auto
		@author Jack
		@link http://fulltheftauto.net
		@version 1.0
	*/

	include_once("./tools/mta_sdk.php");
	include("./tools/dbc_controller.php");

	$incoming = mta::getInput(); // Grab input data from what's coming in from remote call.
	$controller = new dbc();

	if ($incoming[0] === "CALL_HOME") {
		// check if a username and password was provided for auth
		$ip = $incoming[1];
		$key = $incoming[2];

		// Grab caller's IP
		if (!empty($_SERVER["HTTP_CLIENT_IP"])) {
			$callerIP = $_SERVER["HTTP_CLIENT_IP"];
		} elseif (!empty($_SERVER["HTTP_X_FORWARDED_FOR"])) {
			$callerIP = $_SERVER["HTTP_X_FORWARDED_FOR"];
		} else {
			$callerIP = $_SERVER["REMOTE_ADDR"];
		}

		// Check if the IP from the key authenticates to the IP from caller
		if ($ip === $callerIP) {

			error_log("Data from MTA | IP: $ip, Key: $key", 3, "/var/www/fulltheftauto.net/logs/home.log");

			// Double check types for input 0 and 1, and if that doesn't exist, grab the IP for authing.
			if (gettype($ip) === "string" && gettype($key) === "string") {
				// Check the auth, and get the status back
				$status = $controller->check_auth($ip,$key);
				error_log("Status: $status", 3, "/var/www/fulltheftauto.net/logs/home.log");

				if ($status === "PASSED") {
					mta::doReturn("AUTH_OKAY"); // Proceed with resource startup.
				} elseif ($status === "EXPIRED") {
					mta::doReturn("AUTH_EXPIRED"); // Notify console, license needs to be updated on network.
				} elseif ($status === "FAILED") {
					mta::doReturn("AUTH_KILL"); // Obsolete or pirated copy of resource, run self-destruct to remove from that network.
				} else {
					mta::doReturn("UNKNOWN_CODE"); // Database down / timed out. Alert to console.
				}
			} else {
				mta::doReturn("INTERNAL_ERROR"); // Data mismatch. Reported to web logs for further investigation.
			}
		} else {
			mta::doReturn("AUTH_IP_MISMATCH"); // License key being used on a different network than what it was assigned to.
		}
	} else if ($incoming[0] === "SERVER_EXEC") {

		mta::doReturn("Disabled.");

		/*$ip = $incoming[1];
		$port = $incoming[2];

		$outgoing = new mta($ip,$port);
		if ($outgoing) {
			$resource = $outgoing->getResource("odin");
			$rtn = $resource->call("network","exec",$incoming[3]);
			mta::doReturn($rtn);
		} else {
			mta::doReturn("false");
		}*/
	} else if ($incoming[0] == "GENERATE_AUTH") {
		if (!empty($_SERVER["HTTP_CLIENT_IP"])) {
			$IP = $_SERVER["HTTP_CLIENT_IP"];
		} elseif (!empty($_SERVER["HTTP_X_FORWARDED_FOR"])) {
			$IP = $_SERVER["HTTP_X_FORWARDED_FOR"];
		} else {
			$IP = $_SERVER["REMOTE_ADDR"];
		}
		mta::doReturn($IP); // Send IP back to console as there's no available method within the resource.
	} else {
		mta::doReturn("UNKNOWN_CODE"); // Unknown signal sent.
	}
?>
