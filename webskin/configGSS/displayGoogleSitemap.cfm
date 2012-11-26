<cfsetting enablecfoutputonly="true">
<!--- @@displayName: Google Site Map --->
<!--- @@description: XML sitemap for Google. --->

<!--- @@fuAlias: googlesitemap --->
<!--- @@viewStack: page --->
<!--- @@cacheStatus: 1 --->
<!--- @@cacheTimeout: 60 --->

<cfset request.mode.ajax = true />

<cfset stLocal.perSection = 50000 />

<cfif not isdefined("application.config.gss.lSitemapTypes") or not len(application.config.gss.lSitemapTypes)>
	<cfset application.config.gss.lSitemapTypes = application.config.gss.searchtypes />
</cfif>

<cfquery datasource="#application.dsn#" name="stLocal.qURLs"><cfoutput>
	<!--- Site tree --->
	SELECT		'http://#cgi.http_host##application.url.webroot#' + f.friendlyurl as url, isnull(f.bdefault,0) as hasFriendly,
				'dmNavigation' as typename,
				t.objectid,
				t.datetimelastupdated as lastmod,
				n.nlevel
	FROM		dmNavigation t
				INNER JOIN
				nested_tree_objects n
				ON
				t.objectid=n.objectid 
				LEFT OUTER JOIN
				farfu f 
				ON t.objectid = f.refobjectid,
				
				nested_tree_objects n2
				
	WHERE		t.status = <cfqueryparam cfsqltype="cf_sql_varchar" value="approved" />
				AND isnull(f.bdefault,1) = 1 
				AND n2.objectid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#application.navid.home#" /> <!--- n2 = home node --->
				AND n2.nleft < n.nleft AND n.nright < n2.nright <!--- only show children of home node --->
	
	<!--- Other content types --->
	<cfloop list="#application.config.gss.lSitemapTypes#" index="thistype">
		<cfif structkeyexists(application.stCOAPI,thistype) and not thistype eq "dmNavigation">
			UNION ALL
			
			SELECT		'http://#cgi.http_host##application.url.webroot#' + f.friendlyurl as url, isnull(f.bdefault,0) as hasFriendly,
						'#thistype#' as typename,
						t.objectid,
						<cfif structkeyexists(application.stCOAPI[thistype].stProps,"publishdate")>t.publishdate<cfelse>t.datetimelastupdated</cfif> as lastmod,
						-1 as nlevel
			FROM		#thistype# t
						LEFT OUTER JOIN
						farfu f 
						ON t.objectid = f.refobjectid
			WHERE		isnull(f.bdefault,1) = 1 
						<cfif structkeyexists(application.stCOAPI[thistype].stProps,"status")>
							AND t.status = <cfqueryparam cfsqltype="cf_sql_varchar" value="approved" />
						</cfif>
						<cfif structkeyexists(application.stCOAPI[thistype].stProps,"publishdate")>
							AND t.publishdate < <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#" />
						</cfif>
		</cfif>
	</cfloop>
	
	ORDER BY	lastmod desc
</cfoutput></cfquery>

<!--- Create the XML --->
<cfif stLocal.qURLs.recordcount lte stLocal.perSection>
	
	<!--- Single file sitemap --->
	<cfset stLocal.sitemap = createObject("java","java.lang.StringBuffer").init() />
	<cfset stLocal.sitemap.append('<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">') />
	<cfloop query="stLocal.qURLs">
		<cfset stLocal.sitemap.append("<url>") />
		<cfif stLocal.qURLs.hasFriendly>
			<cfset stLocal.sitemap.append("<loc>#stLocal.qURLs.url#</loc>") />
		<cfelse>
			<cfset stLocal.sitemap.append("<loc>http://#cgi.http_host##application.url.webroot#/index.cfm?objectid=#stLocal.qURLs.objectid#</loc>") />
		</cfif>
		<cfset stLocal.sitemap.append("<lastmod>#dateformat(stLocal.qURLs.lastmod,'yyyy-mm-dd')#</lastmod>") />
		<cfif stLocal.qURLs.nlevel eq -1><!--- General content --->
			<cfset stLocal.sitemap.append("<changefreq>weekly</changefreq>") />
			<cfset stLocal.sitemap.append("<priority>#numberformat(1,'0.0')#</priority>") />
		<cfelseif stLocal.qURLs.nlevel eq 2><!--- Main menu navigation --->
			<cfset stLocal.sitemap.append("<changefreq>daily</changefreq>") />
			<cfset stLocal.sitemap.append("<priority>#numberformat(1,'0.0')#</priority>") />
		<cfelse><!--- Everything else --->
			<cfset stLocal.sitemap.append("<changefreq>weekly</changefreq>") />
			<cfset stLocal.sitemap.append("<priority>#numberformat(1-(stLocal.qURLs.nlevel-1)/10,'0.0')#</priority>") />
		</cfif>
		<cfset stLocal.sitemap.append("</url>") />
	</cfloop>
	<cfset stLocal.sitemap.append("</urlset>") />
	
