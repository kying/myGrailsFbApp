<!DOCTYPE html>
<html>
<head>
<title>Maintain It - A Grails Facebook App</title>
<meta charset="UTF-8">
<link rel="stylesheet" href="//netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css">
<link rel="stylesheet" href="//netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap-theme.min.css">        
</head>
<body>
<div class="navbar navbar-inverse navbar-static-top" role="navigation">
    <div class="container">
        <div class="navbar-header">
            <a class="navbar-brand" href="#" style="color: #fff;">Maintain It</a>
        </div>
    </div>
</div>
<div class="container">
	<div id="fb-root"></div>
	
	<div id='loggedInDisplay' style="display:none;" class="container">
	    <form class="form-inline" role="form">
	        <div class="form-group">
	            <label for="pages">Current Page: </label>
	            <select id="pages" class="form-control" style="display:none;" onchange="pagesChange();"></select>
	        </div>
	    </form>
		<br><br>
		<div class="jumbotron" style="padding-top: 10px; padding-bottom: 23px;">
		   <h3 style="margin-top: 0px;">Create Post</h3>
			<form name="input" action="" method="get" role="form">
			  <div class="form-group">
	            <label for="messageInput">Message</label>
	            <input id="messageInput" type="text" class="form-control" name="message">
	          </div>
			  <input id="publishInput" type="checkbox" checked="true" name="publish" value="1" style="margin-right: 10px;">Publish?
			  <input type="submit" value="Submit" class="btn btn-primary" onClick="submitPost();return false;" style="float: right;">
			</form>
		</div>
		<div class="row">
		   <h3 class="page-header">View Posts <button class="btn btn-default" onclick="readPosts();"><span class="glyphicon glyphicon-refresh"></span></button></h3>
		   <div class="col-md-6">
		       <h3>Published</h3>
		       <ul class="list-group" id="publishedmessages">
		       </ul>
		    </div>
	        <div class="col-md-6">
	            <h3>Unpublished</h3>
	            <ul class="list-group" id="unpublishedmessages">
	            </ul>
	        </div>
	    </div>
		
	</div>


	<div id='loggedOutDisplay'>
	    <div class="jumbotron" style="text-align: center;">
	       <div>Unfortunately this page is not very exciting without Facebook. Please Login</div>
	       <button onClick="loginAndGetPages()" class="btn btn-primary">Login</button>
	    </div>
	</div>
	
</div>
<script src="http://code.jquery.com/jquery-2.1.1.min.js"></script>
<script src="//netdna.bootstrapcdn.com/bootstrap/3.1.1/js/bootstrap.min.js"></script>
<script src="http://connect.facebook.net/en_US/all.js"></script>
<script>
FB.init({ appId: '1500253416855132', status: true, cookie: true, xfbml : true });
var access_token;
var user_token;
var page_id;
var post_id;

window.onload = function(){
    loginAndGetPages();  
};

//This is the onChange for the option menu. Similar to onclick, but whenever a different option is selected, this is called
function pagesChange(){
    var pages = document.getElementById("pages");
    page_id = pages.options[pages.selectedIndex].value;
    access_token = pages.options[pages.selectedIndex].id
    readPosts(); 
}

function loginAndGetPages() {  
    FB.getLoginStatus(function(response) {
        if (response.status == 'connected') {
            document.getElementById("loggedOutDisplay").style.display = 'none';
            document.getElementById("loggedInDisplay").style.display = 'block';
            user_token = response.authResponse.accessToken;
            FB.api('/me/accounts/', getPagesCallback); 
        }
        else{
            FB.login(function(response){
                loginAndGetPages(); //Respond by just calling the function again
            }, {scope:'read_insights,manage_pages,publish_actions'});
        }
    }); 
}
 
var getPagesCallback = function(response) {
    if (!response || response.error) {
        alert("There was an error getting the users pages");
    }
    var pages = document.getElementById('pages');
    pages.style.display = 'inline';
    if (response.data.length == 0){
        alert("You have no pages. You should probs make some");
        return false;
    }
    //Start by setting access token and page id to first thing as that starts as displayed,
    //and whenever the dropdown is changed, change those values in the onchange function
    access_token = response.data[0].access_token; 
    page_id = response.data[0].id;
    for(var i=0; i < response.data.length; i++) {
        pages[i] = new Option(response.data[i].name, response.data[i].id);
        pages[i].id = response.data[i].access_token;
    }
    readPosts();
};

function submitPost() {
    var message = document.getElementById("messageInput").value;
    var published = document.getElementById("publishInput").checked;
    var pages = document.getElementById("pages");
    var current_page = pages.options[pages.selectedIndex].innerHTML;
    //Confirm dialog - makes sure user wants to submit
    var doPost = confirm("Are you sure you want to submit? \nmessage: " + message + " \npage: " + current_page);
    if (!doPost){
        //If they cancel, return so the code doesn't keep going
        return false;
    }
    var wallPost = {
        access_token: access_token,
        message: message,
        published: published
    };
    FB.api('/' + page_id + '/feed', 'post', wallPost, postCallback);
}

var postCallback = function(response){
    if (!response || response.error) {
        alert("The post failed. Please try again");
    } 
    else {
        setTimeout(function(){readPosts()}, 2000);
    }
}

function readPosts() {
    var wallPost = {
        access_token: access_token
    };
    FB.api('/' + page_id + '/promotable_posts', wallPost, readPostCallback);
}

var readPostCallback = function(response){
    if (!response || response.error) {
        alert("There was an error getting posts for the page");
    }
    document.getElementById("publishedmessages").innerHTML = "";
    document.getElementById("unpublishedmessages").innerHTML = "";
    for(var i=0; i < response.data.length; i++) {
        var message = escapeString(response.data[i].message);
        var published = response.data[i].is_published;
        
        if (message){
            var displayMessage = "<li class='list-group-item' id='" + response.data[i].id + "'><span class='badge' id='views_" + response.data[i].id + "'></span>" + message + "</li>";
            if (published){
                document.getElementById("publishedmessages").innerHTML += displayMessage;
                getPageViewCount(response.data[i].id);
            }
            else {
                document.getElementById("unpublishedmessages").innerHTML += displayMessage;
            }
        }
    }
}

function getPageViewCount(postid) {
    var accessToken = {
        access_token: access_token
    };
    FB.api('/' + postid + '/insights/post_impressions_unique', accessToken, pageViewsCallback);
}

var pageViewsCallback = function(response){
	console.log(JSON.stringify(response));
	if (!response || response.error) {
	   alert("There was an error getting page view information");
	}
    for (var i=0; i < response.data.length; i++){
    	console.log(response.data[i]);
        var postid = response.data[i].id.split('/')[0];
        console.log(postid);
        
        document.getElementById("views_" + postid).innerHTML = response.data[i].values[0].value;
    }
}

//So user can't embedd html
function escapeString(html){
    if (html){
	    html = html.replace(/&/g, "&amp;");
	    html = html.replace(/</g, "&lt;");
	    html = html.replace(/>/g, "&gt;");
	    html = html.replace(/"/g, "&quot;");
	    html = html.replace(/'/g, "&#039;");
    }
    return html;
} 
</script>

</body>
</html>