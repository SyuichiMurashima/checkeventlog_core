##########################################################################
#
# XML 整形
# http://blogs.msdn.com/b/powershell/archive/2008/01/18/format-xml.aspx
#
##########################################################################
function Format-XML([xml]$xml, $indent=2)
{
	$StringWriter = New-Object System.IO.StringWriter
	$XmlWriter = New-Object System.Xml.XmlTextWriter $StringWriter
	$XmlWriter.Formatting = "indented"
	$XmlWriter.Indentation = $Indent
	$xml.WriteContentTo($XmlWriter)
	$XmlWriter.Flush()
	$StringWriter.Flush()
	return $StringWriter.ToString()
}
