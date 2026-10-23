#!/bin/bash
# Reads text on stdin, prints a best-guess ISO 639-1 code (en, de, fr, es, it,
# pt, nl). Dependency-free stopword scoring: each language scores the share of
# words that are common function words of that language. Falls back to "en"
# when nothing scores clearly (short or code-heavy text).

perl -CSD -0777 -ne '
  my %stop = (
    en => "the and is are was were to of in that it for with as on be this have not but you your from they will can would there which",
    de => "der die das und ist sind war nicht ein eine einen zu von mit den dem des auf für auch ich du sie wir aber oder wie wenn noch nur kann dass es im am bei nach",
    fr => "le la les et est sont un une des du de que qui pour dans pas sur avec ce cette au aux je tu il elle nous vous mais ou comme plus par",
    es => "el la los las y es son un una de que en por para con no se su al lo como más pero sus le ya o este sí porque esta entre",
    it => "il lo la gli le e è sono un una di che in per con non si su al come più ma suo anche questo questa nel della dei delle ho hai",
    pt => "o a os as e é são um uma de que em por para com não se seu ao como mais mas dos das no na também isso este esta você",
    nl => "de het een en is zijn van dat in op te voor met niet ik je we ze maar ook als er aan bij naar uit dit deze wordt kan",
  );
  my @w = map { lc } /\p{L}+/g;
  my $n = @w;
  if ($n < 3) { print "en\n"; exit }
  my ($best, $bs) = ("en", 0);
  for my $l (sort keys %stop) {
    my %s = map { $_ => 1 } split / /, $stop{$l};
    my $hits = grep { $s{$_} } @w;
    # umlauts/accents are a weak tiebreaker for languages sharing stopwords
    $hits += 0.5 * (() = /[äöüß]/g) if $l eq "de";
    if ($hits > $bs) { ($best, $bs) = ($l, $hits) }
  }
  print(($bs / $n >= 0.08 ? $best : "en"), "\n");
'
