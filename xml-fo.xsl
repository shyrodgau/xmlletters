<?xml version="1.0" encoding="UTF-8"?>

<!--
Single call variant:
fop \
      # xslt param        #####################################
      -param lang         de                           # or en (de is default, can also be set in xml:lang in input xml)
                                                       # or via the name of the top level element in the xml input

      -param mod          param:value[,param:value]*   # set modify parameters, as marked by y:mark="mod:<attribute>:<param>" 
                                                       # in fo elems
                          param may be "group"         # or if mod:group:<modgroup> all param:value settings inside the 
                                                       # named modgroup/@mods
                                                       # e.g. color:#e8e8e8 for y:mark="mod:color:color" 
                                                       # or   textfont:Linux Libertine for y:mark="mod:font-family:textfont"
                                                       # or   group:libertine to switch all fonts to Libertine/Biolinum family
                                                       # INTERN mods: 
                                                       # versfont, should name font (monospaced, ocr, etc.) 
                                                       #     for the versionstring
                                                       # eurofont, used for y:eur elements

      -param pdfprofile   A1                           # or A1b or A3 or A3b or "" must match fop pdfprofile and -c
                                                       # (see list below)

      # xslt **special**  #####################################
      -param basedir      ~/prog/hcbriefe              # directory where layout and templates are, default 
                                                       # same as this stylesheet

      -param scriptvers   123456                       # version of calling shellscript (typically yymmdd),
                                                       # Omit when calling direct w/o script

      -param layout       path/layout.xml              # path and name of layouts file, default $basedir/layout.xml

      -param tempbase     /tmp/datei                   # path/file name prefix of ${tempbase}rliste.xml output file
                                                       # (invoice details) (default rechdat -> rechdatrliste.xml)

      -param debug        1                            # include y:ref snippets as comment (0 or omit = do it not)
                                                       # (only useful when using -foout alone for xml->fo)

      -param markxlate    1                            # mark translated texts in color


      # fop param        #####################################
      -pdfprofile        'PDF/A-1a'                    # fop profile, match pdfprofile param above (see list below), 
                                                       # or omit for no PDF/A

      -c                 fop.xconf                     # or "fop_3a.xconf" for A3/b or "fop_1a.xconf" for PDF A1....

      -xml               samples/simple_letter.xml     # input XML
      -xsl               $basedir/xml-fo.xsl           # this file - FIX - do not modify
      -pdf               invoice_1page.pdf             # output PDF
-->

<!--
xsl "-param pdfprofile"  fop  "-pdfprofile"       -c configfile   PDF/A result
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
omit                      omit                    fop.xconf       no PDF/A
A1                        PDF/A-1a                fop_1a.xconf    PDF/A-1a  (PDF 1.4)
A1b                       PDF/A-1b                fop_1a.xconf    PDF/A-1b  (PDF 1.4)
A3                        PDF/A-3a                fop_3a.xconf    PDF/A-3a  (PDF 1.7)
A3b                       PDF/A-3b                fop_3a.xconf    PDF/A-3b  (PDF 1.7)
-->

<!--
Useful combinations

toplevel type in xml         fo template             page-sequence master-name
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
rechnung | invoice           hcdinrechnung-neu      *letter_PG
brief | letter               hcdinbrief-neu          letter
lieferschein                 hclieferschein-neu      letterB
                                                     letterB_PG
                                                     letterx_PG
                                                     letterx
                                                     letterxB
                                                     letterxB_PG



-->

<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:y="http://xmlns.hydrografix.com/letters" xmlns:hx="http://xmlns.hydrografix.com/letters/intern" xmlns:z="http://xmlns.hydrografix.com/letters/config" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:fox="http://xmlgraphics.apache.org/fop/extensions" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:date="http://exslt.org/dates-and-times" xmlns:str="http://exslt.org/strings" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:h="http://www.w3.org/1999/xhtml" xmlns:pdfaid="http://www.aiim.org/pdfa/ns/id/" xmlns:meta="adobe:ns:meta/" xmlns:xmp="http://ns.adobe.com/xap/1.0/" xmlns:xr="http://xml.apache.org/xalan/redirect" xmlns:ex="http://exslt.org/common" xmlns:fx="http://exslt.org/functions" extension-element-prefixes="ex fx xr date str" exclude-result-prefixes="h hx y" version="1.0">

    <xsl:output method="xml"/>

<!-- dir for layouts, texts, templates -->
    <xsl:param name="basedir" select="'./'"/>

<!-- language -->
    <xsl:param name="lang" select="''"/>

<!-- color, font, etc mods or modgroups modname':'modvalue or 'group:'groupname -->
    <xsl:param name="mod" select="''"/>

<!-- A1/a1 = PDF/A-1a,   a3/A3 = PDF/A-3a -->
<!-- A1b/a1b = PDF/A-1b, a3b/A3b = PDF/A-3b -->
    <xsl:param name="pdfprofile" select="''"/>

<!-- version of hcbrief_pdf script -->
    <xsl:param name="scriptvers" select="0"/>

<!-- name of layouts file -->
    <xsl:param name="layout" select="concat($basedir,'/layout.xml')"/>

<!-- debug flag -->
    <xsl:param name="debug" select="0"/>

<!-- debug flag -->
    <xsl:param name="markxlate" select="0"/>

<!-- temp files -->
    <xsl:param name="tempbase" select="'rechdat'"/>

<!-- text for not found translations -->
    <xsl:param name="xlnotfound" select="'?LOREM IPSUM?'"/>

    <xsl:variable name="layouts" select="document($layout)"/>


<!--                         -->
<!-- O V L/A P P  P A R A M  -->
<!--                         -->
    <xsl:variable name="overlayname">
        <xsl:if test="'' != /*/y:overlay/@doc">
            <xsl:value-of select="/*/y:overlay/@doc"/>
        </xsl:if>
    </xsl:variable>
    <xsl:variable name="overlaypages">
        <xsl:choose>
            <xsl:when test="'' != $overlayname and '' != /*/y:overlay/@npages">
                <xsl:value-of select="/*/y:overlay/@npages"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>1</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="overlayalttext">
        <xsl:choose>
            <xsl:when test="'' != $overlayname and '' != /*/y:overlay/@alttext">
                <xsl:value-of select="/*/y:overlay/@alt"/>
            </xsl:when>
            <xsl:when test="'.pdf' = translate(substring($overlayname,string-length($overlayname) - 3),'PDF','pdf')"/>
            <xsl:otherwise>
                <xsl:text>embedded graphic</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="overlayrotate">
        <xsl:choose>
            <xsl:when test="'' != $overlayname and '' != /*/y:overlay/@rotate">
                <xsl:value-of select="/*/y:overlay/@rotate"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>0</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="appendname">
        <xsl:if test="'' != /*/y:append/@doc">
            <xsl:value-of select="/*/y:append/@doc"/>
        </xsl:if>
    </xsl:variable>
    <xsl:variable name="appendpages">
        <xsl:choose>
            <xsl:when test="'' != $appendname and '' != /*/y:append/@npages">
                <xsl:value-of select="/*/y:append/@npages"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>1</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="appendfmt">
        <xsl:choose>
            <xsl:when test="'' != $appendname and '' != /*/y:append/@fmt">
                <xsl:value-of select="/*/y:append/@fmt"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>blank</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="appendrotate">
        <xsl:choose>
            <xsl:when test="'' != $appendname and '' != /*/y:append/@rotate">
                <xsl:value-of select="/*/y:append/@rotate"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>0</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="appendalttext">
        <xsl:choose>
            <xsl:when test="'' != $appendname and '' != //*/y:append/@alttext">
                <xsl:value-of select="/*/y:append/@alt"/>
            </xsl:when>
            <xsl:when test="'.pdf' = translate(substring($appendname,string-length($appendname) - 3),'PDF','pdf')"/>
            <xsl:otherwise>
            <!-- xsl:message><xsl:value-of select="substring($appendname,string-length($appendname) - 3)"/></xsl:message -->
                <xsl:text>embedded graphic</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="embedname">
        <xsl:if test="'' != /*/y:embed/@doc">
            <xsl:value-of select="/*/y:embed/@doc"/>
        </xsl:if>
    </xsl:variable>
    <xsl:variable name="embedalt">
        <xsl:choose>
            <xsl:when test="'' != /*/y:embed/@alttext">
                <xsl:value-of select="/*/y:embed/@alttext"/>
            </xsl:when>
            <xsl:when test="'' != $embedname">
                <xsl:text>Embedded file</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="embedfilename">
        <xsl:choose>
            <xsl:when test="'' != /*/y:embed/@filename">
                <xsl:value-of select="/*/y:embed/@filename"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="y:basename($embedname)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="embedlink">
        <xsl:choose>
            <xsl:when test="'' != /*/y:embed/@linklocation">
                <xsl:value-of select="/*/y:embed/@linklocation"/>
            </xsl:when>
            <xsl:when test="'' != $embedname">
                <xsl:text>anlage</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:variable>


<!--                         -->
<!-- S P R A C H E           -->
<!--                         -->
    <xsl:variable name="sprachint">
        <xsl:choose>
        <!-- 1. cmd line parameter -->
            <xsl:when test="$lang != ''">
                <xsl:value-of select="$lang"/>
            </xsl:when>
        <!-- 2. xml:lang of root -->
            <xsl:when test="'' != /*[1]/@xml:lang">
                <xsl:value-of select="/*[1]/@xml:lang"/>
            </xsl:when>
        <!-- 3. name of root (document type) -->
            <xsl:when test="starts-with(local-name(/*[1]),'letter') or local-name(/*[1]) = 'invoice'">
                <xsl:text>en</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>de</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

<!--                         -->
<!-- V E R S I O N           -->
<!--                         -->
    <xsl:variable name="xslversion">$Id$</xsl:variable>


    <xsl:variable name="timestring" select="concat(date:year(),'-',str:align(date:month-in-year(),'00','right'),'-',str:align(date:day-in-month(),'00','right'),'T',str:align(date:hour-in-day(),'00','right'),':',str:align(date:minute-in-hour(),'00','right'),':',str:align(date:second-in-minute(),'00','right'))"/>


<!--                         -->
<!-- D A T E (S)             -->
<!--                         -->
    <xsl:variable name="docdate">
        <xsl:choose>
            <xsl:when test="*[1]/@datum != ''">
                <xsl:value-of select="*[1]/@datum"/>
            </xsl:when>
            <xsl:when test="*[1]/@date != ''">
                <xsl:value-of select="*[1]/@date"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>
                    <xsl:value-of select="concat('**** NO DATE, using TODAY - ',substring($timestring,1,10))"/>
                </xsl:message>
                <xsl:value-of select="substring($timestring,1,10)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="normdate">
        <xsl:choose>
            <xsl:when test="*[1]/@datenorm != ''">
                <xsl:value-of select="*[1]/@datenorm"/>
            </xsl:when>
            <xsl:when test="string-length(substring-before($docdate,'-')) = 4 and string-length(substring-before(substring-after($docdate,'-'),'-')) = 2 ">
                <xsl:value-of select="$docdate"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>
                    <xsl:value-of select="concat('**** NO NORM-DATE, using TODAY - ',substring($timestring,1,10))"/>
                </xsl:message>
                <xsl:value-of select="substring($timestring,1,10)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

<!--                         -->
<!-- W E I C H E             -->
<!--                         -->

    <xsl:variable name="usedmaster0">
        <xsl:choose>
            <xsl:when test="/*[1]/@master and '' != /*[1]/@master">
                <xsl:copy-of select="document(concat($basedir,/*[1]/@master))"/>
                <xsl:if test="0 != $debug">
                    <xsl:message>
                        <xsl:value-of select="concat('&#xa;master ',/*[1]/@master,' coming from master attribute in input xml ')"/>
                    </xsl:message>
                </xsl:if>
            </xsl:when>
            <xsl:when test="'' != $layouts/z:config/z:types/z:type[contains(concat(',',@names,','),concat(',',local-name(current()/*[1]),','))]/@master">
                    <xsl:copy-of select="document(concat($basedir,$layouts/z:config/z:types/z:type[contains(concat(',',@names,','),concat(',',local-name(current()/*[1]),','))]/@master))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">
                    <xsl:value-of select="concat('***&#xa;**** No FO for document type ',local-name(/*[1]),' -- NOT possible ***&#xa;***&#xa;')"/>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="usedmaster" select="ex:node-set($usedmaster0)"/>
    <xsl:variable name="mainstream">
        <xsl:choose>
            <!-- given/overridden in input xml -->
            <xsl:when test="/*[1]/@fmt and '' != /*[1]/@fmt">
                <xsl:value-of select="/*[1]/@fmt"/>
                <xsl:if test="0 != $debug">
                    <xsl:message>
                        <xsl:value-of select="concat('&#xa;master-reference ',/*[1]/@fmt,' coming from fmt attribute in input xml')"/>
                    </xsl:message>
                </xsl:if>
            </xsl:when>
            <!-- default for master (overriding e.g. letter_PG to letter for serienbrief) -->
            <xsl:when test="'' != $layouts/z:config/z:types/z:type[contains(concat(',',@names,','),concat(',',local-name(current()/*[1]),','))]/@defaultlayout">
                <xsl:value-of select="$layouts/z:config/z:types/z:type[contains(concat(',',@names,','),concat(',',local-name(current()/*[1]),','))]/@defaultlayout"/>
                <xsl:if test="0 != $debug">
                    <xsl:message>
                        <xsl:value-of select="concat('&#xa;master-reference ',$layouts/z:config/z:types/z:type[contains(concat(',',@names,','),concat(',',local-name(current()/*[1]),','))]/@defaultlayout,' coming from ',local-name(current()/*[1]),' specific mapping in layouts.')"/>
                    </xsl:message>
                </xsl:if>
            </xsl:when>
            <!-- language unspecific in master -->
            <xsl:when test="'' != $usedmaster/fo:root/fo:page-sequence/@master-reference">
                <xsl:value-of select="$usedmaster/fo:root/fo:page-sequence/@master-reference"/>
                <xsl:if test="0 != $debug">
                    <xsl:message>
                        <xsl:value-of select="concat('&#xa;master-reference ',$usedmaster/fo:root/fo:page-sequence/@master-reference,' coming from lang un-specific in usedmaster')"/>
                    </xsl:message>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">
                    <xsl:text>***&#xa;**** No page-sequence/@master-reference  -- probably PROGRAMMING error ***&#xa;***&#xa;</xsl:text>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- on serials, never use lastpg -->
    <xsl:variable name="ismulti">
        <xsl:choose>
            <xsl:when test="1 = $layouts/z:config/z:types/z:type[contains(concat(',',@names,','),concat(',',local-name(current()/*[1]),','))]/@ismulti">
                <xsl:value-of select="1"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="0"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="uselastpg">
        <xsl:choose>
            <xsl:when test="1 = $ismulti">
                <xsl:text>0</xsl:text>
                <xsl:if test="0 != $debug">
                    <xsl:message>&#xa;Switching off lastpg (serial or so)&#xa;</xsl:message>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>1</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="versionpattern">
        <fo:block font-family="Courier" y:mark="mod:font-family:versfont" role="none" font-size="5pt" color="#888888">** <fo:inline y:mark="xgenerator"/>**</fo:block>
    </xsl:variable>


