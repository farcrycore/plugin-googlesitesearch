<cfsetting enablecfoutputonly="true" />

<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />

<cfif structkeyexists(request,"stObj") and not request.stObj.typename eq "farCOAPI">
	<cfset stMeta = structnew() />
	<cfset stMeta.typename = request.stObj.typename />
	<cfset stMeta.objectid = request.stObj.objectid />
	<cfif structkeyexists(request.stObj,"publishDate")>
		<cfset stMeta.publishdate = "#dateformat(request.stObj.publishDate,'dd mmm yyyy')#" />
	<cfelse>
		<cfset stMeta.publishdate = "#dateformat(request.stObj.datetimecreated,'dd mmm yyyy')#" />
	</cfif>
	
	<cfset o = application.fapi.getContentType(request.stObj.typename) />
	<cfif structkeyexists(o,"getSearchMetadata")>
		<cfset structappend(stMeta,o.getSearchMetadata(request.stObject),true) />
	</cfif>
	
	<skin:htmlHead id="googlecustomsearch"><cfloop collection="#stMeta#" item="key"><cfoutput><meta name="#lcase(key)#" content="#stMeta[key]#"></cfoutput></cfloop></skin:htmlHead>
</cfif>

<cfsetting enablecfoutputonly="false" />