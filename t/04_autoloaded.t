
BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use CGI::WML;
$loaded = 1;

$q = new CGI::WML;
print "ok 1\n";


($test = $q->header(-expires=>"+1s") )&& print "ok 2\n";
($test = $q->p("foobar") )&& print "ok 3\n";
($test = $q->br )&& print "ok 4\n";
($test = $q->table($q->tr($q->td("test"))) )&& print "ok 5\n";

