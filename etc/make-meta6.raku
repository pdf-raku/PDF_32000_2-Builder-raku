use v6;
use JSON::Fast;

# Build.pm can also be run standalone 
sub MAIN(IO() $meta6-in, Str:D :$root!, *@sources) {
    my Hash $meta6 = from-json($meta6-in.slurp);
    my %provides;
    my @resources;
    my %appendices;
    my @resource-index = [%appendices, ];
    for @sources.sort( -> $k {with ($k ~~ /<?after Table_>\d+/) {.Int} else { $k }}) {
        when /'.rakumod'$/ {
            my $path = .subst($root ~ '/', '');
            my $role-name = $path.subst(/^'lib/'/,'').subst(/'.rakumod'$/, '').subst(m{'/'}, '::', :g);
            %provides{$role-name} = ($path);
        }
        when /'.json'$/ {
            my $file = "$root/resources/$_";
            CATCH { default { die "error processing $file: $_" } }  
            with from-json($file.IO.slurp)<table> -> $table {
                with $table<caption> -> $caption {
                    my $table-name = .subst(/^'ISO_32000_2/'/,'').subst(/'.json'$/,'');
                    if $caption ~~ /:s Table (\d+)/ {
                        @resource-index[$0.Int] = $table-name;
                    }
                    elsif $caption ~~ /:s Table (<[A..Z]>[\d|'.'|\s]+)/ {
                        %appendices{$0.split(/\s/).join} = $table-name;
                    }
                    else {
                        warn "ignoring: $_";
                    }
                }
            }
            @resources.push: $_;
        }
    }
    given "ISO_32000_2-index.json" {
        "$root/resources/$_".IO.spurt: to-json(@resource-index, :sorted-keys);
        @resources.unshift: $_;
    }
    %provides<PDF::ISO_32000_2> = 'lib/PDF/ISO_32000_2.rakumod';
    $meta6<provides> = %provides;
    $meta6<resources> = @resources;
##    $meta6<version> = PDF::ISO_32000_2.^ver.Str;
    say to-json($meta6, :sorted-keys);
}