<!--                         -->
<!-- H E R E  G O E S  I T  L-->
<!--                         -->
    <xsl:template match="/">
        <fo:root xml:lang="{$sprachint}">
            <xsl:choose>
                <xsl:when test="1 = $ismulti">
                    <xsl:call-template name="generate-page-masters">
                        <xsl:with-param name="brief" select="/*/*[1]"/>
                    </xsl:call-template>
                    <xsl:choose>
                        <xsl:when test="$layouts/z:config/z:types/z:type[contains(concat(',',@names,','),concat(',',local-name(current()/*[1]),','))]/@mode = 'letter'">
                            <xsl:apply-templates select="/*/*" mode="letter">
                                <xsl:with-param name="master" select="$usedmaster/fo:root"/>
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:when test="$layouts/z:config/z:types/z:type[contains(concat(',',@names,','),concat(',',local-name(current()/*[1]),','))]/@mode = 'bill'">
                        <!-- currently no corresponding use-case -->
                            <xsl:apply-templates select="/*/*" mode="bill">
                                <xsl:with-param name="master" select="$usedmaster/fo:root"/>
                            </xsl:apply-templates>
                        </xsl:when>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="generate-page-masters">
                        <xsl:with-param name="brief" select="/*[1]"/>
                    </xsl:call-template>

                    <xsl:choose>
                        <xsl:when test="$layouts/z:config/z:types/z:type[contains(concat(',',@names,','),concat(',',local-name(current()/*[1]),','))]/@mode = 'letter'">
                            <xsl:apply-templates select="/*[1]" mode="letter">
                                <xsl:with-param name="master" select="$usedmaster/fo:root"/>
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:when test="$layouts/z:config/z:types/z:type[contains(concat(',',@names,','),concat(',',local-name(current()/*[1]),','))]/@mode = 'bill'">
                            <xsl:apply-templates select="/*[1]" mode="bill">
                                <xsl:with-param name="master" select="$usedmaster/fo:root"/>
                            </xsl:apply-templates>
                        </xsl:when>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
        </fo:root>
    </xsl:template>

    <xsl:template match="*" mode="letter">
        <xsl:param name="master"/>
        <xsl:message>*** Mode letter: <xsl:value-of select="name()"/>
        </xsl:message>
        <xsl:if test="not(following-sibling::y:brief) and not(preceding-sibling::y:brief) and not(following-sibling::y:letter) and not(preceding-sibling::y:letter)">
            <xsl:apply-templates select="$master//fo:declarations">
                <xsl:with-param name="brief" select="."/>
            </xsl:apply-templates>
        </xsl:if>
        <xsl:apply-templates select="$master//fo:page-sequence">
            <xsl:with-param name="brief" select="."/>
        </xsl:apply-templates>
    </xsl:template>

<!-- xsl:template match="y:rechnung | y:lieferschein | y:invoice" -->
    <xsl:template match="*" mode="bill">
        <xsl:param name="master"/>
        <xsl:message>*** Mode invoice: <xsl:value-of select="name($master)"/>
        </xsl:message>
        <xsl:variable name="rechinfo0">
            <xsl:apply-templates select="//y:positionen/y:position" mode="summs">
                <xsl:with-param name="allepos" select="//y:positionen/y:position"/>
                <xsl:with-param name="indx" select="1"/>
                <xsl:with-param name="schonda">
                    <hx:diffvats/>
                    <hx:netsum sum="0"/>
                    <hx:sums/>
                </xsl:with-param>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="xrechinfo0" select="ex:node-set($rechinfo0)"/>
        <xsl:variable name="rechinfo">
            <xsl:copy-of select="$xrechinfo0//hx:diffvats | $xrechinfo0//hx:netsum"/>
            <xsl:apply-templates select="$xrechinfo0//hx:diffvats/hx:vat" mode="grossum">
                <xsl:with-param name="alldiffvats" select="$xrechinfo0//hx:diffvats/hx:vat"/>
                <xsl:with-param name="indx" select="1"/>
                <xsl:with-param name="gross" select="0"/>
                <xsl:with-param name="net" select="0"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="xrechinfo" select="ex:node-set($rechinfo)"/>
        <xsl:if test="element-available('xr:write')">
            <xr:write select="concat($tempbase,'rliste.xml')">
                <x>
                    <xsl:copy-of select="$xrechinfo"/>
                </x>
            </xr:write>
        </xsl:if>

        <xsl:apply-templates select="$master//fo:declarations">
            <xsl:with-param name="brief" select="."/>
            <xsl:with-param name="rechinfo" select="$xrechinfo"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="$master//fo:page-sequence">
            <xsl:with-param name="brief" select="."/>
            <xsl:with-param name="rechinfo" select="$xrechinfo"/>
        </xsl:apply-templates>
    </xsl:template>

<!--                         -->
<!-- A D R E S S E           -->
<!--                         -->
    <xsl:template match="*[@y:mark='addrline0' or @id='addrline0' or y:mark='addr00']">
        <xsl:param name="brief"/>
        <xsl:copy>
            <xsl:copy-of select="@*[name()!='id' and name() != 'y:mark']"/>
            <xsl:choose>
                <xsl:when test="$brief//y:an/y:zust/child::node()">
                    <xsl:apply-templates select="$brief//y:an/y:zust/child::node()">
                        <xsl:with-param name="brief" select="$brief"/>
                    </xsl:apply-templates>
                    <fo:block>&#xa0;</fo:block>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>&#160;</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="*[@y:mark='addr']">
        <xsl:param name="brief"/>
        <xsl:copy>
            <xsl:copy-of select="@*[name()!='id' and name() != 'y:mark']"/>
            <xsl:choose>
                <xsl:when test="$brief//y:an/y:z1/child::node()">
                    <xsl:apply-templates select="$brief//y:an/y:z1/child::node()">
                        <xsl:with-param name="brief" select="$brief"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>&#10;</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:copy-of select="@*[name()!='id' and name() != 'y:mark']"/>
            <xsl:choose>
                <xsl:when test="$brief//y:an/y:z2/child::node()">
                    <xsl:text>&#xa;</xsl:text>
                    <xsl:apply-templates select="$brief//y:an/y:z2/child::node()">
                        <xsl:with-param name="brief" select="$brief"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>&#10;</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:copy-of select="@*[name()!='id' and name() != 'y:mark']"/>
            <xsl:choose>
                <xsl:when test="$brief//y:an/y:z3/child::node()">
                    <xsl:text>&#xa;</xsl:text>
                    <xsl:apply-templates select="$brief//y:an/y:z3/child::node()">
                        <xsl:with-param name="brief" select="$brief"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>&#10;</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:copy-of select="@*[name()!='id' and name() != 'y:mark']"/>
            <xsl:choose>
                <xsl:when test="$brief//y:an/y:z4/child::node()">
                    <xsl:text>&#xa;</xsl:text>
                    <xsl:apply-templates select="$brief//y:an/y:z4/child::node()">
                        <xsl:with-param name="brief" select="$brief"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>&#10;</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:copy-of select="@*[name()!='id' and name() != 'y:mark']"/>
            <xsl:choose>
                <xsl:when test="$brief//y:an/y:z5/child::node()">
                    <xsl:text>&#xa;</xsl:text>
                    <xsl:apply-templates select="$brief//y:an/y:z5/child::node()">
                        <xsl:with-param name="brief" select="$brief"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>&#10;</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>


<!--                         -->
<!--  D A T U M              -->
<!--                         -->
    <xsl:template match="*[@y:mark='datum' or @id='datum']">
        <xsl:param name="brief"/>
        <xsl:copy>
            <xsl:copy-of select="@*[name()!='id' and name() != 'y:mark']"/>
            <xsl:value-of select="$docdate"/>
        </xsl:copy>
    </xsl:template>

<!--                         -->
<!--  C O N T A C T          -->
<!--                         -->
    <xsl:template match="*[@y:mark='aspname']">
        <xsl:param name="brief"/>
        <xsl:copy>
            <xsl:copy-of select="@*[name() != 'y:mark']"/>
            <xsl:choose>
                <xsl:when test="'' != $layouts/z:config/z:contacts/z:contact[@ref = $brief/@contact]/@name and '' != string($brief/@contact)">
                    <xsl:value-of select="$layouts/z:config/z:contacts/z:contact[@ref = $brief/@contact]/@name"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>
                        <xsl:value-of select="concat('**** Unimplemented Contact Name: ', $brief/@contact)"/>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="*[@y:mark='aspemail']">
        <xsl:param name="brief"/>
        <xsl:copy>
            <xsl:copy-of select="@*[name() != 'y:mark']"/>
            <xsl:choose>
                <xsl:when test="'' != $layouts/z:config/z:contacts/z:contact[@ref = $brief/@contact]/@email and '' != string($brief/@contact)">
                    <xsl:value-of select="substring-before($layouts/z:config/z:contacts/z:contact[@ref = $brief/@contact]/@email,'@')"/>
                    <fo:inline font-size="75%">@</fo:inline>
                    <xsl:value-of select="substring-after($layouts/z:config/z:contacts/z:contact[@ref = $brief/@contact]/@email,'@')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>
                        <xsl:value-of select="concat('**** Unimplemented Contact Email: ', $brief/@contact)"/>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="*[@y:mark='asprole']">
        <xsl:param name="brief"/>
        <xsl:copy>
            <xsl:copy-of select="@*[name() != 'y:mark']"/>
            <xsl:choose>
                <xsl:when test="'' != $layouts/z:config/z:contacts/z:contact[@ref = $brief/@contact]/@email and '' != string($brief/@contact)">
                    <xsl:copy-of select="y:xlate($layouts/z:config/z:contacts/z:contact[@ref = $brief/@contact]/@xlposition)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>
                        <xsl:value-of select="concat('**** Unimplemented Contact position: ', $brief/@contact)"/>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="*[@y:mark='asptel']">
        <xsl:param name="brief"/>
        <xsl:variable name="thetel">
            <xsl:choose>
                <xsl:when test="'' != $layouts/z:config/z:contacts/z:contact[@ref = $brief/@contact]/@email and '' != string($brief/@contact)">
                    <xsl:value-of select="$layouts/z:config/z:contacts/z:contact[@ref = $brief/@contact]/@tel"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>
                        <xsl:value-of select="concat('**** No phone contact: ', $brief/@contact)"/>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:copy>
            <xsl:copy-of select="@*[name() != 'y:mark']"/>
            <xsl:call-template name="mytel">
                <xsl:with-param name="tel" select="$thetel"/>
            </xsl:call-template>
        </xsl:copy>
    </xsl:template>

    <xsl:template name="mytel">
        <xsl:param name="tel"/>
        <xsl:param name="first" select="1"/>
        <xsl:choose>
            <xsl:when test="contains($tel,',')">
                <fo:inline>
                    <xsl:if test="$first != 1">
                        <xsl:text> </xsl:text>
                    </xsl:if>
                    <xsl:value-of select="substring-before($tel,',')"/>
                    <xsl:text> </xsl:text>
                </fo:inline>
                <xsl:call-template name="mytel">
                    <xsl:with-param name="tel" select="substring-after($tel,',')"/>
                    <xsl:with-param name="first" select="0"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <fo:inline>
                    <xsl:if test="$first != 1">
                        <xsl:text> </xsl:text>
                    </xsl:if>
                    <xsl:value-of select="$tel"/>
                </fo:inline>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

<!--                         -->
<!--  B E T R E F F          -->
<!--  (nur brief)            -->
    <xsl:template match="*[@y:mark='subject' or @id='subject']">
        <xsl:param name="brief"/>
        <xsl:copy>
            <xsl:for-each select="@*[name()!='id' and name() != 'y:mark']">
                <xsl:copy/>
            </xsl:for-each>
            <xsl:apply-templates select="$brief//y:betr/child::node()">
                <xsl:with-param name="brief" select="$brief"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>

<!--                         -->
<!--  A N R E D E            -->
<!--  (nur brief)            -->
    <xsl:template match="*[@y:mark='opening' or @id='opening']">
        <xsl:param name="brief"/>
        <xsl:copy>
            <xsl:copy-of select="@*[name()!='id' and name() != 'y:mark']"/>
            <xsl:choose>
                <xsl:when test="$brief//y:anrede/child::node()">
                    <xsl:apply-templates select="$brief//y:anrede/child::node()">
                        <xsl:with-param name="brief" select="$brief"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="local-name($brief) = 'letterhead' or local-name($brief) = 'briefkopf'"/>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>

<!--                         -->
<!--  L I E F E R D A T U M  -->
<!--  (nur rechnung/lieferschein)         -->
    <xsl:template match="*[@y:mark='lieferdatum' or @id='lieferdatum']">
        <xsl:param name="brief"/>
        <xsl:copy>
            <xsl:copy-of select="@*[name()!='id' and name() != 'y:mark']"/>
            <xsl:choose>
                <xsl:when test="$brief//y:lieferdatum/child::node()">
                    <xsl:apply-templates select="$brief//y:lieferdatum/child::node()">
                        <xsl:with-param name="brief" select="$brief"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>&#160;</xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>

<!--                         -->
<!--  R E F.  K U N D E      -->
<!--  (nur rechnung/lieferschein)         -->
    <xsl:template match="*[@y:mark='yourref' or @id='yourref']">
        <xsl:param name="brief"/>
        <xsl:copy>
            <xsl:for-each select="@*[name()!='id' and name()!='y:mark']"><!-- xsl:for-each select="@*[name()!='id']" -->
   <!-- xsl:message><xsl:value-of select="concat('&#xa;***',$brief/@yourref,'***&#xa;')"/></xsl:message -->
                <xsl:copy/>
            </xsl:for-each>
            <xsl:choose>
                <xsl:when test="$brief/@yourref">
                    <xsl:value-of select="$brief/@yourref"/>
                </xsl:when>
                <xsl:otherwise>&#160;</xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>

<!--                         -->
<!--  K U N D E N N R        -->
<!--  (nur rechnung/lieferschein)         -->
    <xsl:template match="*[@y:mark='kdnr' or @id='kdnr']">
        <xsl:param name="brief"/>
        <xsl:copy>
            <xsl:copy-of select="@*[name()!='id' and name() != 'y:mark']"/>
            <xsl:choose>
                <xsl:when test="$brief//y:kdnr/child::node()">
                    <xsl:apply-templates select="$brief//y:kdnr/child::node()">
                        <xsl:with-param name="brief" select="$brief"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>&#160;</xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>

<!--                         -->
<!--  R E C H N N R          -->
<!--  (nur rechnung/lieferschein)         -->
    <xsl:template match="*[@y:mark='rechnr' or @id='rechnr']">
        <xsl:param name="brief"/>
        <xsl:copy>
            <xsl:copy-of select="@*[name()!='id' and name() != 'y:mark']"/>
            <xsl:value-of select="$brief/@nr"/>
        </xsl:copy>
    </xsl:template>

<!--                         -->
<!-- Z A H L U N G S B E D I -->
<!--  (nur rechnung)         -->
    <xsl:template match="*[@y:mark='zahlbed' or @id='zahlbed']">
        <xsl:param name="brief"/>
        <xsl:choose>
            <xsl:when test="$brief//y:zahlbed/node()">
                <xsl:copy>
                    <xsl:copy-of select="@*[name()!='id' and name() != 'y:mark']"/>
                    <xsl:apply-templates select="$brief//y:zahlbed/node()"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

<!--                         -->
<!-- U S T P F L I C H T    -->
<!--  (nur rechnung)         -->
    <xsl:template match="*[starts-with(@y:mark,'vatliab') or starts-with(@id,'vatliab')]">
        <xsl:param name="brief"/>
        <xsl:if test="$brief/@novat">
            <xsl:copy>
                <xsl:copy-of select="@*[name()!='id' and name() != 'y:mark']"/>
                <xsl:apply-templates>
                    <xsl:with-param name="brief" select="$brief"/>
                </xsl:apply-templates>
            </xsl:copy>
        </xsl:if>
    </xsl:template>

<!--                         -->
<!-- U S T I D  RE EMPF    -->
<!--  (nur rechnung)         -->
    <xsl:template match="*[@y:mark='vatidrec' or @id = 'vatidrec']">
        <xsl:param name="brief"/>
        <xsl:choose>
            <xsl:when test="$brief/@vatidrec">
                <xsl:copy>
                    <xsl:copy-of select="@*[name()!='id' and name() != 'y:mark']"/>
                    <xsl:value-of select="$brief/@vatidrec"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@*[name()!='id' and name() != 'y:mark']"/>
                    <xsl:value-of select="."/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="*[@y:mark='vatidreccontainer']">
        <xsl:param name="brief"/>
        <xsl:if test="$brief/@vatidrec">
            <xsl:copy>
                <xsl:copy-of select="@*[name()!='id' and name() != 'y:mark']"/>
                <xsl:apply-templates>
                    <xsl:with-param name="brief" select="$brief"/>
                </xsl:apply-templates>
            </xsl:copy>
        </xsl:if>
    </xsl:template>



