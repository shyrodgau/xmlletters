# xmlletters

It's probably currently most suited to a german audience.

XSL-FO Wrapper, macht aus relativ simplem XML mit jeder Menge XSL-FO Vorlagen beliebige Dokumente/Briefköpfe/Fußzeilen und kann auch Rechnungen ausstellen.

Im XSL-FO können `snippet`s wiederverwendet werden oder Parameter per Kommandozeile `-param mod key:value` verändert werden.

Z.B. kann bei den Samples

`-param mod textfont:Times,sansfont:Helvetica,versfont:Courier,ntextfont:Times,addront:Times`

auf die normale Postscript/PDF Fonts umgeschwenkt werden, wenn die eigentlich referenzierten Latin Modern Fonts nicht da sind.

Die nFonts sind explizit ohne Kerning konfiguriert und werden an Stellen verwendet, wo Zahlen untereinander stehen, die vielleicht nicht in allen Schriftarten immer alle gleich breit sind.

Briefköpfe und Fußzeilen sollten im layout.xml konfiguriert werden, die letter_outline.fo und invoice_outline.fo können bedarfsweise auch angepasst werden.

Eingabe XMLs sollten gegen das XML Schema validiert werden, damit sollten dann keine Überraschungen passieren.

Es können Dokumente in mehreren Sprachen, als PDF/A-1a, -1b, -3a und -3b, als zu druckende Serienbriefe u.s.w. erzeugt werden. 

Mehr doku muss noch her.
