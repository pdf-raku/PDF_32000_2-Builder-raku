use v6;
use LibXML;
use LibXML::Document;
use LibXML::Node;
use JSON::Fast;

multi sub tidy(LibXML::Node $_) {
    tidy(.text);
}

multi sub tidy(Str() $_) {
    .trim
    .subst(/[\n|\s]+/, ' ', :g);
}

sub edit($_) {
    .subst(/«[shall|should]" be"»/, 'is', :g)
    .subst(/«[shall|should]" have"»/, 'has', :g)
    .subst(/«[shall|should]" not be"»/, 'is not', :g)
    .subst(/«[shall|should]" all be"»/, 'are', :g)
    .subst(/«[shall|should]" "(also|then)" be"»/, {'is '~$0}, :g)
    .subst(/«[shall|should]" not"»/, 'does not', :g)
    .subst(/«[shall|should]" "(only|itself)»/, {'is ' ~$0}, :g)
    .subst(/«[shall|should]" "(denote|distinguish|never|always|satisfy|exactly|respect)»/, {$0}, :g)
    .subst(/«[shall|should]" "(appl|specif|identif|satisf|occup)y»/, {$0 ~ 'ies'}, :g)
    .subst(/«[shall|should]" "(match|progress|do)»/, {$0 ~ 'es'}, :g)
    .subst(/«[shall|should]" "(accept|adjust|appear|assume|behave|cause|center|conform|consist|contain|continue|correspond|default|define|deliver|depend|describe|determine|disable|display|enable|exclude|exist|expect|fail|ignore|include|increase|indicate|initialize|interpret|invalidate|lie|list|make|map|mean|occur|oscillate|override|perform|permit|play|position|provide|refer|remain|replace|report|represent|set|show|skip|sort|stop|take|tolerate|translate|use)»/, {$0 ~ 's'}, :g)
    .subst(/T \s* a \s* b \s* l \s* e/, 'Table', :g)
    .subst(/:s "(" (<-[)]>*?)  ")"/, { '(' ~ tidy($0) ~ ')' }, :g)
    .subst(/:s Link (Table|Annex|Figure|Bibliography|<[0..9.]>+)/, { $0 }, :g);
}

sub dump-table(LibXML::Node $table is copy, :$caption!, :@head!) {
    my @rows;
    while $table.defined && $table.tag eq 'Table' {
        @rows.append: $table.<TBody/TR>.map({
             my @row = .find('TH|TD');
             if @row.elems >= 3 {
                 @row.map({
                     my @paras = .<P>.map: &tidy;
                     edit(@paras.join("\n"));
                 });
             }
             else {
                 Empty;
             }
        });
        $table .= nextNonBlankSibling;
    }
    %( :table{ :$caption, :@head, :@rows } );
}

sub MAIN(IO() $pdf-extract = '../gen/PDF-ISO_32000-2.xml', :$out-dir= '../resources/ISO_32000-2/', Bool :$make) {
    my $src-modified = $pdf-extract.IO.modified
        // die "problem stat-ing source file: $pdf-extract";
    my LibXML::Document $doc .= parse(:file($pdf-extract));
    for $doc.find('//P[starts-with(normalize-space(text()),"Table")]') {
        my $caption = .&tidy;
        my $table = .nextNonBlankSibling;
        next unless $table.defined && $table.tag eq 'Table';

        my $name = $caption
            .subst(/['. '||'.'|'<'|'>'|'’']/, '', :g)
            .subst(/','.*$/, '')
            .subst(/'3D'/, 'ThreeD')
            .subst(/\s*['–'|'/'|'—']\s*/, '-', :g)
            .subst(/\s+/, '_', :g)
            .subst(/_?'(' .*? ')'/, '');

        my $filename = $out-dir;
        $filename ~= '/' unless $filename.ends-with('/');
        my @head = $table.find('THead/TR/TH/P').map: &tidy;
        $filename ~= 'misc/'
            unless +@head == 3 && @head[0] ~~ /:i['Key'|'Parameter']/ && @head[1] ~~ /:i'Type'/;
        $filename ~= $name ~ '.json';
        my $dest-io = $filename.IO;
        next if $make && $dest-io.e && $dest-io.modified >= $src-modified;
        note "writing: $filename";
        $dest-io.IO.spurt: to-json( dump-table($table, :$caption, :@head), :sorted-keys );
    }
}
