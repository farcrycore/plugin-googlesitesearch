<cfcomponent displayname="Google Custom Search" extends="farcry.core.packages.forms.forms" output="false" hint="" key="gss">
	
	<cfproperty ftSeq="1" ftFieldset="API Access" name="id" type="string" ftLabel="Search Engine Unique ID" ftHint="Copy this from the Basics area of your search engine's <a href='http://www.google.com/cse/manage/all'>control panel</a>" />
	<cfproperty ftSeq="2" ftFieldset="API Access" name="key" type="string" ftLabel="API Access Key" ftHint="Create/retrieve the access key from the <a href='https://code.google.com/apis/console/'>Google APIs Console</a>, in the API Access area." />
	
	<cfproperty ftSeq="11" ftFieldset="Search Options" name="domain" type="string" ftLabel="Site Search" ftHint="Restrict results to this domain" />
	<cfproperty ftSeq="12" ftFieldset="Search Options" name="types" type="string" ftLabel="Type Filters" ftHint="Add type filters, so that a user can restrict their search to particular content" ftType="list" ftListData="getTypes" ftSelectMultiple="true" />
	
	
	<cffunction name="getTypes" access="public" output="false" returntype="query">
		<cfset var qResult = querynew("value,name,order","varchar,varchar,integer") />
		<cfset var k = "" />
		
		<cfset queryaddrow(qResult) />
		<cfset querysetcell(qResult,"value","") />
		<cfset querysetcell(qResult,"name","None") />
		<cfset querysetcell(qResult,"order",0) />
		
		<cfloop collection="#application.stCOAPI#" item="k">
			<cfif application.stCOAPI[k].class eq "type" and structkeyexists(application.stCOAPI[k],"displayname")>
				<cfset queryaddrow(qResult) />
				<cfset querysetcell(qResult,"value",k) />
				<cfset querysetcell(qResult,"name",application.stCOAPI[k].displayname) />
				<cfset querysetcell(qResult,"order",1) />
			</cfif>
		</cfloop>
		
		<cfquery dbtype="query" name="qResult">select * from qResult order by [order],[name]</cfquery>
		
		<cfreturn qResult />
	</cffunction>
	
	<cffunction name="getSubsets" access="public" output="false" returntype="query">
		<cfset var qResult = querynew("value,label,order","varchar,varchar,integer") />
		<cfset var k = "" />
		
		<cfset queryaddrow(qResult) />
		<cfset querysetcell(qResult,"value","") />
		<cfset querysetcell(qResult,"label","All") />
		<cfset querysetcell(qResult,"order",0) />
		
		<cfloop list="#application.config.gss.types#" index="k">
			<cfif application.stCOAPI[k].class eq "type" and structkeyexists(application.stCOAPI[k],"displayname")>
				<cfset queryaddrow(qResult) />
				<cfset querysetcell(qResult,"value",k) />
				<cfset querysetcell(qResult,"label",application.stCOAPI[k].displayname) />
				<cfset querysetcell(qResult,"order",1) />
			</cfif>
		</cfloop>
		
		<cfquery dbtype="query" name="qResult">select * from qResult order by [order],[label]</cfquery>
		
		<cfreturn qResult />
	</cffunction>
	
	<cffunction name="addRestrictions" access="public" output="false" returntype="string" hint="Modifies a user supplied query with a subset restriction">
		<cfargument name="query" type="string" required="true" hint="The user submitted query" />
		<cfargument name="subset" type="string" required="true" hint="The subset to add to the query" />
		<cfargument name="bSiteSearch" type="boolean" required="false" default="true" hint="Restrict to the configured domain" />
		
		<cfif len(arguments.subset) and listcontains(application.config.gss.types,arguments.subset)>
			<cfset arguments.query = listappend(arguments.query,"more:pagemap:metatags-typename:#arguments.subset#"," ") />
		</cfif>
		
		<cfif arguments.bSiteSearch and len(application.config.gss.domain)>
			<cfset arguments.query = listappend(arguments.query,"site:#application.config.gss.domain#"," ") />
		</cfif>
		
		<cfreturn arguments.query />
	</cffunction>
	
</cfcomponent>