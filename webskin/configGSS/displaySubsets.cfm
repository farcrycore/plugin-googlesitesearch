<cfsetting enablecfoutputonly="true" />
<!--- @@displayname: Search --->

<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />

<cfparam name="url.s" default="" /><!--- subset --->

<!--- configuration options --->
<cfparam name="arguments.stParam.displayStyle" default="unorderedList">
<cfparam name="arguments.stParam.id" default="search-subsets">
<cfparam name="arguments.stParam.bFirst" default="0">
<cfparam name="arguments.stParam.firstClass" default="first" />
<cfparam name="arguments.stParam.bLast" default="0">
<cfparam name="arguments.stParam.lastClass" default="last" />
<cfparam name="arguments.stParam.bActive" default="0">
<cfparam name="arguments.stParam.activeClass" default="active" />
<cfparam name="arguments.stParam.class" default="">
<cfparam name="arguments.stParam.style" default="">
<cfparam name="arguments.stParam.bSpan" default="false">

<cfset stLocal.qSubsets = getSubsets() />

<cfswitch expression="#arguments.stParam.displayStyle#">
	<cfcase value="unorderedList"><cfoutput><ul id="#arguments.stParam.id#" class="#arguments.stParam.class#" style="#arguments.stParam.style#"></cfoutput></cfcase>
	<cfcase value="aLink"><cfoutput><div id="#arguments.stParam.id#" class="#arguments.stParam.class#" style="#arguments.stParam.style#"></cfoutput></cfcase>
</cfswitch>

<cfloop query="stLocal.qSubsets">
	<cfset stLocal.class = "" />
	<cfif stLocal.qSubsets.value eq url.s and arguments.stParam.bActive><cfset stLocal.class = listappend(stLocal.class,arguments.stParam.activeClass," ") /></cfif>
	<cfif stLocal.qSubsets.currentrow eq 1 and arguments.stParam.bFirst><cfset stLocal.class = listappend(stLocal.class,arguments.stParam.firstClass," ") /></cfif>
	<cfif stLocal.qSubsets.currentrow eq stLocal.qSubsets.recordcount and arguments.stParam.bLast><cfset stLocal.class = listappend(stLocal.class,arguments.stParam.lastClass," ") /></cfif>
	
	<cfswitch expression="#arguments.stParam.displayStyle#">
		<cfcase value="unorderedList"><cfoutput><li class="#stLocal.class#"></cfoutput></cfcase>
		<cfcase value="aLink"><cfoutput><cfif stLocal.qSubsets.currentrow gt 1> | </cfif><span class="#stLocal.class#"></cfoutput></cfcase>
	</cfswitch>
	
	<cfif stLocal.qSubsets.value eq "">
		<cfoutput><a href="#application.fapi.fixURL(removevalues='s')#"></cfoutput>
	<cfelse>
		<cfoutput><a href="#application.fapi.fixURL(addvalues='s=#stLocal.qSubsets.value#')#"></cfoutput>
	</cfif>
	<cfif arguments.stParam.bSpan><cfoutput><span></cfoutput></cfif>
	<cfoutput>#stLocal.qSubsets.label#</cfoutput>
	<cfif arguments.stParam.bSpan><cfoutput></span></cfoutput></cfif>
	<cfoutput></a></cfoutput>
	
	<cfswitch expression="#arguments.stParam.displayStyle#">
		<cfcase value="unorderedList"><cfoutput></li></cfoutput></cfcase>
		<cfcase value="aLink"><cfoutput></span></cfoutput></cfcase>
	</cfswitch>
</cfloop>

<cfswitch expression="#arguments.stParam.displayStyle#">
	<cfcase value="unorderedList"><cfoutput></ul></cfoutput></cfcase>
	<cfcase value="aLink"><cfoutput></div></cfoutput></cfcase>
</cfswitch>

<cfsetting enablecfoutputonly="false" />