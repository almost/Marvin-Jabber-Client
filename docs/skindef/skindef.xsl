<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
	<xsl:template match="/skindef">
		<html>
			<head><title>Skin Definition for: <xsl:value-of select="@name"/></title></head>
			<body>
				<center>Skin Definition for:
				<h1><xsl:value-of select="@name"/></h1></center>
				<p><xsl:value-of select="description"/></p>
				<hr/>
				<h2>Resources:</h2>
				<xsl:apply-templates select="resource"/>
				<p>
				<h2>Messages:</h2><br/>
				The following messages can be sent from any window, please see bellow for messages that can only be sent from specific windows.<br/>
				Please note that not all of these messages make sense in all windows.
				<table border="1">
					<tr><td><b>Message</b></td><td><b>Required</b></td><td><b>Description</b></td></tr>
					<xsl:for-each select="message">
						<tr>
						<td><xsl:value-of select="@name"/></td>
						<td><xsl:value-of select="@required"/></td>
						<td><xsl:apply-templates select="description"/></td>
						</tr>
					</xsl:for-each>
				</table>
				</p>
				<hr/>
				<p>
				<h2>Text Variables:</h2><br/>
				The following variables can be used in the text of areas in any window, please see bellow for variables that can only be used in areas in specific windows.<br/>
				<table border="1">
					<tr><td><b>Variable</b></td><td><b>Description</b></td></tr>
					<xsl:for-each select="textvariable">
						<tr>
						<td>$<xsl:value-of select="@name"/>$</td>
						<td><xsl:apply-templates select="description"/></td>
						</tr>
					</xsl:for-each>
				</table>
				</p>
				<hr/>
				<xsl:for-each select="window">
					<h2>Window: <xsl:value-of select="@name"/></h2>
					<p><xsl:value-of select="description"/></p>
					<p>
					<b>Areas:</b>
					<table border="1">
						<tr><td><b>Area</b></td><td><b>Required</b></td><td><b>Description</b></td></tr>
						<xsl:for-each select="area">
							<tr>
							<td><xsl:value-of select="@name"/></td>
							<td><xsl:value-of select="@required"/></td>
							<td><xsl:value-of select="description"/>
							
							<p>
							<b>States:</b>
							<table border="1">
								<tr><td><b>Name</b></td><td><b>Description</b></td></tr>
								<xsl:for-each select="state">
									<tr>
									<td><xsl:value-of select="@name"/></td>
									<td><xsl:apply-templates select="description"/></td>
									</tr>
								</xsl:for-each>
							</table>
							</p>
							
							</td>
							</tr>
						</xsl:for-each>
					</table>
					</p><p>
					<b>Messages:</b><br/>
					The following messages are valid within this window in addition to the global messages listed above.
					<table border="1">
						<tr><td><b>Message</b></td><td><b>Required</b></td><td><b>Description</b></td></tr>
						<xsl:for-each select="message">
							<tr>
							<td><xsl:value-of select="@name"/></td>
							<td><xsl:value-of select="@required"/></td>
							<td><xsl:apply-templates select="description"/></td>
							</tr>
						</xsl:for-each>
					</table>
					</p>
					<p>
					<b>Text Variables:</b><br/>
					The following variuables are valid within this window in addition to the global variables listed above..<br/>
					<table border="1">
						<tr><td><b>Variable</b></td><td><b>Description</b></td></tr>
						<xsl:for-each select="textvariable">
							<tr>
							<td>$<xsl:value-of select="@name"/>$</td>
							<td><xsl:apply-templates select="description"/></td>
							</tr>
						</xsl:for-each>
					</table>
					</p>
					<hr/>
				</xsl:for-each>
			</body>
		</html>
	</xsl:template>
	
	<xsl:template match="resource">
		<b> <xsl:value-of select="@name"/></b>
		<p><xsl:value-of select="description"/></p>
		<table>
		<tr>
		<td width="10%"></td>
		<td><xsl:apply-templates select="resource"/></td>
		</tr>
		</table>
		<hr/>
	</xsl:template>
</xsl:stylesheet>