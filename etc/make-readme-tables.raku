use v6;

sub MAIN( Str:D :$root!, *@sources) {
    say '';
    say "ISO_32000_2 Reference|Entries";
    say "----|-----";
    my %entries;
    @sources .= sort( -> $k {with ($k ~~ /<?after Table_>\d+/) {sprintf("%05d", .Int)} else { $k }} );

    for @sources {
        next unless .defined;
        my $io = .IO;
        die "no such file: '$_'" unless $io.e;
        with $io.slurp.lines.first(/^'Table '/) -> $iso-ref {
            s/'#|' .* 'Table'/Table/ with $iso-ref;
            my $path = .subst($root ~ '/', '');
            my $role-name = $path.subst(/^'lib/'/,'').subst(/'.rakumod'$/, '').subst(m{'/'}, '::', :g);
            my $role-ref = "[$iso-ref]($path)";
            my $role = try (require ::($role-name));
            die "failed to compile ::($role-name): $_" with $!;
            my @entries = $role.^methods.map: {'/' ~ .name};
            say "$role-ref|{@entries.join: ' '}";
            %entries{$_}.push($role-ref)
               for @entries;
        }
    }
    say '';
    say '## Entry to role mappings';
    say '';
    say "Entry|ISO_32000_2 Roles";
    say "----|-----";
    say "{.key}|{.value.join: ' '}"
        for %entries.pairs.sort;
}
