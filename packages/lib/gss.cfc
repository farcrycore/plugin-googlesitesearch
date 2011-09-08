<cfcomponent hint="API for Google Custom Search" output="false">
	
	
	<cffunction name="getAuthToken" access="public" output="false" returntype="string">
		<cfargument name="settings" type="struct" default="#application.config.gss#" />
		
		<cfset var cfhttp = structnew() />
		<cfset var info = "" />
		
		<cfif not structkeyexists(arguments.settings,"email") or not len(arguments.settings.email) or not structkeyexists(arguments.settings,"email") or not len(arguments.settings.password)>
			<cfreturn "" />
		<cfelseif isdefined("session.security.gss.auth") and session.security.gss.hash eq hash("#arguments.settings.email#-#arguments.settings.password#-#application.applicationname#_website")>
			<cfreturn session.security.gss.auth />
		</cfif>
		
		<cfhttp url="https://www.google.com/accounts/ClientLogin" method="post">
			<cfhttpparam type="formfield" name="accountType" value="HOSTED_OR_GOOGLE" />
			<cfhttpparam type="formfield" name="Email" value="#arguments.settings.email#" />
			<cfhttpparam type="formfield" name="Passwd" value="#arguments.settings.password#" />
			<cfhttpparam type="formfield" name="service" value="cprose" />
			<cfhttpparam type="formfield" name="source" value="#application.applicationname#_website" />
		</cfhttp>
		
		<cfif cfhttp.statuscode eq "401 Unauthorized" or cfhttp.statuscode eq "403 Forbidden">
			<cfthrow message="Invalid authorisation details" />
		<cfelseif not cfhttp.statuscode eq "200 OK">
			<cfthrow message="Error accessing Google API: #cfhttp.statuscode#" />
		<cfelse>
			<cfset session.security.gss = structnew() />
			<cfset session.security.gss.hash = hash("#arguments.settings.email#-#arguments.settings.password#-#application.applicationname#_website")>
			<cfloop list="#cfhttp.filecontent#" index="info" delimiters=" #chr(10)##chr(13)##chr(9)#">
				<cfset session.security.gss[listfirst(info,"=")] = listlast(info,"=") />
			</cfloop>
		</cfif>
		
		<cfreturn session.security.gss.auth />
	</cffunction>
	
	<cffunction name="apiRequest" access="private" output="false" returntype="any">
		<cfargument name="auth" type="string" required="false" hint="Google authorisation token" />
		<cfargument name="url" type="string" required="true" hint="Request URL" />
		<cfargument name="body" type="string" required="false" default="" />
		
		<cfset var cfhttp = structnew() />
		<cfset var stResult = structnew() />
		<cfset var method = "GET" />
		<cfset var qs = "" />
		<cfset var qsk = "" />
		
		<cfif not structkeyexists(arguments,"auth") or not len(arguments.auth)>
			<cfset arguments.auth = getAuthToken() />
		</cfif>
		
		<cfif len(arguments.body)>
			<cfset method = "POST" />
		</cfif>
		
		<cfloop collection="#arguments#" item="qsk">
			<cfif not listcontainsnocase("auth,url,body",qsk)>
				<cfset qs = listappend(qs,"#lcase(qsk)#=#arguments[qsk]#","&") />
			</cfif>
		</cfloop>
		<cfif len(qs)>
			<cfif find("?",arguments.url)>
				<cfset arguments.url = "#arguments.url#&#qs#" />
			<cfelse>
				<cfset arguments.url = "#arguments.url#?#qs#" />
			</cfif>
		</cfif>
		
		<cfhttp url="#arguments.url#" method="#method#">
			<cfif len(arguments.auth)><cfhttpparam type="header" name="Authorization" value="GoogleLogin auth=#arguments.auth#" /></cfif>
			<cfif len(arguments.body)><cfhttpparam type="body" value="#trim(arguments.body)#" /></cfif>
		</cfhttp>
		
		<cfif cfhttp.statuscode eq "401 Unauthorized" or cfhttp.statuscode eq "403 Forbidden">
			<cfthrow message="Invalid authorisation details" />
		<cfelseif not cfhttp.statuscode eq "200 OK">
			<cfdump var="#arguments.url#"><cfoutput>#cfhttp.filecontent#"></cfoutput><cfdump var="#cfhttp#"><cfthrow message="Error accessing Google API: #cfhttp.statuscode#" />
		<cfelseif isxml(cfhttp.filecontent)>
			<cfset stResult = xmlparse(cfhttp.filecontent) />
		<cfelseif isjson(cfhttp.filecontent)>
			<cfset stResult = deserializeJSON(cfhttp.filecontent) />
		<cfelse>
			<cfreturn cfhttp.filecontent />
		</cfif>
		
		<cfreturn stResult />
	</cffunction>
	
	<cffunction name="getSearchEngines" access="public" output="false" returntype="query">
		<cfargument name="auth" type="string" required="false" default="" hint="Google authorisation token" />
		
		<cfset var cfhttp = structnew() />
		<cfset var qSearchEngines = querynew("id,title") />
		<cfset var i = 0 />
		
		<cfset stResult = apiRequest(auth=arguments.auth,url="http://www.google.com/cse/api/default/cse/")>
		
		<cfloop from="1" to="#arraylen(stResult.CustomSearchEngines.CustomSearchEngine)#" index="i">
			<cfset queryaddrow(qSearchEngines) />
			<cfset querysetcell(qSearchEngines,"id",stResult.CustomSearchEngines.CustomSearchEngine[i].xmlAttributes.id) />
			<cfset querysetcell(qSearchEngines,"title",stResult.CustomSearchEngines.CustomSearchEngine[i].xmlAttributes.title) />
		</cfloop>
		
		<cfquery dbtype="query" name="qSearchEngines">select * from qSearchEngines order by title asc</cfquery>
		
		<cfreturn qSearchEngines />
	</cffunction>
	
	<cffunction name="getSearchEngine" access="public" output="false" returntype="struct">
		<cfargument name="auth" type="string" required="false" default="" hint="Google authorisation token" />
		<cfargument name="id" type="string" required="true" />
		
		<cfset var stResult = structnew() />
		<cfset var stSE = structnew() />
		
		<cfset stResult = apiRequest(auth=arguments.auth,url="http://www.google.com/cse/api/default/cse/#arguments.id#") />
		
		<cfset stSE.xml = stResult />
		<cfset stSE.id = stResult.CustomSearchEngine.xmlAttributes.id />
		<cfset stSE.keywords = stResult.CustomSearchEngine.xmlAttributes.keywords />
		<cfset stSE.title = stResult.CustomSearchEngine.title.xmlText />
		<cfset stSE.description = stResult.CustomSearchEngine.description.xmlText />
		
		<cfreturn stSE />
	</cffunction>
	
	<cffunction name="createSearchEngine" access="public" output="false" returntype="struct">
		<cfargument name="auth" type="string" required="false" default="" hint="Google authorisation token" />
		<cfargument name="id" type="string" required="false" hint="Search engine id" />
		<cfargument name="title" type="string" required="true" hint="Search engine name" />
		<cfargument name="description" type="string" required="false" default="" hint="Description of engine" />
		<cfargument name="keywords" type="string" required="false" default="" />
		
		<cfset var stResult = structnew() />
		<cfset var xmlpost = "" />
		<cfset var stSE = structnew() />
		
		<cfparam name="arguments.id" default="#replace(trim(rereplace(arguments.title,'[^\w\d]+',' ','ALL')),' ','_','ALL')#">
		
		<cfsavecontent variable="xmlpost"><cfoutput>
			<CustomSearchEngine keywords="#arguments.keywords#" language="en">
				<Title>#xmlformat(arguments.title)#</Title>
				<Description>#xmlformat(arguments.description)#</Description>
				<Context><BackgroundLabels></BackgroundLabels></Context>
				<LookAndFeel nonprofit="false" />
			 </CustomSearchEngine>
		</cfoutput></cfsavecontent>
		
		<cfset stResult = apiRequest(auth=arguments.auth,url="http://www.google.com/cse/api/default/cse/#arguments.id#",body=xmlpost) />
		
		<cfset stSE.xml = stResult />
		<cfset stSE.id = stResult.CustomSearchEngine.xmlAttributes.id />
		<cfset stSE.keywords = stResult.CustomSearchEngine.xmlAttributes.keywords />
		<cfset stSE.title = stResult.CustomSearchEngine.title.xmlText />
		<cfset stSE.description = stResult.CustomSearchEngine.description.xmlText />
		
		<cfreturn stSE />
	</cffunction>
	
	<cffunction name="setSearchEngine" access="public" output="false" returntype="struct">
		<cfargument name="auth" type="string" required="false" default="" hint="Google authorisation token" />
		<cfargument name="id" type="string" required="true" hint="Search engine id" />
		<cfargument name="title" type="string" required="false" hint="Search engine name" />
		<cfargument name="description" type="string" required="false" hint="Description of engine" />
		<cfargument name="keywords" type="string" required="false" />
		
		<cfset var stSE = getSearchEngine(arguments.id) />
		<cfset var stResult = structnew() />
		
		<cfif structkeyexists(arguments,"title")><cfset stSE.xml.CustomSearchEngine.Title.xmlText = arguments.title /></cfif>
		<cfif structkeyexists(arguments,"description")><cfset stSE.xml.CustomSearchEngine.Description.xmlText = arguments.description /></cfif>
		<cfif structkeyexists(arguments,"keywords")><cfset stSE.xml.CustomSearchEngine.xmlAttributes.keywords = arguments.keywords /></cfif>
		
		<cfset stResult = apiRequest(auth=arguments.auth,url="http://www.google.com/cse/api/default/cse/#arguments.id#",body=stSE.xml.toString()) />
		
		<cfset stSE = structnew() />
		<cfset stSE.xml = stResult />
		<cfset stSE.id = stResult.CustomSearchEngine.xmlAttributes.id />
		<cfset stSE.title = stResult.CustomSearchEngine.title.xmlText />
		<cfset stSE.description = stResult.CustomSearchEngine.description.xmlText />
		<cfset stSE.keywords = stResult.CustomSearchEngine.xmlAttributes.keywords />
		
		<cfreturn stSE />
	</cffunction>
	
	<cffunction name="getIndexQuota" access="public" output="false" returntype="numeric">
		<cfargument name="auth" type="string" required="false" default="" hint="Google authorisation token" />
		<cfargument name="id" type="string" required="false" default="#application.config.gss.gssid#" hint="Search engine ID" />
		
		<cfset var stResult = apiRequest(auth=arguments.auth,url="http://www.google.com/cse/api/default/index/#arguments.id#") />
		
		<cfreturn stResult.OnDemandIndex.xmlAttributes.quota />
	</cffunction>
	
	<cffunction name="getSearchResults" access="public" output="false" returntype="struct">
		<cfargument name="key" type="string" required="false" default="#application.config.gss.key#" hint="Google API key" />
		<cfargument name="id" type="string" required="false" default="#application.config.gss.id#" hint="Search engine ID" />
		<cfargument name="query" type="string" required="true" hint="User's query" />
		<cfargument name="domain" type="string" required="false" default="#application.config.gss.domain#" hint="Restrict results to this domain" />
		<cfargument name="page" type="numeric" required="false" default="1" />
		<cfargument name="pagesize" type="numeric" required="false" default="10" />
		
		<cfset var stResult = structnew() />
		<cfset var stReturn = structnew() />
		<cfset var i = 0 />
		<cfset var j = 0 />
		<cfset var start = round((arguments.page-1) * arguments.pagesize) + 1 />
		<cfset var reskey = "" />
		<cfset var subkey = "" />
		<cfset var st = structnew() />
		
		<cfif len(arguments.key)>
			<cfset stResult = apiRequest(url="https://www.googleapis.com/customsearch/v1",key=arguments.key,cx=arguments.id,q=rereplace(urlencodedformat(arguments.query),'( |%20)','+','ALL'),num=round(arguments.pagesize),start=start) />
			
			<cfset stReturn.results = arraynew(1) />
			<cfset stReturn.total = stResult.queries.request[1].totalResults />
			
			<cfif structkeyexists(stResult,"items")>
				<cfloop from="1" to="#arraylen(stResult.items)#" index="i">
					<cfset st = duplicate(stResult.items[i]) />
					<cfif structkeyexists(st,"pagemap")>
						<cfset structappend(st,st.pagemap.metatags[1],false) />
						<cfset st.pagemap = st.pagemap.metatags[1] />
					</cfif>
					<cfloop collection="st" item="j">
						<cfif find("date",st[j]) and refind("\d{4}[01]\d[0123]\d",st[j])>
							<cfset st[j] = createdate(left(st[j],4),mid(st[j],5,2),right(st[j],2)) />
						</cfif>
					</cfloop>
					<cfset arrayappend(stReturn.results,st) />
				</cfloop>
			</cfif>
		<cfelse>
			<cfset stResult = apiRequest(url="https://www.google.com/search",client="google-csbe",cx=arguments.id,output="xml_no_dtd",q=rereplace(urlencodedformat(arguments.query),'( |%20)','+','ALL'),num=round(arguments.pagesize),start=start) />
			
			<cfset stReturn.results = arraynew(1) />
			<cfset stReturn.total = 0 />
			
			<cfif structkeyexists(stResult.gsp,"res") and structkeyexists(stResult.gsp.res,"r")>
				<cfset stReturn.total = stResult.gsp.res.m.xmlText />
				<cfloop from="1" to="#arraylen(stResult.gsp.res.r)#" index="i">
					<cfset st = structnew() />
					<cfset st.link = stResult.gsp.res.r[i].u.xmlText />
					<cfset st.displaylink = rereplacenocase(stResult.gsp.res.r[i].u.xmlText,"^https?\:\/\/([^\/]*)\/.*$","\1") />
					<cfset st.htmltitle = stResult.gsp.res.r[i].t.xmlText />
					<cfset st.htmlsnippet = stResult.gsp.res.r[i].s.xmlText />
					<cfif structkeyexists(stResult.gsp.res.r[i],"PageMap") and structkeyexists(stResult.gsp.res.r[i].PageMap,"DataObject")>
						<cfloop from="1" to="#arraylen(stResult.gsp.res.r[i].PageMap.DataObject.Attribute)#" index="j">
							<cfif not structkeyexists(st,stResult.gsp.res.r[i].PageMap.DataObject.Attribute[j].xmlAttributes.name)>
								<cfif find("date",stResult.gsp.res.r[i].PageMap.DataObject.Attribute[j].xmlAttributes.name) and refind("^\d{4}[01]\d[0123]\d$",stResult.gsp.res.r[i].PageMap.DataObject.Attribute[j].xmlAttributes.value)>
									<cfset st[stResult.gsp.res.r[i].PageMap.DataObject.Attribute[j].xmlAttributes.name] = createdate(left(stResult.gsp.res.r[i].PageMap.DataObject.Attribute[j].xmlAttributes.value,4),mid(stResult.gsp.res.r[i].PageMap.DataObject.Attribute[j].xmlAttributes.value,5,2),right(stResult.gsp.res.r[i].PageMap.DataObject.Attribute[j].xmlAttributes.value,2)) />
								<cfelseif structkeyexists(stResult.gsp.res.r[i].PageMap.DataObject.Attribute[j].xmlAttributes,"value")>
									<cfset st[stResult.gsp.res.r[i].PageMap.DataObject.Attribute[j].xmlAttributes.name] = stResult.gsp.res.r[i].PageMap.DataObject.Attribute[j].xmlAttributes.value />
								</cfif>
							</cfif>
						</cfloop>
					</cfif>
					<cfset arrayappend(stReturn.results,st) />
				</cfloop>
			</cfif>
		</cfif>
		
		<cfreturn stReturn />
	</cffunction>
	
</cfcomponent>