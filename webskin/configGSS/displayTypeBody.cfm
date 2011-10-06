<cfsetting enablecfoutputonly="true" />
<!--- @@displayname: Search --->

<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />
<cfimport taglib="/farcry/core/tags/formtools" prefix="ft" />

<cfparam name="url.q" default="" /><!--- query --->
<cfparam name="url.s" default="" /><!--- subset --->
<cfparam name="url.page" default="1" /><!--- results page --->

<skin:loadJS id="jquery" />		
<skin:loadJS id="farcry-form" />
<skin:loadJS id="jquery-tooltip" />
<skin:loadJS id="jquery-tooltip-auto" />
<skin:loadCSS id="jquery-tooltip" />
<skin:loadCSS id="farcry-form" />

<cfif len(url.q)>
	<cfset o = createobject("component","farcry.plugins.googleSiteSearch.packages.lib.gss") />
	<cfset stLocal.result = o.getSearchResults(query=addRestrictions(url.q,url.s),page=url.page) />
<cfelse>
	<cfset stLocal.result = structnew() />
	<cfset stLocal.result.total = 0 />
</cfif>

<cfset stLocal.qSubsets = getSubsets() />

<cfif isdefined("application.fc.lib.ga")>
	<cfset application.fc.lib.ga.setTrackableURL(url=application.fapi.fixURL(removevalues='page,furl')) />
</cfif>

<skin:loadCSS id="googlesitesearch" />

<cfoutput>
	<cfif isdefined("request.stObj.title")><h1>#request.stObj.title#</h1><cfelse><h1>Search</h1></cfif>
	
	<form action="#application.fapi.fixURL(removevalues='q,page')#" method="GET" class="uniForm">
		<ft:field label="Search"><input type="text" name="q" value="#url.q#" /><input type="submit" value="Search" /></ft:field>
	</form>
	
	<cfif stLocal.qSubsets.recordcount gt 1>
		<ft:field label="Filter to">
			<skin:view typename="configGSS" webskin="displaySubsets" displayStyle="aLink" bActive="true" bFirst="true" bSpan="true" />
		</ft:field>
	</cfif>
	
	<cfif stLocal.result.total>
		<skin:pagination typename="configGSS" array="#stLocal.result.results#" currentpage="#url.page#" totalrecords="#stLocal.result.total#" paginationid="" r_stObject="stLocal.r">

			<cftry>

			<cfset stLocal.r = stLocal.r.objectid />
			<cfif structkeyexists(stLocal.r,"typename")>
				<skin:view typename="#stLocal.r.typename#" webskin="displaySearchResult" gss="#stLocal.r#" />
			<cfelse>
				<skin:view typename="configGSS" webskin="displaySearchResult" gss="#stLocal.r#" />
			</cfif>
			
			<cfcatch><cfdump var="#cfcatch#"></cfcatch>
			</cftry>
		</skin:pagination>
	</cfif>
</cfoutput>

<cfsetting enablecfoutputonly="false" />