# Google Site Search Plugin

Provides close integration for FarCry projects with the Google Site Search service.

Google Custom Search enables you to create a search engine for your website, your blog, or a collection of websites. You can fine-tune the ranking, customize the look and feel of the search results, and invite your friends or trusted users to help you build your custom search engine.

Features include:

- webtop configuration
- support for page mapping custom content attributes
- example search result templates

> The solution requires an active Google Site Search service. This is a paid service available from Google: http://www.google.com/sitesearch/

## Installation

### Checkout from source control

```
cd ./farcry/plugins
git clone https://github.com/farcrycore/plugin-googlesitesearch.git googleSiteSearch
```

> ```master``` should be mostly stable. But there are specific milestone tags for those who don't want to risk it.

### Update project constructor

Add googleSiteSearch to the plugin list within ```./www/farcryConstructor.cfm```

```
<!---// set plugin list--->
<cfset THIS.plugins = "farcrycms,googleMaps,googleAnalytics,googleSiteSearch,farcrydoc" />
```

### Deploy content types

Go into the webtop ADMIN > DEVELOPER TOOLS and deploy all the plugin content types.

### Update Google Site Search configuration file

You will need to update the plugins configuration to include your projects specific Google Site Search API Key code.

### Add GSS code to views

Done. GSS PageMap metadata is automatically included into the HEAD of all page views.

### Remove /search from robots.txt

GSS uses url parameters for search queries (better for cache management and the like). You need to exclude search results from bots so you don't blow your search quota just servicing indexing requests.

```
Disallow: /search
```

Read more here: http://discourse.farcrycore.org/t/google-site-search-plugin/55/2?u=modius

## Customising the Look & Feel

By default, the GSS plugin refers to a universal typewebskin called 

```
./googleSiteSearch/webskin/types/displaySearchResult.cfm
```

You can override this behaviour by creating a webskin of exactly the same name in your project. 

GSS plugin uses the standard XML API for retrieving results. You should be able to incorporate any of the data that is returned into your search results output. All GSS custom variables are passed to the webskin in the structure `stparams.GSS`.

Review Google API documentation for an overview: 

http://code.google.com/intl/en/apis/customsearch/docs/snippets.html
