<cfcomponent displayname="Google Site Search" extends="farcry.core.packages.forms.forms" output="false" hint="" key="gss" fuAlias="sitesearch">
	
<!--- 
 // Config Properties
--------------------------------------------------------------------------------------------------->
	<cfproperty 
		name="id" type="string" 
		ftSeq="1" ftFieldset="API Access" ftLabel="Search Engine Unique ID" 
		ftHint="Copy this from the Basics area of your search engine's <a href='http://www.google.com/cse/manage/all'>control panel</a>" />
	
	<cfproperty 
		name="key" type="string" 
		ftSeq="2" ftFieldset="API Access" ftLabel="API Access Key" 
		ftHint="Do not provide an API key if you are using Google Site Search. If you wish to access your search engine through the Google API, create/retrieve the access key from the <a href='https://code.google.com/apis/console/'>Google APIs Console</a>, in the API Access area." />

	<cfproperty 
		name="searchtypes" type="string" 
		ftSeq="6" ftFieldset="Global Criteria" ftLabel="Searchable Types" 
		ftHint="Select the content types that will be searchable via Google Site Search. Content types which are not selected will not appear in search results.<br>Note: If 'None' is selected then ALL content types will be searchable." 
		ftType="list" ftListData="getTypes" ftSelectMultiple="true" ftStyle="height: 150px;" />
	
	<cfproperty 
		name="domain" type="string" 
		ftSeq="11" ftFieldset="Search Options" ftLabel="Site Search" 
		ftHint="Nominate a single domain to restrict search results to; useful if you manage many websites under a single GSS index." />
		
	<cfproperty 
		name="types" type="string" 
		ftSeq="12" ftFieldset="Search Options" ftLabel="Type Filters" 
		ftHint="Add content type filters. Allows users to restrict their search to specific content types." 
		ftType="list" ftListData="getTypes" ftSelectMultiple="true" />
		
	<cfproperty
		name="log" type="string"
		ftSeq="21" ftFieldset="Logging" ftLabel="Enable Logging"
		ftHint="Logs search URLs into the gss log file"
		ftType="boolean" ftDefault="0" default="0" />
	
	<cfproperty 
		name="lSitemapTypes" type="longchar" 
		ftSeq="12" ftFieldset="Sitemap" ftLabel="Sitemap types" 
		ftType="list" ftListData="getTypes" ftSelectMultiple="true" default="" />
	
	
<!--- 
 // Config Functions
--------------------------------------------------------------------------------------------------->	
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
		<cfargument name="searchtype" type="string" required="false" default="all" hint="any, all, phrase" />
		<!--- Extra arguments are interpreted as metatag filters --->
		
		<cfset var i = "" />
		<cfset var typeFilterCriteria = "" />
		<cfset var s = "" />
		
		<!--- manually incorporate the search type --->
		<cfswitch expression="#arguments.searchtype#">
			<cfcase value="any">
				<cfset s = "" />
				<cfloop list="#arguments.query#" index="i" delimiters=" ">
					<cfif len(s)>
						<cfset s = s & " OR " />
					</cfif>
					<cfset s = s & i />
				</cfloop>
				<cfset arguments.query = s />
			</cfcase>
			<cfcase value="phrase">
				<cfset arguments.query = '"' & arguments.query & '"' />
			</cfcase>
		</cfswitch>
		
		<!--- if subset is an empty string, use the global defaults to filter by --->
		<cfif NOT len(arguments.subset)>

			<!--- get the list of globally allowed search types --->
			<cfif listlen(application.config.gss.searchtypes)>
				<!--- build type filtering criteria list --->
				<cfloop from="1" to="#listLen(application.config.gss.searchtypes)#" index="i">
					<cfset typeFilterCriteria = typeFilterCriteria & "more:pagemap:metatags-typename:#listGetAt(application.config.gss.searchtypes, i)#">
					<cfif i neq listLen(application.config.gss.searchtypes)>
						<cfset typeFilterCriteria = typeFilterCriteria & " OR ">
					</cfif>
				</cfloop>
				
				<!--- append to search query --->
				<cfset arguments.query = listappend(arguments.query,"#typeFilterCriteria#"," ") />
			</cfif>
		<cfelseif listlen(arguments.subset) gt 1>
			<cfset lSubsets = "">
			<cfloop list="#arguments.subset#" index=i>
				<cfif listfindnocase(application.config.gss.searchtypes,i)>
					<cfset lSubsets = listappend(lSubsets,"more:pagemap:metatags-typename:#i#",",") />
				</cfif>
			</cfloop>
			<cfset arguments.query = listappend(arguments.query,"#replace(lsubsets,',',' OR ',"ALL")#"," ") />
		<cfelseif len(arguments.subset) and listfindnocase(application.config.gss.searchtypes,arguments.subset)>
			<cfset arguments.query = listappend(arguments.query,"more:pagemap:metatags-typename:#arguments.subset#"," ") />
		</cfif>

		<!--- always filter out pages marked as not searchable --->
		<cfset arguments.query = listappend(arguments.query,"-more:pagemap:metatags-searchable:false"," ") />
		
		<cfif arguments.bSiteSearch and len(application.config.gss.domain)>
			<cfset arguments.query = listappend(arguments.query,"site:#application.config.gss.domain#"," ") />
		</cfif>
		
		<!--- Add any extra arguments as metatag filters --->
		<cfloop collection="#arguments#" item="i">
			<cfif not listfindnocase("query,subset,bSiteSearch,searchtype",i) and len(arguments[i])>
				<cfset arguments.query = listappend(arguments.query,"more:pagemap:metatags-#lcase(i)#:#arguments[i]#"," ") />
			</cfif>
		</cfloop>

		<cfreturn arguments.query />
	</cffunction>
	
</cfcomponent>