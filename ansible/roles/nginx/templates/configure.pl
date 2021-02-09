#!/usr/bin/perl


my $hostname = `cat /etc/hosts |grep 10.129.0.1 | /usr/bin/awk '{print \$2}'`;

#print $hostname;
chop ($hostname);


my $resolvedip = `host '$hostname' |awk '{print \$4}'`;

#print $resolvedip;

if ($resolvedip =~ /found:/)
	{
	$resolvedip = '';
	}

my $template = `cat server.ext.template`;

my $ips = `ip addr | awk '/inet / {print \$2}' | cut -f1 -d"/"` . $resolvedip;

#print $ips;

my @ips = split (/\n/g, $ips);


print "Creating SSL Certificate For $hostname: IPs\n";
print $ips;
sleep (2);

my $counter = 0;
foreach my $ip (@ips) 
	{
	if ($ip ne "127.0.0.1")
		{
		$counter++;
		$template .= "IP.$counter = $ip\n";
		}
	}

#print $template;

open (SAVE, ">server.ext");
print SAVE $template;
close (SAVE);


print "\n\nCreating Certificate Authority\n";
system ("openssl req -x509 -newkey rsa:2048 -out ca.cer -outform PEM -keyout ca.pvk -days 10000 -verbose -config ca.cnf -nodes -sha256 -subj '/CN=RelayTrust CA'");

print "\n\nCreating Server Keys\n";
system ("openssl req -newkey rsa:2048 -keyout /var/www/certificates/server.pvk -out server.req -subj /CN=localhost -sha256 -nodes");

print "\n\nCreating Final Certificate\n";
system ("openssl x509 -req -CA ca.cer -CAkey ca.pvk -in server.req -out /var/www/certificates/server.cer -days 10000 -extfile server.ext -sha256 -set_serial 0x1111");

print "\n\Testing Final Certificate\n";
system ("openssl s_server -accept 15 -cert /var/www/certificates/server.cer -key /var/www/certificates/server.pvk -CAfile ca.cer -WWW");

