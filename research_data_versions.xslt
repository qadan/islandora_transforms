<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:foxml="info:fedora/fedora-system:def/foxml#"
  xmlns:xalan="http://xml.apache.org/xalan"
  xmlns:sparql="http://www.w3.org/2001/sw/DataAccess/rf1/result"
  xmlns:encoder="xalan://java.net.URLEncoder"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:java="http://xml.apache.org/xalan/java"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" exclude-result-prefixes="rdf">
  <xsl:import href="/usr/local/fedora/tomcat/webapps/fedoragsearch/WEB-INF/classes/fgsconfigFinal/index/FgsIndex/islandora_transforms/RELS-EXT_to_solr.xslt"/>

  <xsl:variable name="research_data_version_flag_name">mmv_is_latest_b</xsl:variable>
  <xsl:variable name="research_data_membership_field">RELS_EXT_isMemberOf_uri_ms</xsl:variable>

  <!--
    Check if the given document claims to be the latest, and reindex the current.

    @param $current
      A generated Solr "doc" element with child fields, as per Solr's UpdateXML
      (as we generated in the foxmlToSolr.xslt.

    @return
      If there are other documents in Solr at time of indexing claiming to be
      the latest, we output "doc" elements reindexing them; otherwise, we do
      nothing.
  -->
  <xsl:template name="reindex_previous_newest_research_data_set_version_if_necessary">
    <xsl:param name="current"/>

    <xsl:variable name="doc" select="$current/doc"/>

    <xsl:if test="normalize-space($doc/field[@name=$research_data_version_flag_name]) = 'true'">
      <!--
        We are the latest... we need to check for any other document claiming
        to be the latest and reindex it.
      -->
      <xsl:variable name="container_query">
        <xsl:variable name="container_candidates" select="$doc/field[@name='RELS_EXT_isMemberOf_uri_s' or @name=$research_data_membership_field]"/>
        <xsl:value-of select="$research_data_membership_field"/>
        <xsl:text>:(</xsl:text>
        <xsl:for-each select="$container_candidates">
          <xsl:text>"</xsl:text>
          <xsl:value-of select="normalize-space(.)"/>
          <xsl:text>"</xsl:text>
          <xsl:if test="position() != last()">
            <xsl:text> OR </xsl:text>
          </xsl:if>
        </xsl:for-each>
        <xsl:text>)</xsl:text>
      </xsl:variable>
      <xsl:variable name="solr_query_url" select="string(normalize-space(concat(
        $PROT,
        '://',
        $HOST,
        ':',
        $PORT,
        '/solr/select?q=',
        encoder:encode(concat(
          $container_query,
          ' AND ',
          $research_data_version_flag_name,
          ':&quot;true&quot; AND -PID:&quot;',
          normalize-space($doc/field[@name='PID']),
          '&quot;'
        )),
        '&amp;fl=PID'
      )))"/>

      <xsl:variable name="query_result" select="document(string($solr_query_url))"/>
      <xsl:for-each select="$query_result/response/result[@name='response']/doc">
        <xsl:call-template name="mmv_update_former_latest">
          <xsl:with-param name="pid" select="str[@name='PID']"/>
          <xsl:with-param name="version" select="long[@name='_version_']"/>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:if>
  </xsl:template>

  <!--
    Helper; generate a "doc" to update a record in Solr presently claiming to be the latest.

    @param string $pid
      The PID of the object to update.
    @param long $version
      The version of the document in Solr, as per the _version_ field, so as to
      avoid stomping on things potentially indexed in other threads.

    @return
      A "doc" UpdateXMLMessage element.

    @see https://wiki.apache.org/solr/Optimistic_Concurrency
    @see https://wiki.apache.org/solr/Per%20Steffensen/Update%20semantics
  -->
  <xsl:template name="mmv_update_former_latest">
    <xsl:param name="pid"/>
    <xsl:param name="version"/>

    <!--
      XXX: Updating existing documents is _not_ viable in Solr 4, given
      https://issues.apache.org/jira/browse/SOLR-3743 ...
      It appears "copyField" directives are rerun on update, so stored
      copyField targets (such as our *_ss field) will end up with multiple
      values... despite being defined as single-valued.
    -->
    <xsl:variable name="xml_url" select="concat($PROT, '://', encoder:encode($FEDORAUSER), ':', encoder:encode($FEDORAPASS), '@', $HOST, ':', $PORT, '/fedora/objects/', $pid, '/objectXML')"/>
    <xsl:variable name="object" select="document($xml_url)"/>
    <xsl:if test="$object">
      <xsl:apply-templates select="$object/foxml:digitalObject" mode="indexFedoraObject">
        <xsl:with-param name="PID" select="$pid"/>
        <xsl:with-param name="version" select="$version"/>
      </xsl:apply-templates>
    </xsl:if>
  </xsl:template>

  <!--
    Conditionally index flag for mmv objects.

    This should conditionally override the core implementation for our specific
    relationship by virtue of being loaded and in the same mode.

    @see https://github.com/discoverygarden/islandora_transforms/blob/3f4f40b1b2277c9a435c0f1387975f6be0d85e57/RELS-EXT_to_solr.xslt#L26-L37
  -->
  <xsl:template xmlns:fedora-model="info:fedora/fedora-system:def/model#"
    match="fedora-model:hasModel[@rdf:resource='info:fedora/islandora:research_data_major_minor_version_model']"
    mode="rels_ext_element">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>

    <!--
      XXX: Ideally, we could do an "apply-imports" or something of the like
      here; however, XSLT 1.0 does not and cannot pass parameters inside
      of apply-imports... instead, inline the content of what we would expect
      to run...

      @see https://github.com/discoverygarden/islandora_transforms/blob/3f4f40b1b2277c9a435c0f1387975f6be0d85e57/RELS-EXT_to_solr.xslt#L31-L36
    -->
    <xsl:call-template name="rels_ext_fields">
      <xsl:with-param name="prefix" select="$prefix"/>
      <xsl:with-param name="suffix" select="$suffix"/>
      <xsl:with-param name="type">uri</xsl:with-param>
      <xsl:with-param name="value" select="@rdf:resource"/>
    </xsl:call-template>
    <!-- XXX: ... that's it. -->

    <xsl:if test="$maintain_dataset_latest_version_flag">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="$research_data_version_flag_name"/>
        </xsl:attribute>
        <xsl:call-template name="research_data_version_is_latest">
          <xsl:with-param name="full_pid" select="../@rdf:about"/>
        </xsl:call-template>
      </field>
    </xsl:if>
  </xsl:template>

  <!--
    Determine if the given object is the latest version in its conatainer(s).

    @param string $full_pid
      The full PID of the object to test, with the "info:fedora/" prefix.

    @return string
      The string "true" if there were no newer versions under the containing
      container/data set; otherwise, "false".

    NOTE: Due to the use of "FILTER NOT EXISTS", we require an RI which
    supports Sparql 1.1.
  -->
  <xsl:template name="research_data_version_is_latest">
    <xsl:param name="full_pid"/>

    <xsl:variable name="result">
      <xsl:variable name="base_query">
        <![CDATA[
          ASK {
            VALUES ?base {<!!FULL_PID!!>}
            ?base <fedora-rels-ext:isMemberOf> ?container ;
                  <fedora-model:hasModel> <info:fedora/islandora:research_data_major_minor_version_model> ;
                  <http://islandora.ca/ontology/relsext#isMajorVersionNumber> ?base_major ;
                  <http://islandora.ca/ontology/relsext#isMinorVersionNumber> ?base_minor ;
                  <http://islandora.ca/ontology/relsext#isPatchVersionNumber> ?base_patch .
            ?container <fedora-model:hasModel> <info:fedora/islandora:research_data_set_model> .
            FILTER NOT EXISTS {
                ?version <fedora-rels-ext:isMemberOf> ?container ;
                         <fedora-model:hasModel> <info:fedora/islandora:research_data_major_minor_version_model> ;
                         <http://islandora.ca/ontology/relsext#isMajorVersionNumber> ?major ;
                         <http://islandora.ca/ontology/relsext#isMinorVersionNumber> ?minor ;
                         <http://islandora.ca/ontology/relsext#isPatchVersionNumber> ?patch .
                FILTER(?major > ?base_major || (?major = ?base_major && ?minor > ?base_minor) || (?major = ?base_major && ?minor = ?base_minor && ?patch > ?base_patch))
            }
          }
        ]]>
      </xsl:variable>
      <xsl:call-template name="perform_traversal_query">
        <xsl:with-param name="query" select="java:replaceAll(string($base_query), '!!FULL_PID!!', $full_pid)"/>
        <xsl:with-param name="lang">sparql</xsl:with-param>
      </xsl:call-template>
    </xsl:variable>

    <xsl:value-of
      select="normalize-space(xalan:nodeset($result)/sparql:sparql/sparql:results/sparql:result/sparql:k0)"/>
  </xsl:template>
</xsl:stylesheet>
