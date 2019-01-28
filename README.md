## Übersicht ##

It's probably currently most suited to a german audience, so...

Umfangreicher XSL-FO Wrapper, macht aus relativ simplem XML mit jeder Menge XSL-FO Vorlagen beliebige Dokumente/Briefköpfe/Fußzeilen und kann auch Rechnungen ausstellen. Kann Dokumente darüberlegen (`overlay`), anhängen (`append`) oder einbetten (`embed`). Wenn keines dieser Features genutzt wird, können auch direkt PDF/A-1a, -1b, 3a oder -3b konforme PDF Dokumente erzeugt werden. Es wird [Apache FOP](https://xmlgraphics.apache.org/fop) benötigt, für Überlagerung und Anhänge im PDF Format auch noch das [PDF Images Plugin](https://xmlgraphics.apache.org/fop/fop-pdf-images.html). Apache FOP benutzt intern den [Xalanj XSLT Prozessor](http://xalan.apache.org/).

Im XSL-FO können `snippet`s wiederverwendet werden oder einzelne Attribute per Kommandozeile `-param mod key:value` verändert werden.

Z.B. kann bei den Samples

    -param mod textfont:Times,sansfont:Helvetica,versfont:Courier,ntextfont:Times,addrfont:Times

auf die normale Postscript/PDF Fonts umgeschwenkt werden, wenn die eigentlich referenzierten Latin Modern Fonts nicht da sind.

Mit dem `mod` `addrfont:Helvetica` (oder eine andere serifenlose Schrift) können auszudruckende und per Post versandte Dokumente per Aufruf einen für die Post leichter lesbaren Zeichensatz im Anschriftenfeld erhalten, ohne das Format an sich ändern zu müssen.

Die mods können auch gruppiert werden, so dass mit `-param mod group:<groupname>` mehrere auf einmal geschaltet werden können.

Die Verwendung der Schriftarten hängt von der Apache FOP Konfiguration ab. Bei Erzeugung von PDF/A muss darauf geachtet werden, dass auch die Standard-Fonts eingebettet werden. 

## Voraussetzungen ##

Die Mühe, in XSL-FO schöne Briefköpfe und Fußzeilen zu entwerfen; diese können unterschiedliche Inhalte und Größen haben, für die Briefköpfe sind die in DIN 5008 beschriebenen Höhen vorgesehen (105 oder 87 mm), für die dann auch Faltmarken erzeugt werden können.  

Briefköpfe und Fußzeilen sollten im layout.xml konfiguriert werden, die letter_outline.fo und invoice_outline.fo können bedarfsweise auch angepasst werden.

Eingabe XMLs sollten gegen das XML Schema validiert werden, damit sollten dann keine Überraschungen passieren.

## Dateien ##

- `xml-fo.xsl`  Das Arbeitspfert für die Transformation nach XSL-FO
- `letterfmt0.xsl` XML Schema zur Validierung

Der Rest ist ein Gerüst aus Beispieldateien:
- `layout.xml` Konfiguration der XSL-FO Briefköpfe und Fußzeilen, Übersetzungen, Ansprechpartner-Daten für den Briefkopf
- `layout_simple.xml` Stark vereinfachte Konfiguration ohne Übersetzungen, Ansprechpartner und modgroups
- `letter_outline.fo`, `invoice_outline.fo` Gerüste für Brief und Rechnung, statt Rechnung kann auch ein Lieferschein erstellt werden
- `letter_simple_outline.fo` für die stark vereinfachte Konfiguration
- `fop*.xconf` Beispielkonfigrationen für Apache FOP

Die nFonts sind explizit ohne Kerning konfiguriert und werden an Stellen verwendet, wo Zahlen untereinander stehen, die vielleicht nicht in allen Schriftarten immer alle gleich breit sind.

Mehr doku muss noch her.
