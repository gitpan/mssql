# This file provides login id, passwd and server info for the test programs
# which C<require> this file.
# You may need to edit it, to make it fit you server, Don't forget to remove
# sensitive information once you've tested!


# Comment this if you don't want trusted connection.
MSSQL::DBlib::DBSETLSECURE();
$Uid = 'sa';     # Only matters is above is commented.
$Pwd = '';       # Ditto.
$Srv = '';       # Local server.

# Don't remove the 1, or else C<require> will fail!
1;

