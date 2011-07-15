<cfsetting enablecfoutputonly="true" />
<!--- @@displayname: Search --->

<cfoutput>
	<div class="search-result">
		<div class="search-title">
			<a href="#arguments.stParam.gss.link#">#arguments.stParam.gss.htmltitle#</a>
		</div>
		<div class="search-summary">
			#arguments.stParam.gss.htmlsnippet#
		</div>
		<div class="search-footer">
			<cfif structkeyexists(arguments.stParam.gss,"typename")>
				<span class="search-type">#application.stCoapi[arguments.stParam.gss.typeName].displayName#</span> |
			<cfelse>
				<span class="search-domain">
					<img src="http://www.google.com/s2/favicons?domain=#arguments.stParam.gss.displaylink#" width="16" height="16" />
					#arguments.stParam.gss.displaylink#
				</span> |
			</cfif>
			<cfif structkeyexists(arguments.stParam.gss,"publishdate") and isdate(arguments.stParam.gss.publishdate)>
				<span class="search-date">#dateFormat(arguments.stParam.gss.publishdate, "d mmmm yyyy")#</span> |
			</cfif>
			<a href="#arguments.stParam.gss.link#">Go to page</a>
		</div>
	</div>
</cfoutput>

<cfsetting enablecfoutputonly="false" />