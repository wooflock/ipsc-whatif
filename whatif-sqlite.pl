#!/usr/bin/perl -w

# whatif you had not made that NS, or made it 1 sec faster.
# perl to grab your data from SSI for a match together with the 
# other shooters and produce an excel sheet you can modify.

# needs mechanize and excel writer

use Data::Dumper;
use strict;
use WWW::Mechanize;
use Config::Simple;
use HTML::TokeParser;
use DBI;

# read in data from config file
# user, password, db3file,  and url for match.
my $configfile = "config.txt";
my %cfg;
Config::Simple->import_from($configfile, \%cfg) or die "can not read $configfile: $! \n";

# connect to db
my $dbh = DBI->connect(
    "dbi:SQLite:dbname=$cfg{'database'}",
    "",
    "",
    { RaiseError => 1 },
) or die $DBI::errstr;

# testing sqlite
my $sth = $dbh->prepare("SELECT SQLITE_VERSION()");
$sth->execute();
my $ver = $sth->fetch();
print @$ver;
print " sqlite db version\n";

# testing to login to SSI
print "Logging in to SSI with user $cfg{'username'}";
my $mech = WWW::Mechanize->new( autocheck => 1 );
$mech->get("https://shootnscoreit.com/login");
$mech->submit_form(
        form_number => 1,
        fields      => { username => $cfg{'username'}, password => $cfg{'password'} },
);
die unless ($mech->success);
print " OK!\n\n";

# now we go through all the urls.
# Fetching match data
my $murls = $cfg{'url'}; # murls = match urls
my $murl;
foreach $murl ( @$murls ) {
    print "Getting SSI match results for: $murl \n";
    get_match( $mech, $dbh, $murl );
}

$sth->finish();
$dbh->disconnect();


