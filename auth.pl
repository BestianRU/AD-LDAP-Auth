#!/usr/bin/perl

    use Net::LDAP;


$user		= 'UserName';
$password	= 'pAssw0rD';
$host		= 'ADDomainControllerIPorName';
$domain		= 'DomainName';
$basedn		= 'DC=google,DC=com';
$group		= 'internet_users';

$check_group	= "1"; # 1 - Yes, 0 - No

$result = xldap_auth($host, $domain, $basedn, $user, $password);

if ($result eq 1){
    print "OK\n";
}else{
    print "ERR\n";
}

exit;

sub xldap_get_dn{
    local($ldap,$basedn,$xuser) = (shift, shift, shift);
    my $user="(samaccountname=$xuser)";
    $res = $ldap->search(base => $basedn, filter => $user, attrs => ['dn']);
    $res->code && die $res->error;
    foreach $entry ($res->entries){
	return $entry->dn;
    }
    return 0;
}

sub xldap_user_group_check{
    my($ldap, $userdn, $groupdn, $recurs_count) = (shift, shift, shift, shift, shift);
    my($entry, $res, $memof, $resx, @groups, @entry_dump, $ckl);

    if ($recurs_count<=0 ){
	return 0;
    }

    $res = $ldap->search(base => $userdn, filter => "(objectclass=*)", attrs => ['memberOf']);
    $res->code && die $res->error;

    foreach $entry ($res->entries){
	@groups=$entry->get_value('memberOf');
	for ($ck=0;$ckl<=$#groups;$ckl++){
	    $memof=$groups[$ckl];
	    if ($memof =~ /$groupdn/){
		return 1;
	    }else{
		if ( $recurs_count>1 ){
		    $resx = xldap_user_group_check($ldap, $memof, $groupdn,$recurs_count-1);
		    if ($resx eq 1){
			return 1;
		    }
		}
	    }
	}
    }
    return 0;
}

sub xldap_auth(){
    my($ad_host, $domain, $basedn, $user, $password) = (shift, shift, shift, shift, shift);

    if ($ldap) {
	$mesg	= $ldap->unbind;
    }

    $ldap	= Net::LDAP->new($ad_host.".".$domain) or die "$@";
    $mesg	= $ldap->bind( "$user\@$domain" ,password => "$password", version => 3) or die "$@";

    $userdn		= xldap_get_dn($ldap,$basedn,$user);

	if ($userdn =~ /CN/){
	    if ($check_group eq 1){
		$groupdn	= xldap_get_dn($ldap,$basedn,$group);
		$result		= xldap_user_group_check($ldap, $userdn, $groupdn,1);
		if ($result eq 1){
		    return 1
		}else{
		    $result		= xldap_user_group_check($ldap, $userdn, $groupdn, 16);
		    if ($result eq 1){
			return 1
		    }else{
			return -1
		    }
		}
	    }else{
		return 1
	    }
	}else{
		return -1
	}
}
