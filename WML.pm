package CGI::WML;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $USEXMLPARSER);

$USEXMLPARSER=1;

use CGI;
if ($USEXMLPARSER) {
    use XML::Parser;
}
use HTML::TokeParser;
use IO::Handle;
use IO::File;
use Carp;
use strict;
#no strict 'vars';
no strict 'subs';

require Exporter;

@ISA = qw(Exporter CGI);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
);


$VERSION = do{my@r=q$Revision: 0.02 $=~/\d+/g;sprintf '%d.'.'%02d'x$#r,@r};

my $DEFAULT_DTD     = '-//WAPFORUM//DTD WML 1.1//EN';
my $DEFAULT_DTD_URL = 'http://www.wapforum.org/DTD/wml_1.1.xml';

my $DOTABLE = 0; #use string tables. do not change, stringtables not done.
my ($WBML_RETBUFF,%STRTAB);

# Wireless Binary Markup Language, as defined in WAP forum docs
my $WBML_INLINE_STRING     = 0x03;
my $WBML_INLINE_STRING_END = 0x00;
my $WBML_STRINGTABLE_REF   = 0x83;
my $WMLTC_ATTRIBUTES       = 0x80;
my $WMLTC_CONTENT          = 0x40;
my $WMLTC_END              = 0x01;

 
my %WBML_TAGS = (
        'a' => '29',
	'td' => '30',
	'tr' => '31',
	'table' => '32',
	'p' => '33',
	'postfield' => '34',
	'anchor' => '35',
	'access' => '36',
	'b' => '37',
	'big' => '38',
	'br' => '39',
	'card' => '40',
	'do' => '41',
	'em' => '42',
	'fieldset' => '43',
	'go' => '44',
	'head' => '45',
	'i' => '46',
	'img' => '47',
	'input' => '48',
	'meta' => '49',
	'noop' => '50',
	'prev' => '51',
	'onevent' => '52',
	'optgroup' => '53',
	'option' => '54',
	'refresh' => '55',
	'select' => '56',
	'small' => '57',
	'strong' => '58',
	'UNUSED' => '59',
	'template' => '60',
	'timer' => '61',
	'u' => '62',
	'setvar' => '63',
	'wml' => '64');

my %WBML_ATTRS = (
        'accept-charset' => '6',
	'align="bottom"' => '7',
	'align="center"' => '8',
	'align="middle"' => '9',
	'NULL,' => '10',
	'align="right"' => '11',
	'align="top"' => '12',
	'alt' => '13',
	'content' => '14',
	'NULL,' => '15',
	'domain' => '16',
	'emptyok="false"' => '17',
	'emptyok-"true"' => '18',
	'format' => '19',
	'height' => '20',
	'hspace' => '21',
	'ivalue' => '22',
	'iname' => '23',
	'NULL,' => '24',
	'label' => '25',
	'localsrc' => '26',
	'maxlength' => '27',
	'method="get"' => '28',
	'method="post"' => '29',
	'mode="nowrap"' => '30',
	'mode="wrap"' => '31',
	'multiple="false"' => '32',
	'multiple="true"' => '33',
	'name' => '34',
	'newcontext="false"' => '35',
	'newcontext="true"' => '36',
	'onpick' => '37',
	'onenterbackward' => '38',
	'onenterforward' => '39',
	'ontimer' => '40',
	'optional="false"' => '41',
	'optional="true"' => '42',
	'path' => '43',
	'NULL,' => '44',
	'NULL,' => '45',
	'NULL,' => '46',
	'scheme' => '47',
	'sendreferer="false"' => '48',
	'sendreferer="true"' => '49',
	'size' => '50',
	'src' => '51',
	'ordered="true"' => '52',
	'ordered="false"' => '53',
	'tabindex' => '54',
	'title' => '55',
	'type' => '56',
	'type="accept"' => '57',
	'type="delete"' => '58',
	'type="help"' => '59',
	'type="password"' => '60',
	'type="onpick"' => '61',
	'type="onenterbackward"' => '62',
	'type="onenterforward"' => '63',
	'type="ontimer"' => '64',
	'NULL,' => '65',
	'NULL,' => '66',
	'NULL,' => '67',
	'NULL,' => '68',
	'NULL,' => '69',
	'NULL,' => '70',
	'type="prev"' => '71',
	'type="reset"' => '72',
	'type="text"' => '73',
	'type="vnd"' => '74',
	'href' => '75',
	'href="http://' => '76',
	'href="https://' => '77',
	'value' => '78',
	'vspace' => '79',
	'width' => '80',
	'xml:lang' => '81',
	'NULL,' => '82',
	'align' => '83',
	'columns' => '84',
	'class' => '85',
	'id' => '86',
	'forua="false"' => '87',
	'forua="true"' => '88',
	'src="http://' => '89',
	'src="https://' => '90',
	'http-equiv' => '91',
	'http-equiv="Content-Type"' => '92',
	'content="application/vnd.wap.wmlc;charset=' => '93',
	'http-equiv="Expires"' => '94');

my %WBML_VALUES = (
        '.com/' => '134',
	'.edu/' => '135',
	'.net/' => '136',
	'.org/' => '137',
	'accept' => '138',
	'bottom' => '139',
	'clear' => '140',
	'delete' => '141',
	'help' => '142',
	'http://' => '143',
	'http://www.' => '144',
	'https://' => '145',
	'https://www.' => '146',
	'NULL' => '147',
	'middle' => '148',
	'nowrap' => '149',
	'onpick' => '150',
	'onenterbackward' => '151',
	'onenterforward' => '152',
	'ontimer' => '153',
	'options' => '154',
	'password' => '155',
	'reset' => '156',
	'NULL' => '157',
	'text' => '158',
	'top' => '159',
	'unknown' => '160',
	'wrap' => '161',
	'www.' => '162');

my %WBML_NO_CLOSE_TAGS = (
    'br' => '1',
	'noop' => '1',
	'prev' => '1',
	'img' => '1',
	'meta' => '1',
	'timer' => '1',
    'setvar' => '1');

# HTML->WML conversion constants
# Ignore these HTML and iMode tags completely.
my %IGNORE_TAG = map {$_ => 1} qw(abbr acronym address applet area basefont
				  bdo body cite col colgroup del dfn dir div
				  dl dt fieldsset font frame frameset head
				  html iframe legend link noframes noscript 
				  object param script span style textarea
				  tfoot thead var);

# Straightforward one to one tag mapping
my %TAGMAP = map {$_ => 1} qw(em strong i b u big small table tr td); 


my (%Open_Tags,$Open_Form_Url,@Open_Vars,%Hidden_Vars);


### 
##  End of global variable setting. 
###

sub new {
    my ($self, $initializer, @param) = @_;
    $CGI::USE_PARAM_SEMICOLONS++;
    return $CGI::Q = $self->SUPER::new($initializer, @param);
}

sub DESTROY { }

### Method: header
# Override the CGI.pm header default with the WML one.
# Contributed by Wilbert Smits <wilbert@telegraafnet.nl>
###
sub header {
    my($self,@p) = &CGI::self_or_default(@_);
    my($type, @leftover) = rearrange([TYPE],@p);
    my %leftover;
    foreach (@leftover) {
        next unless my($header,$value) = /([^\s=]+)=\"?([^\"]+)\"?/;
        $leftover{$header} = $value;
    }
    if(!defined $type) {$type = "text/vnd.wap.wml"}
    return $self->SUPER::header("-type"=>$type, %leftover);
}




### Method: start_wml
# Guess what this does!
###
sub start_wml {
    my($self,@p) = &CGI::self_or_default(@_);
    my($meta,$cardid,$dtd,$dtd_url,$lang,$encoding) =
	rearrange([META,CARDID,DTD,DTD_URL,LANG,ENCODING],@p);
    
    if (!defined $encoding) { $encoding="iso-8859-1";}
    
    my(@result);
    push @result,qq(<?xml version="1.0" encoding="$encoding"?>);
    $dtd = $DEFAULT_DTD unless $dtd && $dtd =~ m|^-//|;
    $dtd_url = $DEFAULT_DTD_URL unless $dtd_url && $dtd_url =~ m|^http|;
    push(@result,qq(\n<!DOCTYPE wml PUBLIC "$dtd" 
	            "$dtd_url">\n)) if $dtd && $dtd_url;

    push(@result,qq(<wml));
    push(@result,qq(xml:lang="$lang")) if (defined $lang);
    push(@result,">");

    if (defined $meta) {
        push(@result,"<head>");
        if ($meta && ref($meta) && (ref($meta) eq 'HASH')) {
            foreach (keys %$meta) {
                push(@result,qq(<meta $_ $meta->{$_}/>\n));
            }
        }
        push(@result,"</head>");
    }

    return join(" ",@result);
}


### Method: card
# make a complete WML card
####
sub card {
    my ($self,@p) = &CGI::self_or_default(@_);
    my ($id,$title,$content,$ontimer,$timer,$onenterforward,$onenterbackward,
	$newcontext,$ordered,$class,$lang) =
        rearrange([ID,TITLE,CONTENT,ONTIMER,TIMER,ONENTERFORWARD,ONENTERBACKWARD,NEWCONTEXT,ORDERED,CLASS,LANG],@p);
    
    my @ret;
 
    push(@ret,qq(\n<card id="$id"));
    push(@ret,qq(title="$title")) if (defined $title);
    push(@ret,qq(newcontext="$newcontext")) if (defined $newcontext);
    push(@ret,qq(ontimer="$ontimer")) if (defined $ontimer);
    push(@ret,qq(onenterforward="$onenterforward"))if(defined $onenterforward);
    push(@ret,qq(onenterbackward="$onenterbackward"))if(defined $onenterbackward);
    push(@ret,qq(xml:lang="$lang")) if (defined $lang);
    push(@ret,qq(ordered="$ordered")) if (defined $ordered);
    push(@ret,qq(class="$class")) if (defined $class);

    push(@ret,qq(>));
    push(@ret,qq($timer)) if (defined $timer);
    push(@ret,qq( $content </card>)) if (defined $content);

    return join (" ",@ret);
    
}


### Method: dialtag
# make a 'call this number' tag
####
sub dialtag {
    my ($self,@p) = @_;
    my ($number,$label) = rearrange([NUMBER,LABEL],@p);
    
    $label = $number unless (defined $label);
    my $ret = "<anchor>$label<go href='wtai://wp/mc/;$number'/></anchor>";
    return $ret;
}


### Method: do
# make a 'do' tag
####
sub do {
    # Oh no! Geoworks patent infringment ahead!
    my ($self,@p) = @_;
    my ($type,$class,$label,$name,$content,$optional) = 
	rearrange([TYPE,CLASS,LABEL,NAME,CONTENT,OPTIONAL],@p);

    my @ret;
    push(@ret,qq(<do type="$type"));
    push(@ret,qq(optional="$optional")) if (defined $optional);
    push(@ret,qq(name="$name")) if (defined $name);
    push(@ret,qq(class="$class")) if (defined $class);
    push(@ret,qq(label="$label")) if (defined $label);
    push(@ret,qq(>$content</do>));

    return join(" ",@ret);
}

    
### Method: template
# make a 'template' card for a deck
####
sub template {
    my ($self,@p) = @_;
    my ($content) = rearrange([CONTENT],@p);
    
    my @ret;
    push(@ret,qq(<template>$content</template>));

    return join(" ",@ret);
}

### Method: go
# Make a 'go' block
###
sub go {
    my ($self,@p) = @_;
    my ($method,$href,$postfields) = CGI::rearrange([METHOD,HREF,POSTFIELDS],@p);

    my @ret;
    
    push(@ret,qq(<go href="$href"));
    push(@ret,qq(method="$method")) if (defined $method);
    
    if (defined $postfields) {
      if ($postfields && ref($postfields) && (ref($postfields) eq 'HASH')) {
          push(@ret,">");
          foreach (keys %$postfields) {
              push(@ret,qq(<postfield name="$_" value="$postfields->{$_}"/>));
          }
      }
      push(@ret,"</go>");
    } else {
      push(@ret,"/>");
    }
   
    return join(" ",@ret);
}

### Method: prev
# Canned "back" method
###
sub prev {
    my ($self,@p) = @_;
    my ($label) = rearrange([LABEL],@p);

    my $ret = qq(<do type="accept" label="Back"><prev/></do>);
    $ret =~ s/Back/$label/ if (defined $label);
    
    return $ret;

}

sub back {
   &prev;
}

### Method: timer
# Make a WML timer element
####
sub timer {
    my ($self,@p) = @_;
    my ($name,$value) = rearrange([NAME,VALUE],@p);
    
    return qq(<timer name="$name" value="$value"/>);
}


#### Method: end_wml
# End an WML document.
# Trivial method for completeness.  Just returns "</wml>"
####
sub end_wml {
    return "</wml>\n";
}

# AJM Added a new line to terminate the file
#### Method: input
# Make a text-entry box.
####

sub input {
    my ($self,@p) = @_;
    my ($name,$value,$type,$format,$title,$size,$maxlength,$emptyok) =
     rearrange([NAME,VALUE,TYPE,FORMAT,TITLE,SIZE,MAXLENGTH,EMPTYOK],@p);
    
 
    my @ret;
    push(@ret,qq(<input name="$name"));
    push(@ret,qq(value="$value")) if (defined $value);
    push(@ret,qq(type="$type")) if (defined $type);
    push(@ret,qq(format="$format")) if (defined $format);
    push(@ret,qq(title="$title")) if (defined $title);
    push(@ret,qq(size="$size")) if (defined $size);
    push(@ret,qq(emptyok="$emptyok")) if (defined $emptyok);
    push(@ret,qq(maxlength="$maxlength")) if (defined $maxlength);
    push(@ret,qq(/>));

    return join(" ",@ret);
}


#### Method: onevent
# Make an "onevent" block
####

sub onevent {
    my ($self,@p) = @_;
    my ($type,$content) = rearrange([TYPE,CONTENT],@p);


    return qq(<onevent type="$type">$content</onevent>);
}


### Method: img
# make an image tag
####
sub img {
    my ($self,@p) = @_;
    my ($alt, $src, $localsrc, $vspace, $hspace, $align, $height, $width) =
        rearrange([ALT, SRC, LOCALSRC, VSPACE, HSPACE, ALIGN, HEIGHT, WIDTH],@p);
    my @ret;
    $alt = "image" if (! defined $alt); # alt text is manditory in WML

    push (@ret,qq(<img));
    push (@ret,qq(alt="$alt"))           if (defined $alt);
    push (@ret,qq(src="$src"))           if (defined $src);
    push (@ret,qq(localsrc="$localsrc")) if (defined $localsrc);
    push (@ret,qq(vspace="$vspace"))     if (defined $vspace);
    push (@ret,qq(hspace="$hspace"))     if (defined $hspace);
    push (@ret,qq(align="$align"))       if (defined $align);
    push (@ret,qq(height="$height"))     if (defined $height);
    push (@ret,qq(width="$width"))       if (defined $width);
    push (@ret,qq( />));
    return join(" ",@ret);

}

sub p {
    my ($self, @p) = @_;

    my ($content, $align, $mode) = rearrange([CONTENT, ALIGN, MODE], @p);
    my @ret;

    push ( @ret, qq(<p));
    push ( @ret, qq(align="$align")) if $align;
    push ( @ret, qq(mode="$mode"))   if $mode;    
    push ( @ret, qq(>$content</p>));
    return join (" ", @ret);  
} 






#### Method: wml_to_wmlc
# Convert textal WML to binary WML, not indented to replace the WML
# compiler on the gateway.
####

sub wml_to_wmlc {

    my ($streamheader,$wbml,$parser,$testparser,$stringtable);
    my ($self,@p) = @_;
    my ($wml,$errorcontext) = rearrange([WML,ERRORCONTEXT],@p);
 
    if ($USEXMLPARSER == 0) {
        croak("Error: Routine disabled at installation.");
        return undef;
    }
    
    (defined $errorcontext) || ($errorcontext = 0);
    $parser = new XML::Parser(ErrorContext=>$errorcontext);

    
    # Stringtable work not done yet.
    $stringtable = "";
    
    $WBML_RETBUFF = sprintf("%c%c%c%c%s",
			    0x01,   # Version number
			    0x04,   # "Unknown public identifier"
			    0x6A,   # Charset (UTF-8)
			    length($stringtable), # Number of bytes in table
			    $stringtable);
    

    $parser->setHandlers(Start=>\&wml_start,
                         End=>\&wml_end,
                         Char=>\&wml_char,
                         Final=>\&wml_final);
    

    #$wml =~ s/\r/ /g;
    #$wml =~ s/\n/ /g;
    
    $testparser = eval '$parser->parse($wml); return 1';
    
    if (!defined $testparser) {
        warn ("Error: XML parser failed. Bad WML ?\n");
        if ($errorcontext) {
            # This is going to throw a die(), since we know the
            # document is not well formed.
            $parser->parse($wml);
        }
        return undef;
    } else {
        return $WBML_RETBUFF;
    }
    
}

###
# Non-public function, used by wml_to_wmlc.
# Does the job of returning the buffer of WBML to the calling routine.
###
sub wml_final {
    return $WBML_RETBUFF;
}

### 
# Non-public function, used by wml_to_wmlc
# Called by start of tag XML event, encodes tag and property/value pairs
###
sub wml_start {
    
    my ($parser,$element,@props) = @_;
    my ($tok,$prop,$val,$propandval,$count);

    
    # Get the element token, and say wether it has contents and/or 
    # attributes. 
    $tok = $WBML_TAGS{$element};
    if (! defined($WBML_NO_CLOSE_TAGS{$element})) { 
        $tok |= $WMLTC_CONTENT;
    }
        
    if (scalar(@props) > 0) { $tok |= $WMLTC_ATTRIBUTES;}

    $WBML_RETBUFF .= chr($tok);
    
    for ($count = 0 ; $count < scalar(@props); $count++) {
        $prop = $props[$count];
        $val = $props[++$count];
        $propandval = $prop."=\"".$val."\"";
        $propandval =~ s/\ //g;
	
	# Look for a single attib val first, and if not, break it in
	# to parts and tokenise them.
	
        if ($WBML_ATTRS{$propandval}) { # We got a single value

            $WBML_RETBUFF .= chr($WBML_ATTRS{$propandval});
	    
        }else{  # Break it up and encode the parts
	    
            $WBML_RETBUFF .= chr($WBML_ATTRS{$prop});
	    
            if ($WBML_VALUES{$val}) {
                $WBML_RETBUFF .= chr($WBML_VALUES{$val});
            }else{
                #if ($prop =~ /href/){ # Special case for URLS
                #    if ($val =~ /^http\:\/\//) {
                #	accum(pack('c',chr($WBML_VALUES{"http://"})));
                #	$val =~ s%^http://%%g;
                #    }
                #}
                if ($WBML_VALUES{$val}) {
                    $WBML_RETBUFF .= chr($WBML_VALUES{$val});
                } else {
                    if ($STRTAB{$val}) {
                        $WBML_RETBUFF .= pack('CC',
					    $WBML_STRINGTABLE_REF,
					    $STRTAB{$val});
                    } else {
                        $WBML_RETBUFF .= chr($WBML_INLINE_STRING);
                        $WBML_RETBUFF .= $val;
                        $WBML_RETBUFF .= chr($WBML_INLINE_STRING_END);
                    }
                }
            }
        }
    }
    
    if ($count) {
        # If there was an attribute list, we've got to mark it's 
        # end. Is there a better way of doing this? an Expat option perhaps?
        $WBML_RETBUFF .= chr($WMLTC_END);
    }
}

### 
# Non-public function, used by wml_to_wmlc
# Called by XML parser when an end-of-tag tag is hit.
###
sub wml_end {
    # Just return 0x01, unless it's in the "no closures" hash
    my ($parser,$tag) = @_;
    if (! defined($WBML_NO_CLOSE_TAGS{$tag})) {
        $WBML_RETBUFF .= chr($WMLTC_END);
    }
}    

### 
# Non-public function, used by wml_to_wmlc 
# Called by XML parser to encode strings within tags
# *INCOMPLETE* Ignore the string table stuff, it's incorrect and should
# not be used.
###
sub wml_char {
    my $parser = shift;
    my $charstr = shift;
    my ($char,$buff,$f_white,$word);
    
    $char = $buff = "";
    $f_white = 0;
    
    # Strip out whitespace.
    $charstr =~ s/\s+/ /g;

    # If it's in the string table, then take it from there, else
    # add it in as an inline string.
    if  ($charstr !~ /^\s$/) { 
        if ($DOTABLE) {
            foreach $word (split(' ',$charstr)) {
                if (defined $STRTAB{$word}) {
                    $WBML_RETBUFF .=chr($WBML_INLINE_STRING).chr($STRTAB{$word});
                } else {
                    $WBML_RETBUFF .=chr($WBML_INLINE_STRING_END).$word.chr(0x00);
                }
            }
        } else {
            $WBML_RETBUFF .= chr(0x03).$charstr.chr(0x00);
        }
    }
}


sub rearrange {
    my($order,@param) = @_;

    return () unless @param;

    if (ref($param[0]) eq 'HASH') {
        @param = %{$param[0]};
    } else {
        return @param
            unless (defined($param[0]) && substr($param[0],0,1) eq '-');
    }

    # map parameters into positional indices
    my ($i,%pos);
    $i = 0;
    foreach (@$order) {
        foreach (ref($_) eq 'ARRAY' ? @$_ : $_) { $pos{$_} = $i; }
        $i++;
    }

    my (@result,%leftover);
    $#result = $#$order;  # preextend
    while (@param) {
        my $key = uc(shift(@param));
        $key =~ s/^\-//;
        if (exists $pos{$key}) {
            $result[$pos{$key}] = shift(@param);
        } else {
            $leftover{$key} = shift(@param);
        }
    }

    push (@result,CGI::make_attributes(\%leftover)) if %leftover;
    @result;
}


###
# HTML to WML conversion, not particularly good conversion though. YMMV
# Inspired by Taneli Leppa's "html2wml" distributed with the
# Kannel Open Source WAP gateway.
###

sub html_to_wml {

    my ($self,@p) = @_;
    my ($arg,$redirect_via,$redirect_var,$breaks_after_links) = rearrange([HTML,URL,VARNAME,LINKBREAKS],@p);

    my ($parser,$title,$content,$ioref,$tmp,$tmpfile);

    return undef unless (defined $arg);

    ($redirect_via = "0") if (!defined $redirect_via);
    ($redirect_var = "0") if (!defined $redirect_var);
    ($breaks_after_links = 0) if (!defined $breaks_after_links);

    if (ref($arg) and UNIVERSAL::isa($arg, 'IO::Handler')) {
        # We've got a filehandle.
        $ioref = $arg;
    } else {
        eval {
            $ioref = *{$arg}{IO};
        };
    }


    if (! defined $ioref ) {
        # We've got a scalar, put it in a tempfile.
	
        # Whipped from CGI.pm.

        # choose a relatively unpredictable tmpfile sequence number
        my $seqno = unpack("%16C*",join('',localtime,values %ENV));

        for (my $cnt=10;$cnt>0;$cnt--) {
            next unless $tmpfile = new TempFile($seqno);
            $tmp = $tmpfile->as_string;

            last if defined ($ioref = new IO::File "> $tmp");
            $ioref->autoflush(1);
	    
            $seqno += int rand(100);
        }

        croak("Can't get a tempfile") unless (defined $ioref);

        print $ioref $arg || croak ($!);
        $ioref->close;
        open($ioref,$tmp) || croak ($!);
    }

    $parser = HTML::TokeParser->new($ioref);
   
    $parser->get_tag("title");
    $title = $parser->get_text;
    $content  = html_to_wml_getcontent($self,$parser,$redirect_via,
                                       $redirect_var,$breaks_after_links);
    
    return ($title,$content);
    
    
}

### 
# Non-public function, used by 'convert' routine, extracts 
# text and does limited tag conversion.
###
sub html_to_wml_getcontent {
    
    my $self = shift;
    my $p = shift;
    my $redirect_via = shift;
    my $redirect_var = shift;
    my $breaks_after_links = shift;
    my ($wml,$wmlbit,$token,$tag);
    

    while ($token = $p->get_token) {
	if ($token->[1]) {
	    $_ = $token->[0];
	  TAGTYPE: {
	      /S/ && do { $wmlbit = _start_tag($self,$p,$token->[1],
					       $token->[2],
					       $redirect_via,
					       $redirect_var,
					       $breaks_after_links);
			  last TAGTYPE;
		      };
	      /E/ && do { $wmlbit = _end_tag($token->[1]);
			  last TAGTYPE;
		      };
	      /T/ && do { $wmlbit = $token->[1];
			  $wmlbit =~ s/\&copy\;/\(c\)/g;
			  chomp $wmlbit;
			  last TAGTYPE;
		      };
	  }  
	}
        $wml .= $wmlbit if $wmlbit;
    }
    
    foreach $tag (%Open_Tags) {
        if ( (defined $Open_Tags{$tag}) && ($Open_Tags{$tag} >= 1)) {
            $wml .="</$tag>";
        }
    }
    $wml .= "</p>";
    
    return $wml;
}

### 
# Non-public function, used by 'html_to_wml' routine
###
sub _start_tag {
    my $self = shift;
    my $p = shift;
    my $tag = shift;
    my $attrs = shift;
    my $redirect_via = shift;
    my $redirect_var = shift;
    my $breaks_after_links = shift;
   
    if ($breaks_after_links) {
        $breaks_after_links = "<br/>\n";
    }else{
        $breaks_after_links = "";
    }

    my ($y,$x,$type,$varname,%pfs);


    return "<p>" if (lc($tag) eq "body");

    return if $IGNORE_TAG{$tag};
    
    if ($TAGMAP{$tag}) {
        if ( (defined $Open_Tags{$tag}) && ($Open_Tags{$tag} > 1)) {
	    $Open_Tags{$tag}++;
	    return lc("</$tag><$tag>");
        }else{
	    $Open_Tags{$tag}++;
	    return lc("<$tag>");
        }
    }
    
    for ($tag) {
	
	# Tag-to-tag mapping.

        /^a$/ && do {
            $y = $attrs->{'href'};
	    $y =~ s%&%&amp;%g;

            if (defined $redirect_via) {
                 $y = qq($redirect_via?$redirect_var=$y);
            }
            return sprintf("<a href='%s' %s>%s",
                           $y,
                           ( (defined $attrs->{'accesskey'} ? 
                             "accesskey = '" . $attrs->{'accesskey'} . "'" :
                             "")),
                           $breaks_after_links);
        };
        
        /^img$/ && do {
            $y = $attrs->{'src'};
            $x = $attrs->{'alt'};
            $x = "image" unless $x;
            
            return "<$tag src='$y' alt='$x'/>";
	};
	
	/^hr$/ && do {
	    return "<br/>------<br/>";
	};
	
	/^dd$/ && do {
	    return "<br/>";
	};
	
	/^dl/ && do {
	    return "<br/>";
	};
	    

	/^form$/ && do {
	    $Open_Form_Url = $attrs->{'action'};
	    return "";
	};

	/^select$/ && do {
	    push @Open_Vars, $attrs->{'name'};
	    return sprintf("<select name='%s'>",$attrs->{'name'});
	};

	/^option$/ && do {
	    return
		sprintf ("<option value='%s'>%s</option>",
			 $attrs->{'value'},
			 $p->get_text);
	};



	/^input$/ && do {

	    # Transforming input tags isn't much fun.
	    $type = lc($attrs->{'type'});

	    ($type eq "hidden") && do {
		$Hidden_Vars{$attrs->{'name'}} = $attrs->{'value'};
	    };

	    ($type eq "text") && do {
		push @Open_Vars, $attrs->{'name'};
		return $self->input(-name=>$attrs->{'name'},
				    -value=>$attrs->{'value'},
				    -size=>$attrs->{'size'},
				    -maxlength=>$attrs->{'maxlength'});
	    };

	    
	    ($type eq "submit") && do{
		my $url = $Open_Form_Url;

		foreach $varname (@Open_Vars) {
		    $pfs{$varname} = "\$($varname:e)";
		}
		foreach $varname (keys %Hidden_Vars) {
		    $pfs{$varname} = $Hidden_Vars{$varname};
		}

		undef @Open_Vars;

		return $self->do(-type=>"accept",
				 -label=>($attrs->{'value'} || "Send"),
				 -content=>$self->go(-method=>"post",
						     -href=>$Open_Form_Url,
						     -postfields=>\%pfs));
	    };

	};

            
    }
}

### 
# Non-public function, used by 'html_to_wml' routine
###
sub _end_tag {
    
    my $tag = shift;
       

    return if $IGNORE_TAG{$tag};

    if ($TAGMAP{$tag}) {
        $Open_Tags{$tag}--;
        return lc("</$tag>");
    }
    
    for ($tag) {
	/^a$/     && return "</a>";
	/^p$/     && return "<br/>";
	/^h[0-9]/ && return "<br/>";
	/^dl$/    && return "<br/>";
	/^li$/    && return "<br/>";
	/^select$/&& return "</select>";
    }
    
    
}

















# Preloaded methods go here.




# Autoload methods go after =cut, and are processed by the autosplit program.

1;

__END__

=head1 NAME

CGI::WML - Subclass LDS's "CGI.pm" for WML output and WML methods

=head1 SYNOPSIS

  use CGI::WML;

  $q = new CGI::WML;

  print
     $q->header(),
     $q->start_wml(),
     $q->template(-content=>$q->prev()),
     $q->card(-id=>"first_card",
              -title=>"First card",
              -content=>"<p>Hello WAP world!</p>"),
     $q->card(-id=>"second",
              -title=>"Second Card",
              -content=>"<p>I am No2</p>"),
     $q->end_wml();

  print
     $q->wml_to_wmlc(-wml=>$wml_buffer,
                     -errorcontext=>2);

  ($title,$content) = $query->html_to_wml($buffer);

 

=head1 DESCRIPTION

This is a library of perl functions to allow CGI.pm-style programming
to be applied to WAP/WML. Since this is a subclass of Lincoln Stein's
CGI.pm all the normal CGI.pm methods are available. See B<perldoc CGI>
if you are not familiar with CGI.pm

The most up to date version of this module is available at
http://wap.z-y-g-o.com/tools/

=head1 FUNCTIONS

The library provides an object-oriented method of creating correct WML, 
together with some canned methods for often-used tasks. As this module
is a subclass of CGI.pm, the same argument-passing method is used, and
arguments may be passed in any order.


=head2 CREATING A WML DECK

=over 2

=item B<header()>

This function now overrides the default CGI.pm 'Content-type: ' header
to be 'text/vnd.wap.wml' by default. All the standard CGI.pm header functions
are still available for use.

print $query->header();

	-or-
print $query->header(-expires=>"+1m",
                     -cookie($q->cookie(-name=>"example",
                                        -value=>"123"),
                     -nph=>1);

WARNING: If you are mixing HTML and WML output in the same script you'll 
need to explicity set "text/html" as the content type where appropriate.
This is a change from pre 1.52 versions.


=item B<start_wml()>
Use the start_wml method to create the start of a WML deck, if you
wish you can pass paramaters to the method to define a custom DTD,
XML language value and any 'META' information. If a DTD is not specified
then the default is to use C<WML 1.1>


$query->start_wml(-dtd      =>'-//WAPFORUM//DTD WML 5.5//EN',
                  -dtd_url  => 'http://www.wapforum.org/DTD/wml_5.5.xml',
                  -lang     =>"en-gb",
                  -encoding =>"iso-8859-1",
                  -meta     =>{'scheme'=>'foobar',
                               'name'  =>'mystuff'});

=item B<end_wml()>

Use end_wml() to end the WML deck. Just included for completeness.

=back

=head2 CREATING WML CARDS

=over 2

=item B<card()>

Cards are created whole, by passing paramaters to the card() method, as
well as the card attributes, a timer may be added to the start of the 
card.

$query->card(-id=>"card_id",
             -title=>"First Card",
             -ontimer=>"#next_card",
             -timer=>$query->C<timer>(-name=>"timer1",-value=>"30"),
             -newcontext=>"true",
             -onenterforward=>"#somecard",
             -onenterbackward=>"#othercard",
             -content=>"<p>Hello WAP world</p>");

=head2 TEMPLATES

The template() method creates a template for placing at the start
of a card. If you just need to add a B<back> link, use the prev()
method.

$query->template(-content=>$q->prev(-label=>"Go Back"));

=head2 TIMERS

A card timer is used with the card() method to trigger an action, the
function takes two arguments, the name of the timer and it's value in
milliseconds.

$query->timer(-name=>"mytimer",
              -value=>"30");

=head2 GO BLOCKS

A E<lt>go block is created either as a single line

$query-E<gt>go(-method=>"get",
            -href=E<gt>"http://www.example.com/");
C<
E<lt>go href="http://www.example.com/" method="get"/E<gt>
>
or as a block

%pfs = ('var1'=E<gt>'1',
        'var2'=E<gt>'2',
        'varN'=E<gt>'N');

$query-E<gt>go(-method=E<gt>"post",
           -href=E<gt>"http://www.example.com/",
           -postfields=>\%pfs);

E<lt>go href="http://www.example.com/" method="get"E<gt>
  E<lt>postfield name="var1" value="1"/E<gt>
  E<lt>postfield name="var2" value="2"/E<gt>
  E<lt>postfield name="varN" value="N"/E<gt>
E<lt>/goE<gt> 

depending on wether it is passed a hash of postfields.

=head2 DO 

$query-E<gt>do(-type=>"options",
              -label=>"Menu",
              -content=>qq(go href="#menu"/>));
gives 

<do type="options" label="Menu" >
  <go href="#menu"/>
</do>


=head2 PREV

A canned 'back' link, takes an optional label argument. Default label
is 'Back'. For use in B<templates>

$query->prev(-label=>"Reverse");

<do type="accept" label="Reverse"><prev/></do>


=head2 INPUT

Create an input entry field. No defaults, although not all arguments need
to be specified.

$query->input(-name=>"pin",
              -value=>"1234",
              -type=>"text",
              -size=>4,
              -title=>"Enter PIN",
              -format=>"4N",
              -maxlength=>4,
              -emptyok=>"false");

=head2 ONEVENT

An B<onevent> element may contain one of 'go','prev','noop' or 'refresh'
and be of type 'onenterforward', 'onenterbackward' or 'ontimer'.

$query->onevent(-type=>"onenterforward",
                -content=>qq(<refresh>
                              <setvar name="x" value="1"/>
                             </refresh>));

=head2 IMG

An image can be created with the following attributes:

 alt       Text to display in case the image is not displayed
 align     can be top, middle, bottom
 src       The absolute or relative URI to the image
 localsrc  a variable (set using the setvar tag) that refers to an image
           this attribute takes precedence over the B<src> tag
 vspace    
 hspace    amount of white space to inserted to the left and right 
           of the image [hspace] or above and below the image [vspace] 
 height    
 width     These attributes are a hint to the user agent to leave space
           for the image while the page is rendering the page.  The 
           user agent may ignore the attributes.  If the number length 
           is passed as a percent the resulting image size will be
           relative to the amount of available space, not the image size.

my $img = $q->img(
                 -src      => '/icons/blue_boy.wbmp',
                 -alt      => 'Blue Boy',
                 -localsrc => '$var',
                 -vspace   => '25',
                 -hspace   => '30
                 -align    => 'bottom',
                 -height   => '15',
                 -width    => '10');

I<NOTE> the Unwired Planet (UP) browser 3.1 from Phone.com uses the
HDML mark up to display images.  HDML is a propritarty mark up
developed by Unwire Planet so it could be first to market with
Wireless Internet.  UP browsers are (AFAIK) the only ones supporting
this mark up.  Currently (May 2000) all Motorola phones are using this
browser.  Ericsson and Motorla will be deploying the UP 4.0 browser on
future devices.  Nokia has it's own 100% WAP 1.1 compliant browser
that will be deployed on all future Nokia devices.

I<NOTE> the B<localsrc> element, and formatting elements are not supported
consistently by the current generation of terminals, however they B<should>
simply ignore the attributes they do not understand.


=head2 P

A paragraph can be created with the following attributes

align  (left|right|center)

This attribute specifies the text alignment mode for the
paragraph. Text can be centre aligned, left aligned or right aligned
when it is displayed to the user. Left alignment is the default
alignment mode. If not explicitly specified, the text alignment is set
to the default alignment.

mode   (wrap|nowrap)

This attribute specifies the line-wrap mode for the paragraph. Wrap
specifies breaking text mode and nowrap specifies non-breaking text
mode. If not explicitly specified, the line-wrap mode is identical to
the line-wrap mode of the previous paragraph in the text flow of a
card. The default mode for the first paragraph in a card is wrap.


    content   

my $p = $q->p( -align    => 'center',
               -mode     => 'nowrap',
               -content  => 'This is a paragraph');

If you are not going to use the align or mode attributes you can call
it like this:

my $p = $q->p("This is content");


=head2 Dial Tags

When using cell phones in WAP you can make calls.  When a dial tag is
selected the phone drops out of the WAP stack and into what ever is the 
protocol used for phone calls.  At the conclusion of the call the phone 
returns to the WAP stack in the same place that you linked to the phone
number.  

The tag looks much like a regular link, but has some special syntax.  

$query->dialtag(-label =>"Joe's Pizza",
                -number=>"12125551212");

The recieving terminal must support WTAI for this link to work.


=head1 COMPILING WML DECKS
 

$query->wml_to_wmlc(-wml=>$buffer,
                    -errorcontext=>2);

A fairly good WML to WBML converter/compiler is included for convinience
purposes, although it is not intended to replace the compiler on the WAP
gateway it may prove useful.

The function takes two arguments, a buffer of textual WML and an optional
argument specifiying that should the XML parser fail then X many lines of
the buffer before and after the point where the error occured will be printed
to show the context of the error.


=head2 ERRORCONTEXT

I<WARNING> Setting this to any non-zero value will cause your program to
exit if the routine is passed WML which is not "well formed" this is due
to the fact that XML::Parser calls die() upon such events.

If you wish to test wether a WML document is well formed, then set this
value to zero and check the return value of the function. The function
returns undef upon failiure and issues a warning, anything other than
undef indicates success.

=head1 HTML TO WML CONVERSION

($title,$content) = $query->html_to_wml($buffer);

-or-

($title,$content) = $query->html_to_wml(\*FILEHANDLE);

A limited HTML to WML converter is included in this package. Be warned
that only pretty well marked-up HTML will convert cleanly to WML.
Dave Ragget's excellent B<tidy> utility 
[ see http://www.w3.org/People/Raggett/tidy/ ]
will clean up most HTML into a parseable state.

The main purpose of this function is for converting server error messages 
and the "Compact HTML" used on "I-Mode" systems to readable WML, not for
general page translation.

=back


=head1 AUTHOR

Angus Wood <angus@z-y-g-o.com>, with additions and improvements by Andy Murren <amurren@oven.com>

=head1 CREDITS

=item Wilbert Smits <wilbert@telegraafnet.nl> for the header() function
      content-type override.

=head1 SEE ALSO

perl(1), perldoc CGI, tidy(1)

=cut