# check if we have this match already by url. if not add it.
sub get_match
{
    my $mech = shift;
    my $dbh = shift;
    my $murl = shift;
    
    # check if match already is in DB.
    $sth = $dbh->prepare("SELECT SSI_URL FROM match WHERE SSI_URL='$murl'" );
    $sth->execute();
    $sth->fetchrow();
    if ( $sth->rows() ) {
        # we have this match so we do not go ahead and fetch this data. return.
        print "Match with $murl already exists in database!\n";
        return;
    }
    
    # we add this match to database.
    $dbh->do("INSERT INTO match(SSI_URL) VALUES ('$murl')");
    my $match_MATCH_ID = $dbh->last_insert_id("", "", "match", "");

    # getting the match data from SSI
    $mech->get( $murl );

    # getting the links to the stages
    my @links = $mech->find_all_links( url_regex => qr/\/stage\// ); # stages:

    # getting the links to the competitors, and competitor info in %shooter
    my %shooter;
    my %match_shooter;
    my @Clinks = $mech->find_all_links( url_regex => qr/\/competitor\/all\// ); # comps;
    $mech->get( $Clinks[0]->url_abs );
    my $comppage = $mech->content();
    
    parse_shooters($comppage,\%shooter,\%match_shooter);

    # build the database of shooter_match. the shooters for this match.
    # we need ID first from match table.
    my $match_id = $match_MATCH_ID;
    # we need ID for MAJOR and MINOR
    $sth = $dbh->prepare("SELECT ID FROM powerfactor WHERE NAME='MAJOR'");
    $sth->execute();
    my $MAJOR = $sth->fetchrow();
    $sth = $dbh->prepare("SELECT ID FROM powerfactor WHERE NAME='MINOR'");
    $sth->execute();
    my $MINOR = $sth->fetchrow();
    # we also need id for division (production etc)
    $sth = $dbh->prepare("SELECT * FROM division");
    $sth->execute();
    my %divisions;
    while( my ($division_id,$division_name) = $sth->fetchrow() ) {
        $divisions{$division_id} = $division_name;
    }
    # now insert it...
    my @shoot_links = $mech->find_all_links( url_regex => qr/\/ipsc\/competitor\// );
    foreach my $shooter_start_id ( keys %match_shooter ) {
        # return to the shooter page!

        my $MATCH_ID = $match_id;
        my $SHOOTER_START_ID = $shooter_start_id;
        my $tNAME = $match_shooter{$shooter_start_id}{'first'} . " " . $match_shooter{$shooter_start_id}{'last'};
        my $NAME = $dbh->quote($tNAME);
        my $ms_division = $match_shooter{$shooter_start_id}{'division'};
        my $DIVISION_ID = "error";
        foreach my $key (keys %divisions) {
            if ($ms_division =~ /$divisions{$key}/i ) {
                $DIVISION_ID = $key;
            }
        }
        if ($DIVISION_ID eq "error") { die " can not parse shooter $NAME\n"; }
        my $POWER_FACTOR_ID;
        if ($ms_division =~ /\+/ ) {
            $POWER_FACTOR_ID = $MAJOR; }
        else {
            $POWER_FACTOR_ID = $MINOR;
        }
    
        # now lets gets follow the url from ssi to get the page on the shooter.
        # Get the shooters unique ssi address (diffrent from the competition address for the shooter..
        my $shooter_url = $match_shooter{$shooter_start_id}{'url'};
        #my @shoot_links = $mech->find_all_links( url_regex => qr/\/ipsc\/competitor\// );
        my $shooter_url_complete = 0;
        foreach my $slt (@shoot_links) {
            my $sl = $slt->url_abs();
            if ( $sl =~ /$shooter_url/ ) {
                $shooter_url_complete = $sl;
            }
        }
        if ($shooter_url_complete ) {
            # there is a working link. Lets go get that shooter.
            #print "$shooter_url_complete \n";
            $mech->get( $shooter_url_complete );
            my @user_links = $mech->find_all_links( url_regex => qr/\/users\// );
            my $SSI_URL = $user_links[0]->url_abs();
            
            # try to get some more details from the shooter page. later
            
        
            # now check if they exist before we enter them in the database again.
            $sth = $dbh->prepare("SELECT ID, SSI_URL FROM shooter WHERE SSI_URL='$SSI_URL'");
            $sth->execute();
            my ($id, $search_result) = $sth->fetchrow();
            unless( $search_result ) {
                # already exists.
                $dbh->do("INSERT INTO shooter(NAME,SSI_URL) VALUES($NAME,'$SSI_URL')");
                $id = $dbh->last_insert_id("", "", "shooter", "");
            }
            $dbh->do("INSERT INTO shooter_match(SHOOTER_START_ID,SHOOTER_ID,NAME,MATCH_ID, DIVISION_ID, POWERFACTOR_ID) VALUES($SHOOTER_START_ID,$id,$NAME,$MATCH_ID, $DIVISION_ID, $POWER_FACTOR_ID)");
            # we need to get shooter_match_id for stage_score table
        
        
        } else {
            print "shooter added to shooter_match table, but not to shooter table\n";
            # we did not get a URL so we only have his data for the match and not for the other table.
            $dbh->do("INSERT INTO shooter_match(SHOOTER_START_ID,NAME,MATCH_ID, DIVISION_ID, POWERFACTOR_ID) VALUES($SHOOTER_START_ID,$NAME,$MATCH_ID, $DIVISION_ID, $POWER_FACTOR_ID)");
        }
    
    }

    # Now shooter data is ready. Now we need to add all the match data for this match.
    # it goes into stage and stage score. the $match_MATCH_ID exists already.

    # getting rid of multiple entries of the same URL
    my %doneurls;
    foreach my $link ( @links )
    {
        my $stagelink = $link->url_abs;
        if (exists $doneurls{$stagelink} ) { 
            $doneurls{$stagelink}++; 
        } else { 
            $doneurls{$stagelink} = 1;
        }
    }

    my $stagecount = 0;
    foreach my $uurl (keys %doneurls) {
        $mech->get( $uurl );
        my $stagepage = $mech->content();
        parse_stage($stagepage, \%shooter,$dbh,$uurl,$match_MATCH_ID);

        $stagecount++;
    }
    
}

sub parse_shooters
{
    my $page = shift;
    my $shooters = shift;
    my $match_shooters = shift;
    my $stream = HTML::TokeParser->new( \$page ) or die $!;
    my $tag;
    my $ttag;
    $stream->get_tag('body');
    $stream->get_tag('table');
    $stream->get_tag('tbody');
    while ( $tag = $stream->get_tag("tr") ) {
        $tag = $stream->get_tag('td');
        my $snr = $stream->get_trimmed_text('/td');
        
        $tag = $stream->get_tag('td');$tag = $stream->get_tag('a');
        my $url = $tag->[1]{'href'};
        my $first = $stream->get_trimmed_text('/a');
        if($first =~ /support\@/ ) { return; }
        
        $tag = $stream->get_tag('td');$tag = $stream->get_tag('a');
        my $last = $stream->get_trimmed_text('/a');
        if($first =~ /support\@/ ) { return; }
        
        $tag = $stream->get_tag('td');
        my $div = $stream->get_trimmed_text('/td');
        $$shooters{$snr} = $div;
        $$match_shooters{$snr}{'division'} = $div;
        $$match_shooters{$snr}{'last'} = $last;
        $$match_shooters{$snr}{'first'} = $first;
        $$match_shooters{$snr}{'url'} = $url;
    }
}

sub parse_stage
{
    my $page = shift;
    my $shooters = shift;
    my $dbh = shift;
    my $STAGE_URL = shift;
    my $MATCH_ID = shift;
    my %shooter;
    my $stream = HTML::TokeParser->new( \$page ) or die $!;
    my $tag;
    my $MAXROUNDS;
    
    # getting stage title
    $stream->get_tag('body');
    $stream->get_tag('h1');
    my $tNAME = $stream->get_trimmed_text('/h1');
    my $NAME = $dbh->quote($tNAME);
    print "\tGetting stage: $NAME\n";
    
    # trying to get the Max points from the page.
    $stream->get_tag('hr');
    $stream->get_tag('div');
    $stream->get_tag('div');
    $stream->get_tag('div');
    $stream->get_tag('p');
    my $maxrounds_text = $stream->get_trimmed_text('/p');
    my @textarr = split(/\:/,$maxrounds_text);
    if ($textarr[2] =~ /(\d+)/) {
        $MAXROUNDS = $1;
        #print "max points: $MAXROUNDS \n";
    }
    
    #print "INSERT INTO stage(MATCH_ID,NAME,STAGE_URL,MAXROUNDS) VALUES($MATCH_ID,$NAME,'$STAGE_URL',$MAXROUNDS) \n";
    # ok, we now add the stage info into stage
    $dbh->do("INSERT INTO stage(MATCH_ID,NAME,STAGE_URL,MAXROUNDS) VALUES($MATCH_ID,$NAME,'$STAGE_URL',$MAXROUNDS)");
    my $STAGE_ID = $dbh->last_insert_id("", "", "stage", "");
    
    # now we have what we need and can get shooter data for the stage_result table
    # we need
    
    $stream->get_tag("table");
    $stream->get_tag("tbody");
    my $counter = 2;
    while ( $tag = $stream->get_tag("tr") ) {
                            
        $tag = $stream->get_tag('td');
        # this is the shooter start id, with the match id we get the shooter_match_id
        $shooter{'id'} = $stream->get_trimmed_text('/td');
        my $SHOOTER_START_ID = $shooter{'id'};
        my $sth = $dbh->prepare("SELECT ID FROM shooter_match WHERE SHOOTER_START_ID=$SHOOTER_START_ID AND MATCH_ID=$MATCH_ID");
        $sth->execute();
        my $SMID = $sth->fetchrow();
        
        $tag = $stream->get_tag('td');
        $tag = $stream->get_tag('a');
        
        #print " finding user with SMID $SMID ";
        #print  $stream->get_trimmed_text('/a');
        #print " ";
        $tag = $stream->get_tag('td');
        $tag = $stream->get_tag('a');
        #print $stream->get_trimmed_text('/a');
        #print "\n";
        $tag = $stream->get_tag('td');
        my $A = $stream->get_trimmed_text('/td');
        $tag = $stream->get_tag('td');
        my $C = $stream->get_trimmed_text('/td');
        $tag = $stream->get_tag('td');
        my $D = $stream->get_trimmed_text('/td');
        $tag = $stream->get_tag('td');
        my $MISS = $stream->get_trimmed_text('/td');
        $tag = $stream->get_tag('td');
        my $PROC = $stream->get_trimmed_text('/td');
        $tag = $stream->get_tag('td');
        my $NS = $stream->get_trimmed_text('/td');
        $tag = $stream->get_tag('td');
        $shooter{'POINTS'} = $stream->get_trimmed_text('/td');
        $tag = $stream->get_tag('td');
        my $TIME = $stream->get_trimmed_text('/td');
        $tag = $stream->get_tag('td');
        $shooter{'FACTOR'} = $stream->get_trimmed_text('/td');
        $tag = $stream->get_tag('td');
        $shooter{'VRF'} = $stream->get_trimmed_text('/td');
        
        $dbh->do("INSERT INTO stage_score(STAGE_ID,SHOOTER_MATCH_ID,A,C,D,MISS,NS,PROC,TIME) VALUES($STAGE_ID,$SMID,$A,$C,$D,$MISS,$NS,$PROC,'$TIME')");
        
        $counter++;
    }
}
