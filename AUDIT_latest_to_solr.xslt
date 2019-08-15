<?xml version="1.0" encoding="UTF-8"?>
<!-- AUDIT (latest). -->
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:foxml="info:fedora/fedora-system:def/foxml#"
    xmlns:audit="info:fedora/fedora-system:def/audit#"
    >

    <xsl:template match="foxml:datastream[@ID='AUDIT']/foxml:datastreamVersion[last()]">
      <xsl:param name="content"/>
      <xsl:param name="prefix">AUDIT_latest</xsl:param>
      <xsl:param name="suffix"></xsl:param>

      <xsl:call-template name="index_audit_record">
        <xsl:with-param name="element" select="$content/audit:auditTrail/audit:record[last()]"/>
        <xsl:with-param name="prefix" select="$prefix"/>
      </xsl:call-template>
    </xsl:template>

    <!-- Process an element. -->
    <xsl:template name="index_audit_record">
      <xsl:param name="prefix"/>
      <xsl:param name="element"/>
      <!-- Process type. -->
      <xsl:call-template name="write_audit_field">
        <xsl:with-param name="field_name" select="concat($prefix, '_process_type_s')"/>
        <xsl:with-param name="value" select="$element/audit:process/@type"/>
      </xsl:call-template>
      <!-- Action. -->
      <xsl:call-template name="write_audit_field">
        <xsl:with-param name="field_name" select="concat($prefix, '_action_s')"/>
        <xsl:with-param name="value" select="$element/audit:action"/>
      </xsl:call-template>
      <!-- ComponentID. -->
      <xsl:call-template name="write_audit_field">
        <xsl:with-param name="field_name" select="concat($prefix, '_componentID_s')"/>
        <xsl:with-param name="value" select="$element/audit:componentID"/>
      </xsl:call-template>
      <!-- Responsibility. -->
      <xsl:call-template name="write_audit_field">
        <xsl:with-param name="field_name" select="concat($prefix, '_responsibility_s')"/>
        <xsl:with-param name="value" select="$element/audit:responsibility"/>
      </xsl:call-template>
      <!-- Date. -->
      <xsl:call-template name="write_audit_field">
        <xsl:with-param name="field_name" select="concat($prefix, '_date_dt')"/>
        <xsl:with-param name="value" select="$element/audit:date"/>
      </xsl:call-template>
      <!-- Justification. -->
      <xsl:call-template name="write_audit_field">
        <xsl:with-param name="field_name" select="concat($prefix, '_justification_s')"/>
        <xsl:with-param name="value" select="$element/audit:justification"/>
      </xsl:call-template>
    </xsl:template>

    <!-- Write a field. -->
    <xsl:template name="write_audit_field">
      <xsl:param name="field_name"/>
      <xsl:param name="value"/>
      <xsl:if test="normalize-space($value)">
        <field>
          <xsl:attribute name="name">
            <xsl:value-of select="$field_name"/>
          </xsl:attribute>
          <xsl:value-of select="normalize-space($value)"/>
        </field>
      </xsl:if>
    </xsl:template>

</xsl:stylesheet>