<cfelseif isdefined("url.section")>

	<!--- Multi-section sitemap - this request is for a specific section --->
	<cfset stLocal.sitemap = createObject("java","java.lang.StringBuffer").init() />
	<cfset stLocal.sitemap.append('<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">') />
	<cfloop from="#(url.section-1)*stLocal.perSection+1#" to="#min(stLocal.qURLs.recordcount,(url.section-1)*stLocal.perSection+stLocal.perSection)#" index="i">
		<cfset stLocal.sitemap.append("<url>") />
		<cfif len(stLocal.qURLs.url[i])>
			<cfset stLocal.sitemap.append("<loc>#stLocal.qURLs.url[i]#</loc>") />
		<cfelse>
			<cfset stLocal.sitemap.append("<loc>http://#cgi.http_host##application.url.webroot#/index.cfm?objectid=#stLocal.qURLs.objectid[i]#</loc>") />
		</cfif>
		<cfset stLocal.sitemap.append("<lastmod>#dateformat(stLocal.qURLs.lastmod[i],'yyyy-mm-dd')#</lastmod>") />
		<cfif stLocal.qURLs.nlevel[i] eq -1><!--- General content --->
			<cfset stLocal.sitemap.append("<changefreq>weekly</changefreq>") />
			<cfset stLocal.sitemap.append("<priority>#numberformat(1,'0.0')#</priority>") />
		<cfelseif stLocal.qURLs.nlevel[i] eq 2><!--- Main menu navigation --->
			<cfset stLocal.sitemap.append("<changefreq>daily</changefreq>") />
			<cfset stLocal.sitemap.append("<priority>#numberformat(1,'0.0')#</priority>") />
		<cfelse><!--- Everything else --->
			<cfset stLocal.sitemap.append("<changefreq>weekly</changefreq>") />
			<cfset stLocal.sitemap.append("<priority>#numberformat(1-(stLocal.qURLs.nlevel[i]-1)/10,'0.0')#</priority>") />
		</cfif>
	</cfloop>
	<cfset stLocal.sitemap.append("</urlset>") />
	
<cfelse>
	
	<!--- Multi-section sitemap - this request is for the index --->
	<cfset stLocal.sitemap = createObject("java","java.lang.StringBuffer").init() />
	<cfset stLocal.sitemap.append('<?xml version="1.0" encoding="UTF-8"?><sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">') />
	<cfloop from="1" to="#int(stLocal.qURLs.recordcount / stLocal.perSection) + 1#" index="thissection">
		<cfset stLocal.sitemap.append("<sitemap>") />
		<cfset stLocal.sitemap.append("<loc>#application.fapi.getLink(type='dmNavigation',view='displayGoogleSitemap',urlparameters='section=#thissection#')#</loc>") />
		<cfset stLocal.sitemap.append("<lastmod>#dateformat(stLocal.qURLs.lastmod[(thissection-1) * stLocal.perSection + 1],'yyyy-mm-dd')#</lastmod>") />
		<cfset stLocal.sitemap.append("</sitemap>") />
	</cfloop>
	<cfset stLocal.sitemap.append("</sitemapindex>") />
	
</cfif>

<!--- Stream the result --->
<CFHEADER NAME="Cache-Control" VALUE="max-age=300;s-maxage=300">
<cfcontent type="application/xml" variable="#ToBinary( ToBase64(stLocal.sitemap.toString()) )#" reset="Yes" />

<cfsetting enablecfoutputonly="false">