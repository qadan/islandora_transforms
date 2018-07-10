<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:string="xalan://java.lang.String"
  xmlns:encoder="xalan://java.net.URLEncoder">

  <xsl:template name="perform_ri_query">
    <xsl:param name="PID"/>
    <xsl:param name="risearch">http://localhost:8080/fedora/risearch</xsl:param>
    <xsl:param name="query"/>
    <xsl:param name="lang">sparql</xsl:param>
    <xsl:param name="additional_params"/>

    <xsl:variable name="encoded_query" select="encoder:encode(normalize-space(string:replaceAll($query, '%PID%', $PID)))"/>
    <xsl:variable name="query_url" select="concat($risearch, '?query=', $encoded_query, '&amp;lang=', $lang, $additional_params)"/>

    <xsl:copy-of select="document($query_url)"/>
  </xsl:template>

  <xsl:template name="get-parent-models">
    <xsl:call-template name="perform_ri_query">
       <xsl:with-param name="PID" select="$PID"/>
       <xsl:with-param name="query">
         SELECT ?model FROM &lt;#ri&gt; WHERE {
           {
             &lt;info:fedora/%PID%&gt; &lt;fedora-rels-ext:isMemberOf&gt; ?parent
           }
           UNION {
             &lt;info:fedora/%PID%&gt; &lt;fedora-rels-ext:isMemberOfCollection&gt; ?parent
           }
           ?parent &lt;fedora-model:hasModel&gt; ?model
         }
       </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
</xsl:stylesheet>
