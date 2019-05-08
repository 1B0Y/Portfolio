<?php
	/**
		DBC Controller API
		@copyright Copyright (C) 2018, Full Theft Auto
		@author Jack
		@link http://fulltheftauto.net
		@version 1.0
	*/
	class dbc
	{
		private $host = "localhost";
		private $username = "authentication_handler";
		private $password = "***HIDDEN***";
		private $db_con;
		private $timestamp;

		public function __construct() {
			$this->db_con = new mysqli($this->host,$this->username,$this->password,"authentication_handler_table");
			$this->timestamp = new DateTime();

			if ($this->db_con->connect_errno) {
				error_log("Unable to connect to database: [ %s ]\n", $this->db_con->connect_error, 3, "/var/www/fulltheftauto.net/logs/dbc_controller.log");
			} else {
				error_log("Connection established!", 3, "/var/www/fulltheftauto.net/logs/dbc_controller.log");
			}
		}

		/**
		 * Authentication Checker
		 * USAGE: check_auth(string IP, string KEY)
		 * Checks if a license is still valid in the database, and returns the appropriate signals accordingly.
		 */
		function check_auth($ip, $key) {
			if ($this->db_con->connect_errno) {
				printf("Connection to db not online. Maybe __construct didn't call quick enough?", 3, "/var/www/fulltheftauto.net/logs/dbc_controller.log");
				return false; // Constructor will handle the error reporting.
			}

			error_log("Querying with data: IP: $ip - auth: $key...", 3, "/var/www/fulltheftauto.net/logs/dbc_controller.log");
			
			// Query
			$result = $this->db_con->query("SELECT expiry FROM auth_table WHERE auth='$key' AND IP='$ip' LIMIT 1");
			if (!$result) {
				error_log("There was an error while query for auth keys [" . $this->db_con->error . "]", 3, "/var/www/fulltheftauto.net/logs/dbc_controller.log");
				return "DB_FAILURE";
			} else {
				if ($result->num_rows === 0) {
					error_log("DBC: No results found. Returning none.", 3, "/var/www/fulltheftauto.net/logs/dbc_controller.log");
					return "FAILED"; // Potential pirated resource. Send kill signal to destroy files.
				};

				$row = $result->fetch_row();
				
				// Check timestamp
				if (intval($row[0]) === -1) { // Inexpirable license. Will stay in the database forever. Usually for developers or partnered providers.
					return "PASSED";
				} elseif(intval($row[0]) >= $this->timestamp->getTimestamp()) {
					return "PASSED";
				} elseif(intval($row[0]) < $this->timestamp->getTimestamp()) {
					return "EXPIRED"; // License expired. Log to console and close application.
				} else {
					error_log("No timestamp detected for $key. Investigation required.", 3, "/var/www/fulltheftauto.net/logs/dbc_controller.log");
					return "EXPIRED"; // No timestamp? Send EXPIRED signal back for now, and log to system.
				}
			}
		}

		/**
		 * Authentication Updater
		 * USAGE: update_auth(string IP, string AUTH, timestamp DURATION (or -1 for inf))
		 * Updates (or inserts) the license key in the database via the cPanel.
		 * [ TO BE DEVELOPED ]
		 */
		function update_auth($ip, $auth, $duration) {
			return true;
		}

		/**
		 * Authentication Invalidator
		 * USAGE: invalidate_auth(string IP, string AUTH, string REASON)
		 * Invalidates a license key in the database by setting it expired. Used for suspension reasons or pirated servers.
		 * [ TO BE DEVELOPED ]
		 */
		function invalidate_auth($ip, $auth, $reason) {
			return true;
		}
	}
?>