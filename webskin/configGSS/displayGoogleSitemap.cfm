<cfsetting enablecfoutputonly="true">
<!--- @@displayName: Google Site Map --->
<!--- @@description: XML sitemap for Google. --->

<!--- @@fuAlias: googlesitemap --->
<!--- @@viewStack: page --->
<!--- @@cacheStatus: 1 --->
<!--- @@cacheTimeout: 60 --->

<cfset request.mode.ajax = true />

<cfset stLocal.qURLs = querynew("url,priority,lastmod,changefreq") />
<cfset stLocal.age = arraynew(1) />
<cfset stLocal.persection = 50000 />

<!--- Site tree --->
<cfset stLocal.qNav = application.factory.oTree.getDescendants(objectid=application.navid.home,depth=5,bIncludeSelf=true,lColumns="status,datetimelastupdated") />
<cfloop query="stLocal.qNav">
	<cfif stLocal.qNav.status eq "approved">
		<cfset queryaddrow(stLocal.qURLs) />
		<cfset querysetcell(stLocal.qURLs,"url",application.fapi.getLink(objectid=stLocal.qNav.objectid,includeDomain=true)) />
		<cfif stLocal.qNav.nLevel lte 2>
			<cfset querysetcell(stLocal.qURLs,"priority","1.0") />
		<cfelse>
			<cfset querysetcell(stLocal.qURLs,"priority",numberformat(1-(stLocal.qNav.nLevel-2)/10,'0.0')) />
		</cfif>
		<cfset querysetcell(stLocal.qURLs,"lastmod",dateformat(stLocal.qNav.datetimelastupdated,'yyyy-mm-dd')) />
		<cfif stLocal.qNav.nLevel lte 2>
			<cfset querysetcell(stLocal.qURLs,"changefreq","daily") />
		<cfelse>
			<cfset querysetcell(stLocal.qURLs,"changefreq","weekly") />
		</cfif>
		<cfif ArrayIsDefined(stLocal.age,int(stLocal.qURLs.recordcount / stLocal.persection) + 1)>
			<cfset stLocal.age[int(stLocal.qURLs.recordcount / stLocal.persection) + 1] = min(stLocal.age[int(stLocal.qURLs.recordcount / stLocal.persection) + 1],stLocal.qNav.datetimelastupdated) />
		<cfelse>
			<cfset stLocal.age[int(stLocal.qURLs.recordcount / stLocal.persection) + 1] = stLocal.qNav.datetimelastupdated />
		</cfif>
	</cfif>
</cfloop>

<!--- Other content types --->
<cfparam name="application.config.gss.lSitemapTypes" default="" />
<cfloop list="#application.config.gss.lSitemapTypes#" index="thistype">
	<cfif structkeyexists(application.stCOAPI,thistype)>
		<cfif structkeyexists(application.stCOAPI[thistype].stProps,"publishdate")>
			<cfset stLocal.q = application.fapi.getContentObjects(typename=thistype,lProperties="objectid,publishdate as datetimelastupdated",publishdate_lte=now()) />
		<cfelse>
			<cfset stLocal.q = application.fapi.getContentObjects(typename=thistype,lProperties="objectid,datetimelastupdated") />
		</cfif>
		<cfloop query="stLocal.q">
			<cfset queryaddrow(stLocal.qURLs) />
			<cfset querysetcell(stLocal.qURLs,"url",application.fapi.getLink(objectid=stLocal.q.objectid,includeDomain=true)) />
			<cfset querysetcell(stLocal.qURLs,"priority","1.0") />
			<cfset querysetcell(stLocal.qURLs,"lastmod",dateformat(stLocal.qNav.datetimelastupdated,'yyyy-mm-dd')) />
			<cfset querysetcell(stLocal.qURLs,"changefreq","weekly") />
		</cfloop>
	</cfif>
</cfloop>

<!--- Create the XML --->
<cfif arraylen(stLocal.age) eq 1>
	<cfset stLocal.sitemap = createObject("java","java.lang.StringBuffer").init() />
	<cfset stLocal.sitemap.append('<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">') />
	<cfloop query="stLocal.qURLs">
		<cfset stLocal.sitemap.append("<url>") />
		<cfset stLocal.sitemap.append("<loc>#stLocal.qURLs.url#</loc>") />
		<cfset stLocal.sitemap.append("<priority>#stLocal.qURLs.priority#</priority>") />
		<cfset stLocal.sitemap.append("<lastmod>#stLocal.qURLs.lastmod#</lastmod>") />
		<cfset stLocal.sitemap.append("<changefreq>#stLocal.qURLs.changefreq#</changefreq>") />
		<cfset stLocal.sitemap.append("</url>") />
	</cfloop>
	<cfset stLocal.sitemap.append("</urlset>") />
<cfelseif arraylen(stLocal.age) gt 1 and isdefined("url.section")>
	<cfset stLocal.sitemap = createObject("java","java.lang.StringBuffer").init() />
	<cfset stLocal.sitemap.append('<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">') />
	<cfloop from="#(url.section-1)*stLocal.persection+1#" to="#min(stLocal.qURLs.recordset,(url.section-1)*stLocal.persection+stLocal.persection)#" index="i">
		<cfset stLocal.sitemap.append("<url>") />
		<cfset stLocal.sitemap.append("<loc>#stLocal.qURLs.url[i]#</loc>") />
		<cfset stLocal.sitemap.append("<priority>#stLocal.qURLs.priority[i]#</priority>") />
		<cfset stLocal.sitemap.append("<lastmod>#stLocal.qURLs.lastmod[i]#</lastmod>") />
		<cfset stLocal.sitemap.append("<changefreq>#stLocal.qURLs.changefreq[i]#</changefreq>") />
		<cfset stLocal.sitemap.append("</url>") />
	</cfloop>
	<cfset stLocal.sitemap.append("</urlset>") />
<cfelse>
	<cfset stLocal.sitemap = createObject("java","java.lang.StringBuffer").init() />
	<cfset stLocal.sitemap.append('<?xml version="1.0" encoding="UTF-8"?><sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">') />
	<cfloop from="1" to="#arraylen(stLocal.age)#" index="thissection">
		<cfset stLocal.sitemap.append("<sitemap>") />
		<cfset stLocal.sitemap.append("<loc>#application.fapi.getLink(type='dmNavigation',view='displayGoogleSitemap',urlparameters='section=#thissection#')#</loc>") />
		<cfset stLocal.sitemap.append("<lastmod>#dateformat(stLocal.age[thissection],'yyyy-mm-dd')#</lastmod>") />
		<cfset stLocal.sitemap.append("</sitemap>") />
	</cfloop>
	<cfset stLocal.sitemap.append("</sitemapindex>") />
</cfif>

<!--- Stream the result --->
<CFHEADER NAME="Cache-Control" VALUE="max-age=300;s-maxage=300">
<cfcontent type="application/xml" variable="#ToBinary( ToBase64(stLocal.sitemap.toString()) )#" reset="Yes" />

<cfsetting enablecfoutputonly="false">