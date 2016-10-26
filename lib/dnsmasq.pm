package dnsmasq;
use Dancer ':syntax';
use strict;
use warnings;
use Cwd;
use Sys::Hostname;
use JSON;
use Encode qw( decode encode_utf8);

use examples::simple_form;
use examples::navbar_login;
use examples::tabs;
use examples::show_file;
use examples::photo_gallery;
use examples::markdown;
use examples::template_plugins;
use examples::error_handling;
use examples::dynamic_content;
use Data::Printer;
our $VERSION = '0.1';

sub ToJavascriptArray{ # change =>   [(aaa,aaa), (bbb,sss)]  -> [[aaa,aaa], [bbb,sss]]
    my @array = @_;
    my $result;
    my $count = 0;
    foreach my $element ( @array ){
        if ( $count eq 0 ){
            $result = "[";
        }
        $count++;
        $result .= "[ \"". @{$element}[0] . "\", \"" . @{$element}[1] ."\"]";

        if ($count eq scalar @array ){
            $result .= "]";
        }else {
            $result .= ",";
        }
    }

    return $result;

}

my $fileName  = "/etc/dynamic_host";
	
get '/' => sub {


	my @dns_now;
	open( fileHandle, $fileName ) || die "Cannot open $fileName.\n";
	while( my $aLine =<fileHandle> )
	{
		
#		my @fields = ($aLine =~ /^(address).*[=,]\/(.*)\/([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*)/ );
		my @fields = ($aLine =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})(\s+)(.*)/ );		
#		p @fields;

		my $ipaddr =  $fields[0];
		my $host =  $fields[2];	
		
		if (defined $host && defined $ipaddr){
			push @dns_now , [$ipaddr,$host];
		}

		  
	}
	close( fileHandle );  # 다 읽었으니 꼭 닫습니다. !!!!!

	p @dns_now;
	my %to_value;
	my $param_str = &ToJavascriptArray( @dns_now );
	p $param_str;
    if ( defined $param_str ){
        $to_value{"data_param_value"}  = $param_str;
    }else{
        $to_value{"data_param_value"}  = undef;
    }	
		
    template 'index', {
		dns_now => \@dns_now,
		data	=> \%to_value
    };
};


post '/modify' => sub {
    my $body = request->body;
    my $params = request->params;

    p $body;
    

#    my $json = decode('utf-8', from_json( $body ));
    my $json =  from_json( $body );

    my %config;
    my $result;


    my $data_param_value   = $json->{'data_param_value'};
    my %param_data;
    
	#my $fileName  = "/etc/dnsmasq.d/dns_host";
	open (WRITE, ">$fileName") ;    	
    foreach my $param ( @{$data_param_value}){
    
        my $length =  scalar @{$data_param_value};       
		my $ipaddr = @{$param}[0];
		my $host = @{$param}[1];
	
		print WRITE "\n$ipaddr $host";
        $param_data{@{$param}[0]} = @{$param}[1];
        
    }
    close(WRITE);
    p %param_data;

    $result->{status} = "OK";
    my $encode_json = encode_json $result;
	system('kill -HUP `cat /var/run/dnsmasq/dnsmasq.pid`');
    content_type 'application/json';
    return decode('utf-8',$encode_json);


};


get '/deploy' => sub {
    template 'deployment_wizard', {
		directory => getcwd(),
		hostname  => hostname(),
		proxy_port=> 8000,
		cgi_type  => "fast",
		fast_static_files => 1,
	};
};

#The user clicked "updated", generate new Apache/lighttpd/nginx stubs
post '/deploy' => sub {
    my $project_dir = param('input_project_directory') || "";
    my $hostname = param('input_hostname') || "" ;
    my $proxy_port = param('input_proxy_port') || "";
    my $cgi_type = param('input_cgi_type') || "fast";
    my $fast_static_files = param('input_fast_static_files') || 0;

    template 'deployment_wizard', {
		directory => $project_dir,
		hostname  => $hostname,
		proxy_port=> $proxy_port,
		cgi_type  => $cgi_type,
		fast_static_files => $fast_static_files,
	};
};

true;