<!--                         -->
<!-- V E R S I O N E N       -->
<!--                         -->
    <xsl:template match="*[@y:mark='xgenerator']">
        <xsl:param name="brief"/>
        <xsl:param name="rechinfo"/>
        <xsl:param name="master"/>
        <xsl:variable name="versionstring" select="y:vers()"/>
        <xsl:copy>
            <xsl:copy-of select="@*[name() != 'y:mark']"/>
            <xsl:value-of select="$versionstring"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="*[@y:mark='generator']">
        <xsl:param name="brief"/>
        <xsl:param name="rechinfo"/>
        <xsl:param name="master"/>
        <xsl:variable name="versionstring" select="y:vers()"/>
        <xsl:copy>
            <xsl:copy-of select="@*[name() != 'y:mark']"/>
            <xsl:value-of select="concat('xml-xslt-fo-pdf chain brief_to_fo ',$versionstring)"/>
        </xsl:copy>
    </xsl:template>

    <fx:function name="y:vers">
        <xsl:variable name="versis0">
            <X>
                <xsl:value-of select="$xslversion"/>
            </X>
            <xsl:if test="0 != $scriptvers">
                <S>
                    <xsl:value-of select="$scriptvers"/>
                </S>
            </xsl:if>
            <L>
                <xsl:value-of select="$layouts/z:config/@version"/>
            </L>
            <b>
                <xsl:value-of select="$usedmaster/fo:root/@y:version"/>
            </b>
        </xsl:variable>
        <xsl:variable name="versis" select="ex:node-set($versis0)"/>
        <fx:result>
            <xsl:for-each select="$versis/*">
                <xsl:variable name="curvers" select="string(.)"/>
                <xsl:if test="not(following::*[string(.) = $curvers])">
        <!--xsl:message><xsl:value-of select="$curvers"/></xsl:message-->
                    <xsl:for-each select="$versis/*[string(.) = $curvers]">
                        <xsl:choose>
                            <xsl:when test="name() = 'b' and '' != $layouts/z:config/z:types/z:type[@master=$usedmaster/fo:root/@y:thisname]/@short">
                                <xsl:value-of select="$layouts/z:config/z:types/z:type[@master=$usedmaster/fo:root/@y:thisname]/@short"/>
                            </xsl:when>
                            <xsl:when test="name() = 'b'">
                                <xsl:text>..</xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="local-name()"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                    <xsl:value-of select="concat(' ',$curvers,' ')"/>
                </xsl:if>
            </xsl:for-each>
        </fx:result>
    </fx:function>


<!--                         -->
<!-- M O D s                 -->
<!--                         -->
    <xsl:template match="*[starts-with(@y:mark,'mod:')]">
        <xsl:param name="brief"/>
        <xsl:param name="rechinfo"/>
        <xsl:param name="master"/>
        <xsl:variable name="attribname" select="substring-before(substring-after(@y:mark,'mod:'),':')"/>
        <xsl:variable name="modparam" select="substring-before(substring-after(substring-after(concat(@y:mark,','),'mod:'),':'),',')"/>
        <xsl:variable name="elname" select="name()"/>
 
        <!-- recurse ?? -->
        <xsl:choose>
            <xsl:when test="'' = substring-after(@y:mark,concat(':',$modparam,','))">
                <xsl:variable name="nparam2" select="y:getmodval($modparam)"/>
                <!--xsl:message><xsl:value-of select="concat('SCH   an ',$attribname, ' mp ',$modparam,'  blc ',@border-left-color, '  na ',name(),'  NP2 ',$nparam2)"/></xsl:message -->
                <xsl:choose>
                    <xsl:when test="$nparam2">
                        <xsl:copy>
                            <xsl:copy-of select="@*[name() != $attribname and name()!='y:mark']"/>
                            <xsl:attribute name="{$attribname}">
                                <xsl:value-of select="$nparam2"/>
                            </xsl:attribute>
                            <xsl:apply-templates>
                                <xsl:with-param name="master" select="$master"/>
                                <xsl:with-param name="brief" select="$brief"/>
                                <xsl:with-param name="rechinfo" select="$rechinfo"/>
                            </xsl:apply-templates>
                        </xsl:copy>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy>
                            <xsl:copy-of select="@*[name()!='y:mark']"/>
                            <xsl:apply-templates>
                                <xsl:with-param name="master" select="$master"/>
                                <xsl:with-param name="brief" select="$brief"/>
                                <xsl:with-param name="rechinfo" select="$rechinfo"/>
                            </xsl:apply-templates>
                        </xsl:copy>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <!-- there are more marks -->
                <xsl:variable name="nparam2" select="y:getmodval($modparam)"/>
                <!--xsl:message><xsl:value-of select="concat('SCHSCH   an ',$attribname, ' mp ',$modparam,'  blc ',@border-left-color, '  na ',name(),'  NP2 ',$nparam2)"/></xsl:message -->

                <xsl:choose>
                    <xsl:when test="$nparam2">
                        <xsl:variable name="ohnedies">
                            <xsl:copy>
                                <xsl:attribute name="y:mark">
                                    <xsl:value-of select="concat('mod:',substring-after(@y:mark,concat(':',$modparam,',')))"/>
                                </xsl:attribute>
                                <xsl:copy-of select="@*[name() != $attribname and name()!='y:mark']"/>
                                <xsl:attribute name="{$attribname}">
                                    <xsl:value-of select="$nparam2"/>
                                </xsl:attribute>
                                <xsl:copy-of select="*"/>
                            </xsl:copy>
                        </xsl:variable>
                        <xsl:apply-templates select="ex:node-set($ohnedies)/*">
                            <xsl:with-param name="master" select="$master"/>
                            <xsl:with-param name="brief" select="$brief"/>
                            <xsl:with-param name="rechinfo" select="$rechinfo"/>
                        </xsl:apply-templates>
                        <!--xsl:message><xsl:value-of select="concat('OHNE  an ',ex:node-set($ohnedies)//@*[name() = $attribname], '  mark  ',ex:node-set($ohnedies)//@y:mark)"/></xsl:message -->
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="ohnedies">
                            <xsl:copy>
                                <xsl:attribute name="y:mark">
                                    <xsl:value-of select="concat('mod:',substring-after(@y:mark,concat(':',$modparam,',')))"/>
                                </xsl:attribute>
                                <xsl:copy-of select="@*[name()!='y:mark']"/>
                                <xsl:copy-of select="*"/>
                            </xsl:copy>
                        </xsl:variable>
                        <xsl:apply-templates select="ex:node-set($ohnedies)/*">
                            <xsl:with-param name="master" select="$master"/>
                            <xsl:with-param name="brief" select="$brief"/>
                            <xsl:with-param name="rechinfo" select="$rechinfo"/>
                        </xsl:apply-templates>
                    </xsl:otherwise>
                </xsl:choose>

            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>

    <fx:function name="y:getmodval">
        <xsl:param name="modparam"/>
        <xsl:choose>
            <!-- explicit param -->
            <xsl:when test="contains(concat(',',$mod),concat(',',$modparam,':'))">
                <xsl:variable name="nparam" select="substring-after(concat(',',$mod),concat(',',$modparam,':'))"/>
                <xsl:variable name="nparam2">
                    <xsl:choose>
                        <xsl:when test="contains($nparam,',')">
                            <xsl:value-of select="substring-before($nparam,',')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$nparam"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <fx:result select="$nparam2"/>
            </xsl:when>
            <!-- group param -->
            <xsl:when test="$layouts/z:config/z:modgroups/z:modgroup[
                        contains(
                            concat(',',$mod,','),
                            concat(',group:',@name,',')
                        ) and 
                        contains(
                            concat(',',@mods),
                            concat(',',$modparam,':')
                        )
                    ]">
                <xsl:variable name="nparam" select="
        substring-before(
            concat(
                substring-after(
                    concat(',',
                        $layouts/z:config/z:modgroups/z:modgroup[
                            contains(
                                concat(',',$mod,','),
                                concat(',group:',@name,',')
                            ) and 
                            contains(
                                concat(',',@mods),
                                concat(',',$modparam,':')
                            )
                        ][1]/@mods
                    ),
                    concat(
                        ',',$modparam,':')
                 ),','
              ),','
          )"/>
                <xsl:variable name="nparam2">
                    <xsl:choose>
                        <xsl:when test="contains($nparam,',')">
                            <xsl:value-of select="substring-before($nparam,',')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$nparam"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <fx:result select="$nparam2"/>
            </xsl:when>
            <!-- leyout group -->
            <xsl:when test="$layouts/z:config/z:modgroups/z:modgroup[
                        contains(
                            concat(',',$layouts/z:config/z:layouts/z:layout[@name=$mainstream]/@modgroups,','),
                            concat(',',@name,',')
                        ) and 
                        contains(
                            concat(',',@mods),
                            concat(',',$modparam,':')
                        )
                    ]">
                <xsl:variable name="nparam" select="
        substring-before(
            concat(
                substring-after(
                    concat(',',
                        $layouts/z:config/z:modgroups/z:modgroup[
                            contains(
                                concat(',',$layouts/z:config/z:layouts/z:layout[@name=$mainstream]/@modgroups,','),
                                concat(',',@name,',')
                            ) and 
                            contains(
                                concat(',',@mods),
                                concat(',',$modparam,':')
                            )
                        ][1]/@mods
                    ),
                    concat(
                        ',',$modparam,':')
                 ),','
              ),','
          )"/>
                <xsl:variable name="nparam2">
                    <xsl:choose>
                        <xsl:when test="contains($nparam,',')">
                            <xsl:value-of select="substring-before($nparam,',')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$nparam"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <fx:result select="$nparam2"/>
            </xsl:when>
            <!-- *default* param -->
            <xsl:when test="$layouts/z:config/z:modgroups/z:modgroup[
                        '*default*' = @name
                        and 
                        contains(
                            concat(',',@mods),
                            concat(',',$modparam,':')
                        )
                    ]">
                <xsl:variable name="nparam" select="
        substring-before(
            concat(
                substring-after(
                    concat(',',
                        $layouts/z:config/z:modgroups/z:modgroup[
                            '*default*' = @name
                            and 
                            contains(
                                concat(',',@mods),
                                concat(',',$modparam,':')
                            )
                        ][1]/@mods
                    ),
                    concat(
                        ',',$modparam,':')
                 ),','
              ),','
          )"/>
                <xsl:variable name="nparam2">
                    <xsl:choose>
                        <xsl:when test="contains($nparam,',')">
                            <xsl:value-of select="substring-before($nparam,',')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$nparam"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <fx:result select="$nparam2"/>
            </xsl:when>
            <xsl:otherwise>
                <fx:result select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </fx:function>

<!--                         -->
<!-- A N L A G E N  /  P.S.  -->
<!--                         -->
    <xsl:template match="*[@y:mark='enclblock' or @id='enclblock']">
        <xsl:param name="brief"/>
        <xsl:if test="$brief//y:anlage/node()">
            <xsl:copy>
                <xsl:copy-of select="@*[name()!='id' and name() != 'y:mark']"/>
                <xsl:apply-templates>
                    <xsl:with-param name="brief" select="$brief"/>
                </xsl:apply-templates>
            </xsl:copy>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*[@y:mark='digisig' or @id='digisig']">
        <xsl:param name="brief"/>
  <!-- xsl:if test="'' != $signer">
   <xsl:copy><xsl:copy-of select="@*[name()!='id' and name() != 'y:mark']"/>
     <xsl:copy-of select="concat(y:xlate('signedby'),' ',$signer)"/>
    </xsl:copy>
  </xsl:if-->
    </xsl:template>

    <xsl:template match="*[@y:mark='visisig' or @id='visisig']">
        <xsl:param name="brief"/>
   <!--xsl:copy><xsl:copy-of select="@*[name()!='id' and name() != 'y:mark']"/>
     <fo:block vertical-align="bottom" role="none">visible&amp;signature@space_from§outer%space</fo:block>
    </xsl:copy-->
    </xsl:template>

    <xsl:template match="*[@y:mark='encl' or @id='encl']">
        <xsl:param name="brief"/>
        <xsl:choose>
            <xsl:when test="'' != $embedname  and '' = $pdfprofile and ($embedlink='anlage' or $embedlink='encl')">
                <fo:basic-link external-destination="{concat('url(embedded-file:',$embedfilename,')')}" color="blue">
                    <fo:inline font-size="66%">
                        <xsl:copy-of select="y:xlate('seelink')"/>&#xa0;</fo:inline>
                    <xsl:apply-templates select="$brief/y:anlage/node()"/>
                </fo:basic-link>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="$brief/y:anlage/node()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="*[@y:mark='ps' or @id='ps']">
        <xsl:param name="brief"/>
        <xsl:variable name="thisps" select="."/>
        <xsl:choose>
            <xsl:when test="'' != $brief//y:ps">
                <xsl:for-each select="$brief//y:ps">
                    <xsl:variable name="briefps" select="."/>
                    <xsl:for-each select="$thisps">
                        <xsl:copy>
                            <xsl:copy-of select="@*[name()!='id' and name() != 'y:mark']"/>
                            <xsl:apply-templates select="$briefps/node()"/>
                        </xsl:copy>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>

<!--                         -->
<!--  G R U S S              -->
<!--                         -->
    <xsl:template match="*[@y:mark='closing' or @id='closing']">
        <xsl:param name="brief"/>
        <xsl:variable name="this" select="."/>
        <xsl:copy>
            <xsl:copy-of select="@*[name()!='id' and name() != 'y:mark']"/>
            <xsl:choose>
                <xsl:when test="$brief//y:mfg/child::node()">

                    <xsl:apply-templates mode="textblock" select="$brief//y:mfg">
                        <xsl:with-param name="theblock" select="$this"/>
                        <xsl:with-param name="brief" select="$brief"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>

<!--                         -->
<!--  T E X T A B S A T Z    -->
<!--                         -->
    <xsl:template match="*[starts-with(@y:mark,'txt') or starts-with(@id,'txt')]">
        <xsl:param name="brief"/>
        <xsl:param name="rechinfo"/>
        <xsl:variable name="this" select="."/>
        <xsl:apply-templates mode="textblock" select="$brief//y:txt">
            <xsl:with-param name="theblock" select="$this"/>
            <xsl:with-param name="brief" select="$brief"/>
            <xsl:with-param name="rechinfo" select="$rechinfo"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="*" mode="textblock">
        <xsl:param name="theblock"/>
        <xsl:param name="brief"/>
        <xsl:param name="rechinfo"/>
        <fo:block>
            <xsl:for-each select="$theblock/@*[name() != 'y:mark']">
                <xsl:copy/>
            </xsl:for-each>
            <xsl:apply-templates select="node()">
                <xsl:with-param name="brief" select="$brief"/>
                <xsl:with-param name="rechinfo" select="$rechinfo"/>
            </xsl:apply-templates>
        </fo:block>
    </xsl:template>

