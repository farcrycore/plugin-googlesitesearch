<cfsetting enablecfoutputonly="true" />

<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />

<!---NOTE: dont't pick up type view calls or form calls without datetimecreated (ie library pickers)--->
<cfif 	structkeyexists(request,"stObj") AND 
		structkeyexists(request.stobj,"datetimecreated") AND
		NOT request.stObj.typename eq "farCOAPI" AND
		NOT (structKeyExists(url, "view") AND url.view eq "displayLibraryTabs")
		>

	<cfset stMeta = structnew() />
	<cfset stMeta.typename = request.stObj.typename />
	<cfset stMeta.objectid = request.stObj.objectid />
	<cfif structkeyexists(request.stObj,"publishDate")>
		<cfset stMeta.publishdate = "#dateformat(request.stObj.publishDate,'yyyymmdd')#" />
	<cfelse>
		<cfset stMeta.publishdate = "#dateformat(request.stObj.datetimecreated,'yyyymmdd')#" />
	</cfif>
	
	<cfset o = application.fapi.getContentType(request.stObj.typename) />
	<cfif structkeyexists(o,"getSearchMetadata")>
		<cfset structappend(stMeta,o.getSearchMetadata(request.stObject),true) />
	</cfif>
	
	<skin:htmlHead id="googlecustomsearch"><cfloop collection="#stMeta#" item="key"><cfoutput><meta name="#lcase(key)#" content="#stMeta[key]#"></cfoutput></cfloop></skin:htmlHead>
</cfif>

<cfsetting enablecfoutputonly="false" />