<!--                         -->
<!--  R E C H - P O S I T    -->
<!--  (nur rechnung/lieferschein)         -->
    <xsl:template match="*[@y:mark='posi' or @id='posi']">
        <xsl:param name="brief"/>
        <xsl:param name="rechinfo"/>
        <xsl:variable name="this" select="."/>
        <xsl:apply-templates mode="posline" select="$brief//y:positionen/y:position">
            <xsl:with-param name="posfmt" select="$this"/>
            <xsl:with-param name="rechinfo" select="$rechinfo"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="y:position" mode="posline">
        <xsl:param name="posfmt"/>
        <xsl:param name="rechinfo"/>
        <xsl:variable name="position" select="."/>
        <xsl:variable name="posnr" select="position()"/>
        <xsl:element name="{name($posfmt)}">
            <xsl:for-each select="$posfmt/@*[name()!='id' and name() != 'y:mark']">
                <xsl:copy/>
            </xsl:for-each>
            <xsl:apply-templates mode="posline" select="$posfmt/*">
                <xsl:with-param name="position" select="$position"/>
                <xsl:with-param name="posnr" select="$posnr"/>
                <xsl:with-param name="rechinfo" select="$rechinfo"/>
                <xsl:with-param name="anzahl">
                    <xsl:choose>
                        <xsl:when test="count($position/y:anz/node()) = 1">
                            <xsl:value-of select="number(translate($position/y:anz,',','.'))"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="number(translate($position/y:anz/y:num,',','.'))"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:with-param>
            </xsl:apply-templates>
        </xsl:element>
    </xsl:template>

    <xsl:template match="*[not(@id) and namespace-uri(.) = 'http://www.w3.org/1999/XSL/Format']" mode="posline">
        <xsl:param name="position"/>
        <xsl:param name="posnr"/>
        <xsl:param name="anzahl"/>
        <xsl:param name="rechinfo"/>
        <xsl:copy>
            <xsl:copy-of select="@*[name()!='id' and name() != 'y:mark']"/>
            <xsl:apply-templates select="node()" mode="posline">
                <xsl:with-param name="position" select="$position"/>
                <xsl:with-param name="anzahl" select="$anzahl"/>
                <xsl:with-param name="posnr" select="$posnr"/>
                <xsl:with-param name="rechinfo" select="$rechinfo"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="*[@y:mark='posnr' or @id='posnr']" mode="posline">
        <xsl:param name="position"/>
        <xsl:param name="posnr"/>
        <xsl:param name="anzahl"/>
        <xsl:copy>
            <xsl:copy-of select="@*[name()!='id' and name() != 'y:mark']"/>
            <xsl:value-of select="$posnr"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="*[@y:mark='postxt' or @id='postxt']" mode="posline">
        <xsl:param name="position"/>
        <xsl:param name="posnr"/>
        <xsl:param name="anzahl"/>
        <xsl:copy>
            <xsl:copy-of select="@*[name()!='id' and name() != 'y:mark']"/>
            <xsl:apply-templates select="$position/y:txt/node()" mode="posline"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="*[@y:mark='anz' or @id='anz']" mode="posline">
        <xsl:param name="position"/>
        <xsl:param name="posnr"/>
        <xsl:param name="anzahl"/>
        <xsl:element name="{name(.)}">
            <xsl:copy-of select="@*[name()!='id' and name() != 'y:mark']"/>
            <xsl:choose>
                <xsl:when test="count($position/y:anz/node()) = 1">
                    <xsl:value-of select="hx:mynum(number($anzahl))"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="$position/y:anz/y:num/preceding-sibling::node()"/>
                    <xsl:value-of select="hx:mynum(number($anzahl))"/>
                    <xsl:apply-templates select="$position/y:anz/y:num/following-sibling::node()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

    <xsl:template match="*[@y:mark='satz' or @id='satz']" mode="posline">
        <xsl:param name="position"/>
        <xsl:param name="posnr"/>
        <xsl:param name="anzahl"/>
        <xsl:copy>
            <xsl:copy-of select="@*[name()!='id' and name() != 'y:mark']"/>
            <xsl:value-of select="hx:mynum($position/y:satz/node(),2)"/>
            <xsl:text> </xsl:text>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="*[@y:mark='possum' or @id='possum']" mode="posline">
        <xsl:param name="position"/>
        <xsl:param name="posnr"/>
        <xsl:param name="anzahl"/>
        <xsl:param name="rechinfo"/>
        <xsl:element name="{name(.)}">
            <xsl:copy-of select="@*[name()!='id' and name() != 'y:mark']"/>
            <xsl:value-of select="hx:mynum($rechinfo//hx:vat/hx:pos[@posis=$posnr]/@sum,2)"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="text()" mode="posline">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>

    <xsl:template match="*" mode="posline">
        <xsl:param name="position"/>
        <xsl:param name="posnr"/>
        <xsl:param name="anzahl"/>
        <xsl:param name="rechinfo"/>
        <xsl:apply-templates select=".">
            <xsl:with-param name="brief" select="$position"/>
            <xsl:with-param name="rechinfo" select="$rechinfo"/>
        </xsl:apply-templates>
    </xsl:template>

<!--                         -->
<!--  R E C H - S U M M E N  -->
<!--  (nur rechnung/lieferschein)         -->
    <xsl:template match="*[@y:mark='netsum' or @id='netsum']">
        <xsl:param name="brief"/>
        <xsl:param name="rechinfo"/>
        <xsl:element name="{name(.)}">
            <xsl:for-each select="@*[name()!='id' and name() != 'y:mark']">
                <xsl:copy/>
            </xsl:for-each>
            <xsl:value-of select="hx:mynum($rechinfo//hx:sums/@net,2)"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="*[@y:mark='sum' or @id='sum']">
        <xsl:param name="brief"/>
        <xsl:param name="rechinfo"/>
        <xsl:element name="{name(.)}">
            <xsl:for-each select="@*[name()!='id' and name() != 'y:mark']">
                <xsl:copy/>
            </xsl:for-each>
            <xsl:value-of select="hx:mynum($rechinfo//hx:sums/@gross,2)"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="y:position" mode="summs">
        <xsl:param name="allepos"/>
        <xsl:param name="schonda"/>
        <xsl:param name="indx"/>
        <xsl:variable name="xschonda" select="ex:node-set($schonda)"/>
        <xsl:if test="position() = $indx">
            <xsl:variable name="position" select="."/>
            <xsl:variable name="anzahl">
                <xsl:choose>
                    <xsl:when test="count($position/y:anz/node()) = 1">
                        <xsl:value-of select="number(translate($position/y:anz,',','.'))"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="number(translate($position/y:anz/y:num,',','.'))"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="not($xschonda/hx:diffvats/hx:vat[number(@vat)=number(current()/y:mwst)])">
                    <!-- neuer mwst satz -->
                    <xsl:variable name="nunda">
                        <xsl:apply-templates mode="newmwst" select="$xschonda/*">
                            <xsl:with-param name="satz" select="$position/y:mwst"/>
                            <xsl:with-param name="netto" select="(round(100 * $anzahl * number(translate($position/y:satz,',','.')))) div 100"/>
                            <xsl:with-param name="position" select="$indx"/>
                        </xsl:apply-templates>
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="$indx &lt; count($allepos)">
                            <xsl:apply-templates select="$allepos" mode="summs">
                                <xsl:with-param name="allepos" select="$allepos"/>
                                <xsl:with-param name="schonda" select="$nunda"/>
                                <xsl:with-param name="indx" select="$indx + 1"/>
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy-of select="$nunda"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <!-- mwst satz schon drin -->
                    <xsl:variable name="nunda">
                        <xsl:apply-templates mode="addtomwst" select="$xschonda/*">
                            <xsl:with-param name="satz" select="$position/y:mwst"/>
                            <xsl:with-param name="netto" select="(round(100 * $anzahl * number(translate($position/y:satz,',','.')))) div 100"/>
                            <xsl:with-param name="position" select="$indx"/>
                        </xsl:apply-templates>
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="$indx &lt; count($allepos)">
                            <xsl:apply-templates select="$allepos" mode="summs">
                                <xsl:with-param name="allepos" select="$allepos"/>
                                <xsl:with-param name="schonda" select="$nunda"/>
                                <xsl:with-param name="indx" select="$indx + 1"/>
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy-of select="$nunda"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*" mode="addtomwst">
        <xsl:param name="satz"/>
        <xsl:param name="netto"/>
        <xsl:param name="position"/>
        <xsl:copy>
            <xsl:apply-templates mode="addtomwst">
                <xsl:with-param name="satz" select="$satz"/>
                <xsl:with-param name="netto" select="$netto"/>
                <xsl:with-param name="position" select="$position"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="*" mode="newmwst">
        <xsl:param name="satz"/>
        <xsl:param name="netto"/>
        <xsl:param name="position"/>
        <xsl:copy>
            <xsl:apply-templates mode="newmwst">
                <xsl:with-param name="satz" select="$satz"/>
                <xsl:with-param name="netto" select="$netto"/>
                <xsl:with-param name="position" select="$position"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="hx:vat" mode="addtomwst">
        <xsl:param name="satz"/>
        <xsl:param name="netto"/>
        <xsl:param name="position"/>
        <xsl:choose>
            <xsl:when test="number(@vat) = number($satz)">
                <xsl:copy>
                    <xsl:attribute name="{'vat'}">
                        <xsl:value-of select="@vat"/>
                    </xsl:attribute>
                    <xsl:attribute name="{'sum'}">
                        <xsl:value-of select="number(@sum) + number($netto)"/>
                    </xsl:attribute>
                    <xsl:attribute name="{'posis'}">
                        <xsl:value-of select="concat(@posis,', ', $position)"/>
                    </xsl:attribute>
                    <xsl:attribute name="{'vatval'}">
                        <xsl:value-of select="round(number(@vat) * (number(@sum) + number($netto))) div 100"/>
                    </xsl:attribute>
                    <xsl:attribute name="{'gross'}">
                        <xsl:value-of select="round((100 + number(@vat)) * (number(@sum) + number($netto))) div 100"/>
                    </xsl:attribute>
                    <xsl:for-each select="*">
                        <xsl:copy-of select="."/>
                    </xsl:for-each>
                    <xsl:element name="{'hx:pos'}">
                        <xsl:attribute name="{'vat'}">
                            <xsl:value-of select="$satz"/>
                        </xsl:attribute>
                        <xsl:attribute name="{'sum'}">
                            <xsl:value-of select="number($netto)"/>
                        </xsl:attribute>
                        <xsl:attribute name="{'posis'}">
                            <xsl:value-of select="$position"/>
                        </xsl:attribute>
                        <xsl:attribute name="{'vatval'}">
                            <xsl:value-of select="round(number($satz)*number($netto)) div 100"/>
                        </xsl:attribute>
                        <xsl:attribute name="{'gross'}">
                            <xsl:value-of select="round((100 + number($satz))*number($netto)) div 100"/>
                        </xsl:attribute>
                    </xsl:element>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:for-each select="@*">
                        <xsl:copy/>
                    </xsl:for-each>
                    <xsl:for-each select="*">
                        <xsl:copy-of select="."/>
                    </xsl:for-each>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="hx:diffvats" mode="newmwst">
        <xsl:param name="satz"/>
        <xsl:param name="netto"/>
        <xsl:param name="position"/>
        <xsl:copy>
            <xsl:for-each select="*">
                <xsl:copy-of select="."/>
            </xsl:for-each>
            <xsl:element name="{'hx:vat'}">
                <xsl:attribute name="{'vat'}">
                    <xsl:value-of select="$satz"/>
                </xsl:attribute>
                <xsl:attribute name="{'sum'}">
                    <xsl:value-of select="number($netto)"/>
                </xsl:attribute>
                <xsl:attribute name="{'posis'}">
                    <xsl:value-of select="$position"/>
                </xsl:attribute>
                <xsl:attribute name="{'vatval'}">
                    <xsl:value-of select="round(number($satz)*number($netto)) div 100"/>
                </xsl:attribute>
                <xsl:attribute name="{'gross'}">
                    <xsl:value-of select="round((100 + number($satz))*number($netto)) div 100"/>
                </xsl:attribute>
                <xsl:element name="{'hx:pos'}">
                    <xsl:attribute name="{'vat'}">
                        <xsl:value-of select="$satz"/>
                    </xsl:attribute>
                    <xsl:attribute name="{'sum'}">
                        <xsl:value-of select="number($netto)"/>
                    </xsl:attribute>
                    <xsl:attribute name="{'posis'}">
                        <xsl:value-of select="$position"/>
                    </xsl:attribute>
                    <xsl:attribute name="{'vatval'}">
                        <xsl:value-of select="round(number($satz)*number($netto)) div 100"/>
                    </xsl:attribute>
                    <xsl:attribute name="{'gross'}">
                        <xsl:value-of select="round((100 + number($satz))*number($netto)) div 100"/>
                    </xsl:attribute>
                </xsl:element>
            </xsl:element>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="hx:netsum" mode="addtomwst">
        <xsl:param name="netto"/>
        <xsl:apply-templates select="." mode="addnetto">
            <xsl:with-param name="netto" select="$netto"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="hx:netsum" mode="newmwst">
        <xsl:param name="netto"/>
        <xsl:apply-templates select="." mode="addnetto">
            <xsl:with-param name="netto" select="$netto"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="hx:netsum" mode="addnetto">
        <xsl:param name="netto"/>
        <xsl:variable name="cursum" select="number(@sum)"/>
        <xsl:copy>
            <xsl:attribute name="{'sum'}">
                <xsl:value-of select="number($cursum) + number($netto)"/>
            </xsl:attribute>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="hx:vat" mode="grossum">
        <xsl:param name="alldiffvats"/>
        <xsl:param name="gross"/>
        <xsl:param name="net"/>
        <xsl:param name="indx"/>
        <xsl:if test="position() = $indx">
            <xsl:choose>
                <xsl:when test="$indx &lt; count($alldiffvats)">
                    <xsl:apply-templates select="$alldiffvats" mode="grossum">
                        <xsl:with-param name="alldiffvats" select="$alldiffvats"/>
                        <xsl:with-param name="gross" select="$gross + @gross"/>
                        <xsl:with-param name="net" select="$net + @sum"/>
                        <xsl:with-param name="indx" select="$indx + 1"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <hx:sums>
                        <xsl:attribute name="{'gross'}">
                            <xsl:value-of select="$gross + @gross"/>
                        </xsl:attribute>
                        <xsl:attribute name="{'net'}">
                            <xsl:value-of select="$net + @sum"/>
                        </xsl:attribute> ende rechinfo. </hx:sums>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>

<!--                         -->
<!--  M W S T  Z E I L E N   -->
<!--  (nur rechnung)         -->
    <xsl:template match="*[@y:mark='vatrow' or @id='vatrow']">
        <xsl:param name="brief"/>
        <xsl:param name="rechinfo"/>
        <xsl:variable name="this" select="."/>
        <xsl:apply-templates mode="vatline" select="$rechinfo//hx:vat">
            <xsl:with-param name="vatfmt" select="$this"/>
            <xsl:with-param name="anzahl" select="count($rechinfo//hx:vat)"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="hx:vat" mode="vatline">
        <xsl:param name="vatfmt"/>
        <xsl:param name="anzahl"/>
        <xsl:variable name="position" select="."/>
        <xsl:variable name="posnr" select="position()"/>
        <xsl:element name="{name($vatfmt)}">
            <xsl:for-each select="$vatfmt/@*[name()!='id' and name() != 'y:mark']">
                <xsl:copy/>
            </xsl:for-each>
            <xsl:apply-templates mode="vatline" select="$vatfmt/*">
                <xsl:with-param name="position" select="$position"/>
                <xsl:with-param name="anzahl" select="$anzahl"/>
            </xsl:apply-templates>
        </xsl:element>
    </xsl:template>

    <xsl:template match="*[not(@id) and not(@y:mark) and namespace-uri() = 'http://www.w3.org/1999/XSL/Format']" mode="vatline">
        <xsl:param name="position"/>
        <xsl:param name="posnr"/>
        <xsl:param name="anzahl"/>
        <xsl:copy>
            <xsl:for-each select="@*">
                <xsl:copy/>
            </xsl:for-each>
            <xsl:apply-templates select="node()" mode="vatline">
                <xsl:with-param name="position" select="$position"/>
                <xsl:with-param name="anzahl" select="$anzahl"/>
                <xsl:with-param name="posnr" select="$posnr"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="*[@y:mark='vatval' or @id='vatval']" mode="vatline">
        <xsl:param name="position"/>
        <xsl:param name="posnr"/>
        <xsl:param name="anzahl"/>
        <xsl:copy>
            <xsl:for-each select="@*[name()!='id' and name() != 'y:mark']">
                <xsl:copy/>
            </xsl:for-each>
            <xsl:value-of select="hx:mynum($position/@sum,2)"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="*[@y:mark='vatposis' or @id='vatposis']" mode="vatline">
        <xsl:param name="position"/>
        <xsl:param name="posnr"/>
        <xsl:param name="anzahl"/>
        <xsl:if test="number($anzahl) &gt; 1">
            <xsl:copy>
                <xsl:for-each select="@*[name()!='id' and name() != 'y:mark']">
                    <xsl:copy/>
                </xsl:for-each>
                <xsl:text>(Pos. </xsl:text>
                <xsl:value-of select="$position/@posis"/>
                <xsl:text>)</xsl:text>
            </xsl:copy>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*[@y:mark='vatperc' or @id='vatperc']" mode="vatline">
        <xsl:param name="position"/>
        <xsl:param name="posnr"/>
        <xsl:param name="anzahl"/>
        <xsl:element name="{name(.)}">
            <xsl:for-each select="@*[name()!='id' and name() != 'y:mark']">
                <xsl:copy/>
            </xsl:for-each>
            <xsl:value-of select="$position/@vat"/>
            <xsl:text>%</xsl:text>
        </xsl:element>
    </xsl:template>

    <xsl:template match="*[@y:mark='vat' or @id='vat']" mode="vatline">
        <xsl:param name="position"/>
        <xsl:param name="posnr"/>
        <xsl:param name="anzahl"/>
        <xsl:copy>
            <xsl:for-each select="@*[name()!='id' and name() != 'y:mark']">
                <xsl:copy/>
            </xsl:for-each>
            <xsl:value-of select="hx:mynum($position/@vatval,2)"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="*" mode="vatline">
        <xsl:param name="position"/>
        <xsl:param name="posnr"/>
        <xsl:param name="anzahl"/>
        <xsl:param name="rechinfo"/>
        <xsl:apply-templates select=".">
            <xsl:with-param name="brief" select="$position"/>
            <xsl:with-param name="rechinfo" select="$rechinfo"/>
        </xsl:apply-templates>
    </xsl:template>


<!--                         -->
<!--  D E F A U L T   F O    -->
<!--                         -->
<!-- xsl:template match="*[not(@id) and namespace-uri(.) = 'http://www.w3.org/1999/XSL/Format']" -->
    <xsl:template match="*">
        <xsl:param name="brief"/>
        <xsl:param name="rechinfo"/>
        <xsl:copy>
            <xsl:for-each select="@*[name() != 'y:mark']">
                <xsl:copy/>
            </xsl:for-each>
            <xsl:apply-templates select="node()">
                <xsl:with-param name="brief" select="$brief"/>
                <xsl:with-param name="rechinfo" select="$rechinfo"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>

<!--                         -->
<!--  E U R O,   R E S T     -->
<!--                         -->
    <xsl:template match="y:eur | euro">
        <xsl:variable name="modparam" select="'eurofont'"/>
        <xsl:variable name="nparam2" select="y:getmodval($modparam)"/>
        <xsl:choose>
            <xsl:when test="'' != $nparam2">
                <fo:inline font-family="{$nparam2}">€</fo:inline>
            </xsl:when>
            <xsl:otherwise>
                <fo:inline>€</fo:inline>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


<!--                         -->
<!--  M E T A D A T E N      -->
<!--                         -->
    <xsl:template match="*[@y:mark='meta_title' or @id='meta_title']">
        <xsl:param name="brief"/>
        <xsl:param name="rechinfo"/>
        <xsl:copy>
            <xsl:for-each select="@*[name()!='id' and name() != 'y:mark']">
                <xsl:copy/>
            </xsl:for-each>
            <rdf:Alt>
                <rdf:li xml:lang="{'x-default'}">
                    <xsl:choose>
                        <xsl:when test="starts-with(local-name($brief),'letter')  or starts-with(local-name($brief),'brief')">
                            <xsl:choose>
                                <xsl:when test="$pdfprofile != '' and '' = normalize-space($brief/y:betr)">
                                    <!-- empty title is not good, verapdf check will fail -->
                                    <xsl:value-of select="concat(local-name($brief),' ',$brief/y:betr)"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$brief/y:betr"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="concat(local-name($brief), ' ', $brief/@nr, ' - ', $brief//y:an/y:z1)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </rdf:li>
            </rdf:Alt>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="*[@y:mark='meta_desc' or @id='meta_desc']">
        <xsl:param name="brief"/>
        <xsl:param name="rechinfo"/>
        <xsl:copy>
            <xsl:for-each select="@*[name()!='id' and name() != 'y:mark']">
                <xsl:copy/>
            </xsl:for-each>
            <!-- auch oben beim exiftool im kommentar anpasse  - nicht mehr noetig -->
            <rdf:Alt>
                <rdf:li xml:lang="{'x-default'}">
                    <xsl:value-of select="concat(local-name($brief), ' ', $brief/@nr, ' - ', $brief//y:an/y:z1, ' ', $brief//y:an/y:z2, ' - ', $docdate, ' (', $normdate,')')"/>
                </rdf:li>
            </rdf:Alt>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="*[@y:mark='meta_author' or @id='meta_author']">
        <xsl:param name="brief"/>
        <xsl:param name="rechinfo"/>
        <xsl:if test="$brief/@contact != '' and $layouts/z:config/z:contacts/z:contact[@ref = $brief/@contact] or '' != normalize-space(.)">
            <xsl:copy>
                <xsl:copy-of select="@*[name()!='id' and name() != 'y:mark']"/>
                <rdf:Seq>
                    <rdf:li>
                        <xsl:choose>
                            <xsl:when test="'' != normalize-space(.) and $brief/@contact != '' and $layouts/z:config/z:contacts/z:contact[@ref = $brief/@contact]">
                                <xsl:value-of select="concat(.,', ',$layouts/z:config/z:contacts/z:contact[@ref = $brief/@contact]/@name)"/>
                            </xsl:when>
                            <xsl:when test="$brief/@contact != '' and $layouts/z:config/z:contacts/z:contact[@ref = $brief/@contact]">
                                <xsl:value-of select="$layouts/z:config/z:contacts/z:contact[@ref = $brief/@contact]/@name"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="."/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </rdf:li>
                </rdf:Seq>
            </xsl:copy>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*[@y:mark='meta_lang' or @id='meta_lang']">
        <xsl:param name="brief"/>
        <xsl:param name="rechinfo"/>
        <xsl:copy>
            <xsl:for-each select="@*[name()!='id' and name() != 'y:mark']">
                <xsl:copy/>
            </xsl:for-each>
            <rdf:Bag>
                <rdf:li>
                    <xsl:value-of select="$sprachint"/>
                </rdf:li>
            </rdf:Bag>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="rdf:Description">
        <xsl:param name="brief"/>
        <xsl:param name="rechinfo"/>
        <xsl:copy>
            <xsl:copy-of select="@*[name()!='id' and name() != 'y:mark']"/>
            <xsl:apply-templates>
                <xsl:with-param name="brief" select="$brief"/>
                <xsl:with-param name="rechinfo" select="$rechinfo"/>
            </xsl:apply-templates>
            <!-- keywords -->
            <pdf:Keywords xmlns:pdf="http://ns.adobe.com/pdf/1.3/">
                <xsl:value-of select="concat('&#xa;',local-name($brief), ' ', $brief/@nr,',')"/>
                <xsl:value-of select="y:xlateint('datum')"/>
                <xsl:text> </xsl:text>
                <xsl:value-of select="$normdate"/>
                <xsl:text>,</xsl:text>
                <xsl:value-of select="$layouts//y:for/y:rechnungsempf[@lang = $sprachint]/@is"/>
                <xsl:for-each select="$brief//y:an/*">
                    <xsl:text>&#xa;</xsl:text>
                    <xsl:value-of select="."/>
                    <xsl:text> </xsl:text>
                </xsl:for-each>
            </pdf:Keywords>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="*[@y:mark='meta_datum' or @id='meta_datum']">
        <xsl:param name="brief"/>
        <xsl:param name="rechinfo"/>
        <xsl:copy>
            <xsl:copy-of select="@*[name()!='id' and name() != 'y:mark']"/>
            <rdf:Seq>
                <rdf:li>
                    <xsl:value-of select="$normdate"/>
                </rdf:li>
            </rdf:Seq>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="fo:declarations">
        <xsl:param name="brief"/>
        <xsl:param name="rechinfo"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:if test="$brief/@wintitle and ($brief/@wintitle = 1 or $brief/@wintitle = 'true')">
                <pdf:catalog xmlns:pdf="http://xmlgraphics.apache.org/fop/extensions/pdf">
            <!-- this will replace the window title from filename to below dc:title -->
                    <pdf:dictionary type="normal" key="ViewerPreferences">
                        <pdf:boolean key="DisplayDocTitle">true</pdf:boolean>
                    </pdf:dictionary>
                </pdf:catalog>
            </xsl:if>
            <xsl:if test="'' != $embedname">
                <pdf:embedded-file xmlns:pdf="http://xmlgraphics.apache.org/fop/extensions/pdf" filename="{$embedfilename}" description="{$embedalt}" src="{$embedname}"/>
            </xsl:if>
  <!-- x:xmpmeta xmlns:x="adobe:ns:meta/">
    <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
      <rdf:Description rdf:about=""
          xmlns:dc="http://purl.org/dc/elements/1.1/"
          xmlns:xmp="http://ns.adobe.com/xap/1.0/">
        <xmp:CreatorTool y:mark="generator">xxxx</xmp:CreatorTool-->
            <xsl:apply-templates>
                <xsl:with-param name="brief" select="$brief"/>
                <xsl:with-param name="rechinfo" select="$rechinfo"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>


<!--                         -->
<!--  H T M L   M A P P I N  -->
<!--                         -->
    <xsl:template match="h:i">
        <fo:inline font-style="italic">
            <xsl:apply-templates select="node()"/>
        </fo:inline>
    </xsl:template>

    <xsl:template match="h:b">
        <fo:inline font-weight="bold">
            <xsl:apply-templates select="node()"/>
        </fo:inline>
    </xsl:template>

    <xsl:template match="h:br">
        <xsl:text>&#xa;</xsl:text>
    </xsl:template>

    <xsl:template match="y:linkembed">
        <xsl:param name="brief"/>
        <xsl:param name="master"/>
        <xsl:param name="rechinfo"/>
        <xsl:choose>
            <xsl:when test="'' != $embedname and '' = $pdfprofile">
                <fo:basic-link external-destination="{concat('url(embedded-file:',$embedfilename,')')}" color="blue">
                    <xsl:if test="not(@nohint) or 1 != @nohint">
                        <fo:inline font-size="66%">
                            <xsl:copy-of select="y:xlate('seelink')"/>&#xa0;</fo:inline>
                    </xsl:if>
                    <xsl:apply-templates>
                        <xsl:with-param name="master" select="$master"/>
                        <xsl:with-param name="rechinfo" select="$rechinfo"/>
                        <xsl:with-param name="brief" select="$brief"/>
                    </xsl:apply-templates>
                </fo:basic-link>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates>
                    <xsl:with-param name="master" select="$master"/>
                    <xsl:with-param name="rechinfo" select="$rechinfo"/>
                    <xsl:with-param name="brief" select="$brief"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

<!--                         -->
<!--  Z A H L E N F M T      -->
<!--                         -->

    <fx:function name="hx:mynum">
        <xsl:param name="valuex"/>
        <xsl:param name="digits" select="0"/>
        <xsl:param name="decsep" select="','"/>
        <xsl:param name="thousandsep" select="'.'"/>
        <xsl:variable name="value" select="number($valuex)"/>
        <xsl:variable name="valrnd" select="round(100000*number($value)) div 100000"/>
        <xsl:variable name="vorkomma">
            <xsl:choose>
                <xsl:when test="contains(string($valrnd),'.')">
                    <xsl:value-of select="substring-before(string($valrnd),'.')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="string($valrnd)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="nachkomma">
            <xsl:choose>
                <xsl:when test="contains(string($valrnd),'.')">
                    <xsl:value-of select="substring-after(string($valrnd),'.')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="''"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="splitdrei">
            <sp>
                <xsl:call-template name="splitdrei">
                    <xsl:with-param name="v" select="$vorkomma"/>
                </xsl:call-template>
            </sp>
        </xsl:variable>
        <fx:result>
            <xsl:choose>
                <xsl:when test="$value &lt; 0">
                    <xsl:value-of select="concat('-',hx:mynum(-1 * $value,$digits,$decsep,$thousandsep))"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each select="ex:node-set($splitdrei)//hx:d">
                        <xsl:choose>
                            <xsl:when test="position() = 1">
                                <xsl:value-of select="."/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="substring(1000 + . , 2)"/>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:if test="not(position() = last())">
                            <xsl:value-of select="$thousandsep"/>
                        </xsl:if>
                    </xsl:for-each>
                    <!-- that was for the integer part -->
                    <xsl:if test="($digits &gt; 0) or (string-length($nachkomma) &gt; 0)">
                        <xsl:value-of select="$decsep"/>
                        <xsl:value-of select="$nachkomma"/>
                        <xsl:if test="string-length($nachkomma) &lt; $digits">
                            <xsl:value-of select="substring('00000000000000000000000000000000000',1,$digits - string-length($nachkomma))"/>
                        </xsl:if>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </fx:result>
    </fx:function>

    <xsl:template name="splitdrei">
        <xsl:param name="v" select="0"/>
        <xsl:choose>
            <xsl:when test="$v &lt; 1000">
                <hx:d>
                    <xsl:value-of select="$v"/>
                </hx:d>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="splitdrei">
                    <xsl:with-param name="v" select="floor($v div 1000)"/>
                </xsl:call-template>
                <hx:d>
                    <xsl:value-of select="$v mod 1000"/>
                </hx:d>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

<!--                         -->
<!--  I N C L U D E S        -->
<!--                         -->
    <xsl:template match="y:ref">
        <xsl:param name="brief"/>
        <xsl:param name="rechinfo"/>
        <xsl:param name="master"/>
        <xsl:variable name="snip" select="@snippet"/>
        <xsl:if test="$debug != 0">
            <xsl:text>&#xa;</xsl:text>
            <xsl:comment>
                <xsl:value-of select="concat('SNIPPET: ',$snip)"/>
            </xsl:comment>
            <xsl:text>&#xa;</xsl:text>
        </xsl:if>
        <xsl:for-each select="$layouts//y:snippet[@id = $snip]/*">
            <xsl:apply-templates select=".">
                <xsl:with-param name="master" select="$master"/>
                <xsl:with-param name="brief" select="$brief"/>
                <xsl:with-param name="rechinfo" select="$rechinfo"/>
            </xsl:apply-templates>
        </xsl:for-each>
        <xsl:if test="not($layouts//y:snippet[@id = $snip]/*)">
            <xsl:message>
                <xsl:value-of select="concat('****  NOT FOUND: snipped ',$snip)"/>
            </xsl:message>
        </xsl:if>
        <xsl:if test="$debug != 0">
            <xsl:text>&#xa;</xsl:text>
            <xsl:comment>
                <xsl:value-of select="concat('** END ** SNIPPET: ',$snip)"/>
            </xsl:comment>
            <xsl:text>&#xa;</xsl:text>
        </xsl:if>
    </xsl:template>

    <xsl:template match="y:snippet"/>

    <xsl:template match="fo:block[@id='lastpg' and @y:mark='lastpg']">
        <xsl:choose>
            <xsl:when test="contains(concat(',',$usedmaster/fo:root/@y:mark,','),'nolastpg')">
                <xsl:message>
                    <xsl:text>Throw out lastpg because serials</xsl:text>
                </xsl:message>
            </xsl:when>
            <xsl:when test="1 != $uselastpg">
                <xsl:message>
                    <xsl:text>Throw out lastpg because serials</xsl:text>
                </xsl:message>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:for-each select="@*[name() != 'y:mark']">
                        <xsl:copy/>
                    </xsl:for-each>
                    <xsl:apply-templates/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

<!--                         -->
<!--  P D F  O V E R L A Y S -->
<!--                         -->
    <xsl:template name="generate-page-masters">
        <xsl:param name="brief"/>
        <xsl:variable name="fullpage0">
            <xsl:apply-templates select="$layouts/z:config/z:layouts/z:layout[@name=$mainstream]" mode="normalizer">
                <xsl:with-param name="refdoc" select="$brief"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="fullpage" select="ex:node-set($fullpage0)"/>
        <!--xsl:if test="0 != $debug">
            <xsl:copy-of select="$fullpage"/>
        </xsl:if-->
        <xsl:variable name="fullpageapp0">
            <xsl:if test="'' != $appendname and $appendfmt != 'blank'">
                <xsl:apply-templates select="$layouts/z:config/z:layouts/z:layout[@name=$mainstream]" mode="normalizer">
                    <xsl:with-param name="refdoc" select="$brief//y:append"/>
                </xsl:apply-templates>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="fullpageapp" select="ex:node-set($fullpageapp0)"/>
        <fo:layout-master-set>
            <fo:simple-page-master master-name="SPM_blank" margin-right="0mm" margin-left="0mm" margin-bottom="0mm" margin-top="0mm" page-width="21cm" page-height="29.7cm">
                <fo:region-body margin-left="0mm" margin-top="0mm" margin-bottom="0mm" margin-right="0mm"/>
            </fo:simple-page-master>
            <xsl:if test="$mainstream != 'blank'">
                <xsl:copy-of select="y:buildspm(concat('SPM_',$mainstream,'_only'),
                    '_only',
                    $fullpage//@headerfirst,
                    $fullpage//@footonly,
                    ($fullpage//@pagenumbers = 'yes'),
                    ($fullpage//@visisig != 'no'),
                    $fullpage//@foldfirst,
                    ($fullpage//@vers != 'no'),
                    ($overlayname != ''))"/>
                <xsl:copy-of select="y:buildspm(concat('SPM_',$mainstream,'_first'),
                    '_first',
                    $fullpage//@headerfirst,
                    $fullpage//@footfirst,
                    ($fullpage//@pagenumbers = 'yes' or $fullpage//@pagenumbers = 'ifmore'),
                    ($fullpage//@visisig = 'first'),
                    $fullpage//@foldfirst,
                    ($fullpage//@vers = 'first'),
                    ($overlayname != ''))"/>
                <xsl:copy-of select="y:buildspm(concat('SPM_',$mainstream,'_last'),
                    '_last',
                    $fullpage//@headerrest,
                    $fullpage//@footlast,
                    ($fullpage//@pagenumbers = 'yes' or $fullpage//@pagenumbers = 'ifmore'),
                    ($fullpage//@visisig = 'last'),
                    $fullpage//@foldrest,
                    ($fullpage//@vers = 'last'),
                    ($overlayname != ''))"/>
                <xsl:copy-of select="y:buildspm(concat('SPM_',$mainstream,'_rest'),
                    '_last',
                    $fullpage//@headerrest,
                    $fullpage//@footrest,
                    ($fullpage//@pagenumbers = 'yes' or $fullpage//@pagenumbers = 'ifmore'),
                    ($fullpage//@visisig = 'kommtnetvor'),
                    $fullpage//@foldrest,
                    ($fullpage//@vers = 'kommnetvor'),
                    ($overlayname != ''))"/>
            </xsl:if>
            <xsl:if test="'' != $appendname and $appendfmt != 'blank'">
                <xsl:copy-of select="y:buildspm(concat('SPMA_',$appendfmt,'_only'),
                    '_last',
                    $fullpageapp//@headerfirst,
                    $fullpageapp//@footonly,
                    ($fullpageapp//@pagenumbers = 'yes'),
                    ($fullpageapp//@visisig = 'kommnetvor'),
                    $fullpageapp//@foldfirst,
                    ($fullpageapp//@vers != 'no'),
                    true())"/>
                <xsl:copy-of select="y:buildspm(concat('SPMA_',$appendfmt,'_first'),
                    '_first',
                    $fullpageapp//@headerfirst,
                    $fullpageapp//@footfirst,
                    ($fullpageapp//@pagenumbers = 'yes' or $fullpageapp//@pagenumbers = 'ifmore'),
                    ($fullpageapp//@visisig = 'kommnetvor'),
                    $fullpageapp//@foldfirst,
                    ($fullpageapp//@vers = 'first'),
                    true())"/>
                <xsl:copy-of select="y:buildspm(concat('SPMA_',$appendfmt,'_last'),
                    '_last',
                    $fullpageapp//@headerrest,
                    $fullpageapp//@footlast,
                    ($fullpageapp//@pagenumbers = 'yes' or $fullpageapp//@pagenumbers = 'ifmore'),
                    ($fullpageapp//@visisig = 'kommnetvor'),
                    $fullpageapp//@foldrest,
                    ($fullpageapp//@vers = 'last'),
                    true())"/>
                <xsl:copy-of select="y:buildspm(concat('SPMA_',$appendfmt,'_rest'),
                    '_rest',
                    $fullpageapp//@headerrest,
                    $fullpageapp//@footrest,
                    ($fullpageapp//@pagenumbers = 'yes' or $fullpageapp//@pagenumbers = 'ifmore'),
                    ($fullpageapp//@visisig = 'kommtnetvor'),
                    $fullpageapp//@foldrest,
                    ($fullpageapp//@vers = 'kommnetvor'),
                    true())"/>
            </xsl:if>
            <xsl:if test="$mainstream != 'blank'">
                <fo:page-sequence-master master-name="{concat('PSM_',$mainstream)}">
                    <fo:repeatable-page-master-alternatives>
                        <fo:conditional-page-master-reference master-reference="{concat('SPM_',$mainstream,'_only')}" page-position="only"/>
                        <fo:conditional-page-master-reference master-reference="{concat('SPM_',$mainstream,'_first')}" page-position="first"/>
                        <fo:conditional-page-master-reference master-reference="{concat('SPM_',$mainstream,'_last')}" page-position="last"/>
                        <fo:conditional-page-master-reference master-reference="{concat('SPM_',$mainstream,'_rest')}" page-position="rest"/>
                    </fo:repeatable-page-master-alternatives>
                </fo:page-sequence-master>
            </xsl:if>
            <xsl:if test="'' != $appendname and $appendfmt != 'blank'">
                <fo:page-sequence-master master-name="{concat('PSMA_',$appendfmt)}">
                    <fo:repeatable-page-master-alternatives>
                        <fo:conditional-page-master-reference master-reference="{concat('SPMA_',$appendfmt,'_only')}" page-position="only"/>
                        <fo:conditional-page-master-reference master-reference="{concat('SPMA_',$appendfmt,'_first')}" page-position="first"/>
                        <fo:conditional-page-master-reference master-reference="{concat('SPMA_',$appendfmt,'_last')}" page-position="last"/>
                        <fo:conditional-page-master-reference master-reference="{concat('SPMA_',$appendfmt,'_rest')}" page-position="rest"/>
                    </fo:repeatable-page-master-alternatives>
                </fo:page-sequence-master>
            </xsl:if>
            <fo:page-sequence-master master-name="blank">
                <fo:repeatable-page-master-alternatives>
                    <fo:conditional-page-master-reference master-reference="SPM_blank" page-position="any"/>
                </fo:repeatable-page-master-alternatives>
            </fo:page-sequence-master>
        </fo:layout-master-set>
    <!-- xsl:message><xsl:value-of select="concat('ovl: ', $overlayname, '  ovlstream: ',$ovlseq, ' mainstream: ',$mainstream)"/></xsl:message -->
    <!-- WE NEED COPIES OF MASTERS BECAUSE THE BODY REGION IS FULL-PAGE FOR OVERLAY/APPEND -->
    <!-- Other regions besides body can stay same but always newly full page body region  -->
    <!-- could be shared between append and overlay -->
    </xsl:template>

    <fx:function name="y:buildspm">
        <xsl:param name="name"/>
        <xsl:param name="suffx"/>
        <xsl:param name="head"/>
        <xsl:param name="foot"/>
        <xsl:param name="pgno"/>
        <xsl:param name="vsig"/>
        <xsl:param name="fold"/>
        <xsl:param name="vers"/>
        <xsl:param name="blank" select="false()"/>
        <fx:result>
            <fo:simple-page-master master-name="{$name}" margin-right="10mm" margin-left="0mm" margin-bottom="0mm" margin-top="0mm" page-width="21cm" page-height="29.7cm">
                <xsl:if test="0 != $debug">
                <xsl:comment>
                    <xsl:text> head: </xsl:text>
                    <xsl:value-of select="$head"/>
                    <xsl:text>  foot: </xsl:text>
                    <xsl:value-of select="$foot"/>
                    <xsl:text> </xsl:text>
                    <xsl:if test="$pgno">
                        <xsl:text>  pageno yes </xsl:text>
                    </xsl:if>
                    <xsl:if test="$vsig">
                        <xsl:text>  visiblesign. yes </xsl:text>
                    </xsl:if>
                </xsl:comment>
                </xsl:if>
                <xsl:variable name="bottoms">
                    <xsl:if test="'no' != $foot">
                        <a>
                            <xsl:value-of select="y:topt($layouts/z:config/z:foot[@name=$foot]/@vextent)"/>
                        </a>
                    </xsl:if>
                    <xsl:if test="$pgno = 'yes'">
                        <a>
                            <xsl:value-of select="y:topt($layouts/z:config/z:pageno/@vextent)"/>
                        </a>
                    </xsl:if>
                </xsl:variable>
                <xsl:variable name="bottommarg" select="sum(ex:node-set($bottoms)//a)"/>
                <xsl:variable name="bottommargsig">
                    <xsl:choose>
                        <xsl:when test="$vsig and ($bottommarg &lt; y:topt($layouts/z:config/z:visiblesignature/@top))">
                            <xsl:value-of select="y:topt($layouts/z:config/z:visiblesignature/@top)"/>
                        </xsl:when>
                        <xsl:when test="$bottommarg &lt; y:topt('1cm')">
                            <xsl:value-of select="y:topt('1cm')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$bottommarg"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="topmarg">
                    <xsl:choose>
                        <xsl:when test="'no' != $head">
                            <xsl:value-of select="$layouts/z:config/z:head[@name=$head]/@vextent"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="y:topt('1cm')"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:choose>
                <!--xsl:when test="'' != $overlayname and $mainstream != 'blank'" -->
                    <xsl:when test="$blank">
                    <!-- for overlay body full page -->
                        <fo:region-body margin-left="0mm" margin-top="0mm" margin-bottom="0mm" margin-right="0mm"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <fo:region-body margin-left="25mm" margin-top="{$topmarg}" margin-bottom="{concat($bottommargsig,'pt')}" margin-right="10mm"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="0 != $topmarg">
                    <fo:region-before extent="{$layouts/z:config/z:head[@name=$head]/@vextent}" region-name="{concat('BEF_',$head)}"/>
                </xsl:if>
                <xsl:choose>
                    <xsl:when test="0 != $bottommarg and $pgno">
                        <fo:region-after extent="{concat($bottommarg,'pt')}" region-name="{concat('AFT_',$foot,'_E_PG')}"/>
                    </xsl:when>
                    <xsl:when test="0 != $bottommarg">
                        <fo:region-after extent="{concat($bottommarg,'pt')}" region-name="{concat('AFT_',$foot,'_E')}"/>
                    </xsl:when>
                    <xsl:when test="$pgno">
                        <fo:region-after extent="{concat($bottommarg,'pt')}" region-name="{'AFT__E'}"/>
                    </xsl:when>
                </xsl:choose>
                <xsl:choose>
                    <xsl:when test="'A' = translate(translate($fold,'B','A'),'C','A') and ($vers = 'first' or $vers = 'last')">
                        <fo:region-start extent="1mm" region-name="{concat('foldleft',$fold,'_vers')}"/>
                    </xsl:when>
                    <xsl:when test="$vers = 'first' or $vers = 'last'">
                        <fo:region-start extent="1mm" region-name="left_vers"/>
                    </xsl:when>
                    <xsl:when test="'A' = translate(translate($fold,'B','A'),'C','A')">
                        <fo:region-start extent="1mm" region-name="{concat('foldleft',$fold)}"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <fo:region-start extent="1mm" region-name="empty"/>
                    </xsl:otherwise>
                </xsl:choose>
            <!--fo:region-start extent="1mm" region-name="{concat('STA_',$mainstream,'_only')}"/ -->
            </fo:simple-page-master>
        </fx:result>
    </fx:function>

    <xsl:template match="y:generate-static-contents">
        <xsl:param name="brief"/>
        <xsl:variable name="fullpage0">
            <xsl:apply-templates select="$layouts/z:config/z:layouts/z:layout[@name=$mainstream]" mode="normalizer">
                <xsl:with-param name="refdoc" select="$brief"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="fullpage" select="ex:node-set($fullpage0)"/>
        <xsl:variable name="fullpageapp0">
            <xsl:if test="'' != $appendname and $appendfmt != 'blank'">
                <xsl:apply-templates select="$layouts/z:config/z:layouts/z:layout[@name=$mainstream]" mode="normalizer">
                    <xsl:with-param name="refdoc" select="$brief//y:append"/>
                </xsl:apply-templates>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="fullpageapp" select="ex:node-set($fullpageapp0)"/>

        <xsl:variable name="neededtop0">
            <xsl:if test="'no' != $fullpage//@headerfirst">
                <a n="{$fullpage//@headerfirst}"/>
            </xsl:if>
            <xsl:if test="'no' != $fullpage//@headerrest">
                <a n="{$fullpage//@headerrest}"/>
            </xsl:if>
            <xsl:if test="'' != $fullpageapp//@headerfirst and 'no' != $fullpageapp//@headerfirst">
                <a n="{$fullpageapp//@headerfirst}"/>
            </xsl:if>
            <xsl:if test="'' != $fullpageapp//@headerrest and 'no' != $fullpageapp//@headerrest">
                <a n="{$fullpageapp//@headerrest}"/>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="neededtop" select="ex:node-set($neededtop0)"/>

        <xsl:for-each select="$neededtop/a[@n != 'no' and '' != @n]">
            <xsl:if test="not(following::a[@n = current()/@n])">
                <xsl:variable name="n" select="@n"/>
                <fo:static-content flow-name="{concat('BEF_',$n)}">
                    <xsl:apply-templates select="$layouts/z:config/z:head[@name=$n]/*">
                        <xsl:with-param name="brief" select="$brief"/>
                    </xsl:apply-templates>
                </fo:static-content>
            </xsl:if>
        </xsl:for-each>

        <xsl:variable name="neededbottom0">
            <!-- only -->
            <a n="{y:buildaftname($fullpage//@footonly,($fullpage//@pagenumbers = 'yes'))}"/>
            <!-- first -->
            <a n="{y:buildaftname($fullpage//@footfirst,($fullpage//@pagenumbers = 'yes' or $fullpage//@pagenumbers = 'ifmore'))}"/>
            <!-- last -->
            <a n="{y:buildaftname($fullpage//@footlast,($fullpage//@pagenumbers = 'yes' or $fullpage//@pagenumbers = 'ifmore'))}"/>
            <!-- rest -->
            <a n="{y:buildaftname($fullpage//@footrest,($fullpage//@pagenumbers = 'yes' or $fullpage//@pagenumbers = 'ifmore'))}"/>
            <!-- same again -->
            <a n="{y:buildaftname($fullpageapp//@footonly,($fullpageapp//@pagenumbers = 'yes'))}"/>
            <a n="{y:buildaftname($fullpageapp//@footfirst,($fullpageapp//@pagenumbers = 'yes' or $fullpageapp//@pagenumbers = 'ifmore'))}"/>
            <a n="{y:buildaftname($fullpageapp//@footlast,($fullpageapp//@pagenumbers = 'yes' or $fullpageapp//@pagenumbers = 'ifmore'))}"/>
            <a n="{y:buildaftname($fullpageapp//@footrest,($fullpageapp//@pagenumbers = 'yes' or $fullpageapp//@pagenumbers = 'ifmore'))}"/>
        </xsl:variable>
        <xsl:variable name="neededbottom" select="ex:node-set($neededbottom0)"/>

        <xsl:for-each select="$neededbottom/a[@n != 'no' and '' != @n]">
            <xsl:if test="not(following::a[@n = current()/@n])">
                <fo:static-content flow-name="{@n}">
                    <!--xx><xsl:value-of select="@n"/></xx><aa><xsl:value-of select="substring(@n,5,string-length(@n) - 9)"/></aa><bb><xsl:value-of select="substring(@n,5,string-length(@n) - 6)"/></bb -->
                    <xsl:variable name="f">
                        <xsl:choose>
                            <xsl:when test="y:ends-with(@n,'_E_PG')">
                                <xsl:value-of select="substring(@n,5,string-length(@n) - 9)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="substring(@n,5,string-length(@n) - 6)"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="y:ends-with(@n,'_E_PG')">
                            <xsl:apply-templates select="$layouts/z:config/z:pageno/*">
                                <xsl:with-param name="brief" select="$brief"/>
                            </xsl:apply-templates>
                            <xsl:if test="'' != $f">
                                <fo:block-container position="absolute" top="{$layouts/z:config/z:pageno/@vextent}" height="{$layouts/z:config/z:foot[@name=$f]/@vextent}" width="18.5cm">
                                    <xsl:apply-templates select="$layouts/z:config/z:foot[@name=$f]/*">
                                        <xsl:with-param name="brief" select="$brief"/>
                                    </xsl:apply-templates>
                                </fo:block-container>
                            </xsl:if>
                        </xsl:when>
                        <xsl:when test="'' != $f">
                            <xsl:apply-templates select="$layouts/z:config/z:foot[@name=$f]/*">
                                <xsl:with-param name="brief" select="$brief"/>
                            </xsl:apply-templates>
                        </xsl:when>
                    </xsl:choose>
                </fo:static-content>
            </xsl:if>
        </xsl:for-each>

        <xsl:variable name="neededleft0">
            <xsl:choose>
                <xsl:when test="'A' = translate(translate($fullpage//@foldfirst,'B','A'),'C','A') and ($fullpage//@vers = 'first' or $fullpage//@vers = 'last')">
                    <a n="{concat('foldleft',$fullpage//@foldfirst,'_vers')}"/>
                </xsl:when>
                <xsl:when test="$fullpage//@vers = 'first' or $fullpage//@vers = 'last'">
                    <fo:region-start extent="1mm" region-name="left_vers"/>
                </xsl:when>
                <xsl:when test="'A' = translate(translate($fullpage//@foldfirst,'B','A'),'C','A')">
                    <a n="{concat('foldleft',$fullpage//@foldfirst)}"/>
                </xsl:when>
                <xsl:otherwise>
                    <a n="empty"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="'A' = translate(translate($fullpage//@foldfirst,'B','A'),'C','A') and ($fullpage//@vers = 'first')">
                    <a n="{concat('foldleft',$fullpage//@foldfirst,'_vers')}"/>
                </xsl:when>
                <xsl:when test="$fullpage//@vers = 'first'">
                    <fo:region-start extent="1mm" region-name="left_vers"/>
                </xsl:when>
                <xsl:when test="'A' = translate(translate($fullpage//@foldfirst,'B','A'),'C','A')">
                    <a n="{concat('foldleft',$fullpage//@foldfirst)}"/>
                </xsl:when>
                <xsl:otherwise>
                    <a n="empty"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="'A' = translate(translate($fullpage//@foldrest,'B','A'),'C','A') and ($fullpage//@vers = 'last')">
                    <a n="{concat('foldleft',$fullpage//@foldrest,'_vers')}"/>
                </xsl:when>
                <xsl:when test="$fullpage//@vers = 'last'">
                    <fo:region-start extent="1mm" region-name="left_vers"/>
                </xsl:when>
                <xsl:when test="'A' = translate(translate($fullpage//@foldrest,'B','A'),'C','A')">
                    <a n="{concat('foldleft',$fullpage//@foldrest)}"/>
                </xsl:when>
                <xsl:otherwise>
                    <a n="empty"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="'A' = translate(translate($fullpage//@foldrest,'B','A'),'C','A')">
                    <a n="{concat('foldleft',$fullpage//@foldrest)}"/>
                </xsl:when>
                <xsl:otherwise>
                    <a n="empty"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="'A' = translate(translate($fullpageapp//@foldfirst,'B','A'),'C','A') and ($fullpageapp//@vers = 'first' or $fullpageapp//@vers = 'last')">
                    <a n="{concat('foldleft',$fullpageapp//@foldfirst,'_vers')}"/>
                </xsl:when>
                <xsl:when test="$fullpageapp//@vers = 'first' or $fullpageapp//@vers = 'last'">
                    <fo:region-start extent="1mm" region-name="left_vers"/>
                </xsl:when>
                <xsl:when test="'A' = translate(translate($fullpageapp//@foldfirst,'B','A'),'C','A')">
                    <a n="{concat('foldleft',$fullpageapp//@foldfirst)}"/>
                </xsl:when>
                <xsl:otherwise>
                    <a n="empty"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="'A' = translate(translate($fullpageapp//@foldfirst,'B','A'),'C','A') and ($fullpageapp//@vers = 'first')">
                    <a n="{concat('foldleft',$fullpageapp//@foldfirst,'_vers')}"/>
                </xsl:when>
                <xsl:when test="$fullpageapp//@vers = 'first'">
                    <fo:region-start extent="1mm" region-name="left_vers"/>
                </xsl:when>
                <xsl:when test="'A' = translate(translate($fullpageapp//@foldfirst,'B','A'),'C','A')">
                    <a n="{concat('foldleft',$fullpageapp//@foldfirst)}"/>
                </xsl:when>
                <xsl:otherwise>
                    <a n="empty"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="'A' = translate(translate($fullpageapp//@foldrest,'B','A'),'C','A') and ($fullpageapp//@vers = 'last')">
                    <a n="{concat('foldleft',$fullpageapp//@foldrest,'_vers')}"/>
                </xsl:when>
                <xsl:when test="$fullpageapp//@vers = 'last'">
                    <fo:region-start extent="1mm" region-name="left_vers"/>
                </xsl:when>
                <xsl:when test="'A' = translate(translate($fullpageapp//@foldrest,'B','A'),'C','A')">
                    <a n="{concat('foldleft',$fullpageapp//@foldrest)}"/>
                </xsl:when>
                <xsl:otherwise>
                    <a n="empty"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="'A' = translate(translate($fullpageapp//@foldrest,'B','A'),'C','A')">
                    <a n="{concat('foldleft',$fullpageapp//@foldrest)}"/>
                </xsl:when>
                <xsl:otherwise>
                    <a n="empty"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="neededleft" select="ex:node-set($neededleft0)"/>
            <!--xsl:copy-of select="$neededleft"/-->
        <xsl:for-each select="$neededleft/a">
            <xsl:if test="not(following::a[@n = current()/@n]) and @n != 'empty'">
                    <!--xsl:value-of select="@n"/ -->
                <fo:static-content flow-name="{@n}">
                    <xsl:if test="starts-with(@n,'foldleftA')">
                        <fo:block-container position="absolute" top="8.7cm" left="5mm" height="6.15cm" width="2mm" border-color="black" border-style="solid" border-top-width="0.1pt" border-bottom-width="0.1pt" border-left-width="0pt" border-right-width="0pt">
                            <fo:block/>
                        </fo:block-container>
                        <fo:block-container position="absolute" top="14.85cm" left="5mm" height="4.35cm" width="2mm" border-bottom-color="black" border-bottom-style="solid" border-top-width="0pt" border-bottom-width="0.1pt" border-left-width="0pt" border-right-width="0pt">
                            <fo:block/>
                        </fo:block-container>
                    </xsl:if>
                    <xsl:if test="starts-with(@n,'foldleftB')">
                        <fo:block-container position="absolute" top="10.5cm" left="5mm" height="4.35cm" width="2mm" border-color="black" border-style="solid" border-top-width="0.1pt" border-bottom-width="0.1pt" border-left-width="0pt" border-right-width="0pt">
                            <fo:block/>
                        </fo:block-container>
                        <fo:block-container position="absolute" top="14.85cm" left="5mm" height="6.15cm" width="2mm" border-bottom-color="black" border-bottom-style="solid" border-top-width="0pt" border-bottom-width="0.1pt" border-left-width="0pt" border-right-width="0pt">
                            <fo:block/>
                        </fo:block-container>
                    </xsl:if>
                    <xsl:if test="starts-with(@n,'foldleftC')">
                        <fo:block-container position="absolute" top="9.6cm" left="5mm" height="5.25cm" width="2mm" border-color="black" border-style="solid" border-top-width="0.1pt" border-bottom-width="0.1pt" border-left-width="0pt" border-right-width="0pt">
                            <fo:block/>
                        </fo:block-container>
                        <fo:block-container position="absolute" top="14.85cm" left="5mm" height="5.25cm" width="2mm" border-bottom-color="black" border-bottom-style="solid" border-top-width="0pt" border-bottom-width="0.1pt" border-left-width="0pt" border-right-width="0pt">
                            <fo:block/>
                        </fo:block-container>
                    </xsl:if>
                    <xsl:if test="y:ends-with(@n,'_vers')">
                        <fo:block-container position="absolute" top="24cm" width="3.9cm" text-align="start" left="7mm" reference-orientation="90">
                            <xsl:choose>
                                <xsl:when test="$layouts/z:config/z:version">
                                    <xsl:apply-templates select="$layouts/z:config/z:version/*"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:apply-templates select="ex:node-set($versionpattern)/*"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </fo:block-container>
                    </xsl:if>
                </fo:static-content>
            </xsl:if>
        </xsl:for-each>
        
    <!-- xsl:message><xsl:value-of select="concat('ovl: ', $overlayname, '  ovlstream: ',$ovlseq, ' mainstream: ',$mainstream)"/></xsl:message -->
    <!-- WE NEED COPIES OF MASTERS BECAUSE THE BODY REGION IS FULL-PAGE FOR OVERLAY/APPEND -->
    <!-- Other regions besides body can stay same but always newly full page body region  -->
    <!-- could be shared between append and overlay -->
    </xsl:template>

    <fx:function name="y:buildaftname">
        <xsl:param name="foot"/>
        <xsl:param name="pgno"/>
        <xsl:choose>
            <xsl:when test="'no' != $foot and '' != $foot and $pgno">
                <fx:result select="concat('AFT_',$foot,'_E_PG')"/>
            </xsl:when>
            <xsl:when test="'no' != $foot and '' != $foot">
                <fx:result select="concat('AFT_',$foot,'_E')"/>
            </xsl:when>
            <xsl:when test="$pgno">
                <fx:result select="'AFT__E_PG'"/>
            </xsl:when>
            <xsl:otherwise>
                <fx:result select="''"/>
            </xsl:otherwise>
        </xsl:choose>
    </fx:function>

    <xsl:template match="fo:page-sequence">
        <xsl:param name="brief"/>
        <xsl:param name="rechinfo"/>
        <xsl:param name="master"/>
        <!-- check / message -->
        <xsl:if test="'.pdf' = translate(substring($overlayname,string-length($overlayname) - 3),'PDF','pdf') and string($pdfprofile) != ''">
            <xsl:message>
                <xsl:text>**** Attention, pdf Overlay may not work conforming PDF/A ****</xsl:text>
            </xsl:message>
        </xsl:if>
        <xsl:if test="'.pdf' = translate(substring($appendname,string-length($appendname) - 3),'PDF','pdf') and string($pdfprofile) != ''">
            <xsl:message>
                <xsl:text>**** Attention, pdf Append may not work conforming PDF/A ****</xsl:text>
            </xsl:message>
        </xsl:if>
        <!-- do something -->
        <xsl:choose>
            <xsl:when test="string($overlayname) != ''">
                <!-- there should be no content right in that content stream -->
                <xsl:copy>
                    <xsl:copy-of select="@*[not(starts-with(name(),'master-reference'))]"/>
                    <xsl:attribute name="master-reference">
                        <xsl:choose>
                            <xsl:when test="'blank' != $mainstream">
                                <xsl:value-of select="concat('PSM_',$mainstream)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>blank</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                    <xsl:apply-templates select="y:ref  | y:generate-static-contents">
                        <xsl:with-param name="master" select="$master"/>
                        <xsl:with-param name="brief" select="$brief"/>
                        <xsl:with-param name="rechinfo" select="$rechinfo"/>
                    </xsl:apply-templates>
                    <fo:flow flow-name="xsl-region-body">
                        <xsl:call-template name="buildovlpg">
                            <xsl:with-param name="bgovl" select="$overlayname"/>
                            <xsl:with-param name="ovlpages" select="$overlaypages"/>
                            <xsl:with-param name="page" select="1"/>
                            <xsl:with-param name="alttext" select="$overlayalttext"/>
                            <xsl:with-param name="rotate" select="$overlayrotate"/>
                        </xsl:call-template>
                        <xsl:if test="'' = $appendname and 1 = $uselastpg">
                            <fo:block space-before="-7pt" line-height="1pt" white-space-collapse="true" margin-bottom="0mm" font-weight="normal" font-size="1pt" page-break-before="avoid" id="lastpg"/>
                        </xsl:if>
                    </fo:flow>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@*[not(starts-with(name(),'master-reference'))]"/>
                    <xsl:attribute name="master-reference">
                        <xsl:choose>
                            <xsl:when test="'blank' != $mainstream">
                                <xsl:value-of select="concat('PSM_',$mainstream)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>blank</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                    <xsl:attribute name="language">
                        <xsl:value-of select="$sprachint"/>
                    </xsl:attribute>
                    <xsl:apply-templates select="*">
                        <xsl:with-param name="master" select="$master"/>
                        <xsl:with-param name="brief" select="$brief"/>
                        <xsl:with-param name="rechinfo" select="$rechinfo"/>
                    </xsl:apply-templates>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
        <!-- then there might be append -->
        <xsl:if test="'' != $appendname">
            <xsl:copy>
                <xsl:copy-of select="@*[name() != 'master-reference']"/>
                <xsl:attribute name="master-reference">
                    <xsl:choose>
                        <xsl:when test="'blank' != $appendfmt">
                            <xsl:value-of select="concat('PSMA_',$appendfmt)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>blank</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
                <xsl:apply-templates select="y:ref">
                    <xsl:with-param name="master" select="$master"/>
                    <xsl:with-param name="brief" select="$brief"/>
                    <xsl:with-param name="rechinfo" select="$rechinfo"/>
                </xsl:apply-templates>
                <fo:flow flow-name="xsl-region-body">
                    <xsl:call-template name="buildovlpg">
                        <xsl:with-param name="bgovl" select="$appendname"/>
                        <xsl:with-param name="ovlpages" select="$appendpages"/>
                        <xsl:with-param name="page" select="1"/>
                        <xsl:with-param name="alttext" select="$appendalttext"/>
                        <xsl:with-param name="rotate" select="$appendrotate"/>
                    </xsl:call-template>
                    <fo:block space-before="-7pt" line-height="1pt" white-space-collapse="true" margin-bottom="0mm" font-weight="normal" font-size="1pt" page-break-before="avoid" id="lastpg"/>
                </fo:flow>
            </xsl:copy>
        </xsl:if>
    </xsl:template>

    <xsl:template match="fo:block[@id='lastpg']">
        <!-- lastpg always set inside the page-sequence -->
        <xsl:if test="concat(string($overlayname),string($appendname)) = '' and 1 = $uselastpg">
            <xsl:copy-of select="."/>
        </xsl:if>
    </xsl:template>

    <xsl:template name="buildovlpg">
        <xsl:param name="bgovl"/>
        <xsl:param name="ovlpages" select="0"/>
        <xsl:param name="page" select="1"/>
        <xsl:param name="alttext" select="''"/>
        <xsl:param name="rotate" select="0"/>
        <!-- xsl:message><xsl:value-of select="concat('buildovlg bg: ',$bgovl,' pages: ',$ovlpages,' page: ',$page)"/></xsl:message -->
        <xsl:if test="$page &lt;= $ovlpages">
            <xsl:variable name="bcw">
                <xsl:choose>
                    <xsl:when test="0 = $rotate or 180 = $rotate">20.9cm</xsl:when>
                    <xsl:otherwise>29.7cm</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="bch">
                <xsl:choose>
                    <xsl:when test="0 != $rotate and 180 != $rotate">20.9cm</xsl:when>
                    <xsl:otherwise>29.7cm</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="xgw">
                <xsl:choose>
                    <xsl:when test="0 = $rotate or 180 = $rotate">21cm</xsl:when>
                    <xsl:otherwise>29.7cm</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="xgh">
                <xsl:choose>
                    <xsl:when test="0 != $rotate and 180 != $rotate">21cm</xsl:when>
                    <xsl:otherwise>29.7cm</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <fo:block-container position="absolute" left="0mm" top="0mm" width="{$bcw}" height="{$bch}">
                <xsl:if test="0 != $rotate">
                    <xsl:attribute name="reference-orientation">
                        <xsl:value-of select="$rotate"/>
                    </xsl:attribute>
                </xsl:if>
                <fo:block>
                    <fo:external-graphic width="{$xgw}" height="{$xgh}" content-width="{$xgw}" content-height="{$xgh}">
                        <xsl:attribute name="src">
                            <xsl:choose>
                                <xsl:when test="$ovlpages != 1">
                                    <xsl:value-of select="concat($bgovl,'#page=',$page)"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$bgovl"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                        <xsl:if test="'' != $alttext">
                            <xsl:attribute name="fox:alt-text">
                                <xsl:value-of select="$alttext"/>
                            </xsl:attribute>
                        </xsl:if>
                    </fo:external-graphic>
                </fo:block>
            </fo:block-container>
            <fo:block-container>
                <fo:block font-size="0.1pt">
                    <xsl:if test="$ovlpages &gt; $page">
                        <xsl:attribute name="page-break-after">always</xsl:attribute>
                        <xsl:attribute name="break-after">page</xsl:attribute>
                    </xsl:if>
                    <xsl:text>&#xa0;</xsl:text>
                </fo:block>
            </fo:block-container>
            <xsl:call-template name="buildovlpg">
                <xsl:with-param name="bgovl" select="$bgovl"/>
                <xsl:with-param name="ovlpages" select="$ovlpages"/>
                <xsl:with-param name="alttext" select="$alttext"/>
                <xsl:with-param name="page" select="$page + 1"/>
                <xsl:with-param name="rotate" select="$rotate"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

<!--                         -->
<!--  T E X T  T R A N S L A -->
<!--                         -->
    <fx:function name="y:xlate">
        <xsl:param name="srch"/>
        <xsl:variable name="xltext" select="y:xlateint($srch)"/>
        <fx:result>
            <xsl:choose>
                <xsl:when test="$markxlate = 1">
                    <xsl:choose>
                        <xsl:when test="$xltext = $xlnotfound">
                            <fo:inline background-color="#ff0000">
                                <xsl:value-of select="$xltext"/>
                            </fo:inline>
                        </xsl:when>
                        <xsl:otherwise>
                            <fo:inline background-color="#77ffbb">
                                <xsl:value-of select="$xltext"/>
                            </fo:inline>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="$xltext = $xlnotfound">
                            <fo:inline background-color="#ff0000">
                                <xsl:value-of select="$xltext"/>
                            </fo:inline>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$xltext"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
        </fx:result>
    </fx:function>

    <fx:function name="y:xlateint">
        <xsl:param name="srch"/>
        <fx:result>
            <xsl:choose>
                <xsl:when test="$layouts//y:for/y:xlate[@lang = $sprachint and @k = $srch]/@is">
                    <xsl:value-of select="$layouts//y:for/y:xlate[@lang = $sprachint and @k = $srch]/@is"/>
                </xsl:when>
                <xsl:when test="$layouts//y:for/y:xlate[@k = $srch]/*[local-name() = $sprachint]/@is">
                    <xsl:value-of select="$layouts//y:for/y:xlate[@k = $srch]/*[local-name() = $sprachint]/@is"/>
                </xsl:when>
                <xsl:when test="$layouts//y:for/*[@lang = $sprachint and local-name() = $srch]/@is">
                    <xsl:value-of select="$layouts//y:for/*[@lang = $sprachint and local-name() = $srch]/@is"/>
                </xsl:when>
                <xsl:when test="$layouts//y:for/*[local-name() = $srch]/*[local-name() = $sprachint]/@is">
                    <xsl:value-of select="$layouts//y:for/*[local-name() = $srch]/*[local-name() = $sprachint]/@is"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>
                        <xsl:value-of select="concat('**** OOOps, no translation for :',$srch,',: found for lang :',$sprachint,':&#xa;')"/>
                    </xsl:message>
                    <fo:inline background-color="#ff0000">
                        <xsl:value-of select="$xlnotfound"/>
                    </fo:inline>
                </xsl:otherwise>
            </xsl:choose>
        </fx:result>
    </fx:function>

    <xsl:template match="y:xlate">
        <xsl:copy-of select="y:xlate(@k)"/>
    </xsl:template>

    <xsl:template match="y:testlangeq">
        <xsl:param name="master" select="''"/>
        <xsl:param name="rechinfo" select="''"/>
        <xsl:param name="brief" select="''"/>
        <xsl:if test="@k = $sprachint">
            <xsl:apply-templates>
                <xsl:with-param name="rechinfo" select="$rechinfo"/>
                <xsl:with-param name="master" select="$master"/>
                <xsl:with-param name="brief" select="$brief"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

    <fx:function name="y:basename">
        <xsl:param name="name" select="''"/>
        <xsl:choose>
            <xsl:when test="contains($name,'/')">
                <fx:result select="y:basename(substring-after($name,'/'))"/>
            </xsl:when>
            <xsl:otherwise>
                <fx:result select="$name"/>
            </xsl:otherwise>
        </xsl:choose>
    </fx:function>

<!--                         -->
<!-- N E W  L A Y O U T      -->
<!--                         -->
    <xsl:template match="z:layout" mode="normalizer">
        <xsl:param name="refdoc"/>
        <!-- xsl:message><xsl:value-of select="@name"/></xsl:message -->
        <xsl:copy>
        <!--xsl:copy-of select="@*"/-->
            <xsl:choose>
                <xsl:when test="ex:node-set($refdoc)//@pagenumbers and '' != ex:node-set($refdoc)//@pagenumbers">
                <!-- pagenumbers passed in briefetc. -->
                    <xsl:attribute name="pagenumbers">
                        <xsl:value-of select="ex:node-set($refdoc)//@pagenumbers"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:when test="not(Ωpagenumbers) or '' = @pagenumbers">
                <!-- no pagenumbers, default ifmore -->
                <!-- xsl:message>pagenumbers</xsl:message -->
                    <xsl:attribute name="pagenumbers">
                        <xsl:text>ifmore</xsl:text>
                    </xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                <!-- copy given -->
                    <xsl:copy-of select="@pagenumbers"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="ex:node-set($refdoc)//@footlast and '' != ex:node-set($refdoc)//@footlast">
                <!-- footlast overridden in briefetc. -->
                    <xsl:attribute name="footlast">
                        <xsl:value-of select="ex:node-set($refdoc)//@footlast"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:when test="not(@footlast) or '' = @footlast">
                <!-- no footlast, default no -->
                <!-- xsl:message>footlast</xsl:message -->
                    <xsl:attribute name="footlast">
                        <xsl:text>no</xsl:text>
                    </xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                <!-- copy given -->
                    <xsl:copy-of select="@footlast"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="ex:node-set($refdoc)//@footrest and '' != ex:node-set($refdoc)//@footrest">
                <!-- footrest overriden in briefetc. -->
                    <xsl:attribute name="footrest">
                        <xsl:value-of select="ex:node-set($refdoc)//@footrest"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:when test="not(@footlast) or '' = @footrest">
                <!-- no footrest, default no -->
                <!-- xsl:message>footrest</xsl:message -->
                    <xsl:attribute name="footrest">
                        <xsl:text>no</xsl:text>
                    </xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                <!-- copy given -->
                    <xsl:copy-of select="@footrest"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="ex:node-set($refdoc)//@footfirst and '' != ex:node-set($refdoc)//@footfirst">
                <!-- footfirst overridden in briefetc -->
                    <xsl:attribute name="footfirst">
                        <xsl:value-of select="ex:node-set($refdoc)//@footfirst"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                <!-- copy given, NO DEFAULT -->
                    <xsl:copy-of select="@footfirst"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="ex:node-set($refdoc)//@headerfirst and '' != ex:node-set($refdoc)//@headerfirst">
                <!-- headerfirst overridden in briefetc -->
                    <xsl:attribute name="headerfirst">
                        <xsl:value-of select="ex:node-set($refdoc)//@headerfirst"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                <!-- copy given, NO DEFAULT -->
                    <xsl:copy-of select="@headerfirst"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="ex:node-set($refdoc)//@headerrest and '' != ex:node-set($refdoc)//@headerrest">
                <!-- headerrest overridden in briefetc -->
                    <xsl:attribute name="headerrest">
                        <xsl:value-of select="ex:node-set($refdoc)//@headerrest"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                <!-- copy given, NO DEFAULT -->
                    <xsl:copy-of select="@headerrest"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="ex:node-set($refdoc)//@footonly and '' != ex:node-set($refdoc)//@footonly">
                <!-- footonly overridden in briefetc. -->
                    <xsl:attribute name="footonly">
                        <xsl:value-of select="ex:node-set($refdoc)//@footonly"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:when test="(not(@footonly) or '' = @footonly) and ex:node-set($refdoc)//@footfirst and '' != ex:node-set($refdoc)//@footfirst">
                <!-- no footonly, but given in briefetc -->
                <!-- xsl:message>footonly</xsl:message -->
                    <xsl:attribute name="footonly">
                        <xsl:value-of select="ex:node-set($refdoc)//@footfirst"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:when test="not(@footonly) or '' = @footonly">
                <!-- no footonly, use footfirst -->
                <!-- xsl:message>footonly</xsl:message -->
                    <xsl:attribute name="footonly">
                        <xsl:value-of select="@footfirst"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                <!-- copy given -->
                    <xsl:copy-of select="@footonly"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="ex:node-set($refdoc)//@visisig and '' != ex:node-set($refdoc)//@visisig">
                <!-- visisig overridden in briefetc. -->
                    <xsl:attribute name="visisig">
                        <xsl:value-of select="ex:node-set($refdoc)//@visisig"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:when test="not(@visisig) or '' = @visisig">
                <!-- no visisig, default no -->
                <!-- xsl:message>visisig</xsl:message -->
                    <xsl:attribute name="visisig">
                        <xsl:text>no</xsl:text>
                    </xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                <!-- copy given -->
                    <xsl:copy-of select="@visisig"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="(not(@foldfirst) or '' = @foldfirst) and ex:node-set($refdoc)//@headerfirst and '' != ex:node-set($refdoc)//@headerfirst and $layouts/z:config/z:head[@name = current()/@headerfirst]/@form and 'A' = translate(translate($layouts/z:config/z:head[@name = ex:node-set($refdoc)//@headerfirst]/@form,'B','A'),'C','A')">
                <!-- foldfirst not given but headerfirst overridden in briefetc. -->
                <!-- xsl:message>foldrest 1</xsl:message -->
                    <xsl:attribute name="foldfirst">
                        <xsl:value-of select="$layouts/z:config/z:head[@name = ex:node-set($refdoc)//@headerfirst]/@form"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:when test="(not(@foldfirst) or '' = @foldfirst) and $layouts/z:config/z:head[@name = current()/@headerfirst]/@form and 'A' = translate(translate($layouts/z:config/z:head[@name = current()/@headerfirst]/@form,'B','A'),'C','A')">
                <!-- xsl:message>foldfirst</xsl:message -->
                    <xsl:attribute name="foldfirst">
                        <xsl:value-of select="$layouts/z:config/z:head[@name = current()/@headerfirst]/@form"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:when test="(not(@foldfirst) or '' = @foldfirst)">
                <!-- xsl:message>foldfirst</xsl:message -->
                    <xsl:attribute name="foldfirst">no</xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="@foldfirst"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="(not(@foldrest) or '' = @foldrest) and (not(@foldfirst) or '' = @foldfirst) and ex:node-set($refdoc)//@headerfirst and '' != ex:node-set($refdoc)//@headerfirst and $layouts/z:config/z:head[@name = current()/@headerfirst]/@form and 'A' = translate(translate($layouts/z:config/z:head[@name = ex:node-set($refdoc)//@headerfirst]/@form,'B','A'),'C','A')">
                <!-- xsl:message>foldrest 1</xsl:message -->
                    <xsl:attribute name="foldrest">
                        <xsl:value-of select="$layouts/z:config/z:head[@name = ex:node-set($refdoc)//@headerfirst]/@form"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:when test="(not(@foldrest) or '' = @foldrest) and (not(@foldfirst) or '' = @foldfirst) and $layouts/z:config/z:head[@name = current()/@headerfirst]/@form and 'A' = translate(translate($layouts/z:config/z:head[@name = current()/@headerfirst]/@form,'B','A'),'C','A')">
                <!-- xsl:message>foldrest 1</xsl:message -->
                    <xsl:attribute name="foldrest">
                        <xsl:value-of select="$layouts/z:config/z:head[@name = current()/@headerfirst]/@form"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:when test="(not(@foldrest) or '' = @foldrest) and (not(@foldfirst) or '' = @foldfirst)">
                <!-- xsl:message>foldrest 1</xsl:message -->
                    <xsl:attribute name="foldrest">no</xsl:attribute>
                </xsl:when>
                <xsl:when test="not(@foldrest) or (not(@foldfirst) or '' = @foldrest)">
                <!-- xsl:message>foldrest 2</xsl:message -->
                    <xsl:attribute name="foldrest">
                        <xsl:value-of select="@foldfirst"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="@foldrest"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="not(@vers) or '' = @vers">
            <!-- xsl:message>vers</xsl:message -->
                <xsl:attribute name="vers">
                    <xsl:text>first</xsl:text>
                </xsl:attribute>
            </xsl:if>
        </xsl:copy>
    </xsl:template>

    <fx:function name="y:topt">
        <xsl:param name="v"/>
        <xsl:choose>
            <xsl:when test="y:ends-with($v,'mm')">
                <fx:result select="2.834 * number(substring-before($v,'mm'))"/>
            </xsl:when>
            <xsl:when test="y:ends-with($v,'cm')">
                <fx:result select="28.34 * number(substring-before($v,'cm'))"/>
            </xsl:when>
            <xsl:when test="y:ends-with($v,'pt')">
                <fx:result select="substring-before($v,'pt')"/>
            </xsl:when>
            <xsl:when test="y:ends-with($v,'in')">
                <fx:result select="72 * number(substring-before($v,'in'))"/>
            </xsl:when>
            <xsl:when test="y:ends-with($v,'px')">
            <!-- assume 72dpi -->
                <fx:result select="substring-before($v,'px')"/>
            </xsl:when>
            <xsl:when test="'' = substring-after($v,'0')">
                <fx:result select="0"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>*** Number without unit <xsl:value-of select="$v"/>
                </xsl:message>
                <fx:result select="$v"/>
            </xsl:otherwise>
        </xsl:choose>
    </fx:function>

    <fx:function name="y:ends-with">
        <xsl:param name="s"/>
        <xsl:param name="end"/>
        <fx:result select="substring($s,string-length($s) - (string-length($end)-1)) = $end"/>
    </fx:function>


</xsl:transform>

