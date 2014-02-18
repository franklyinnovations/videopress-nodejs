mpm.video
=========

author : mparaiso

version : 0.0.3


Express-video is a cms allowing users to create playlists from various video web sites such as Youtube. It is built on nodejs with express framework and mongodb.

### Changelog

### FEATURES

- membership
- import and display videos from : 
	- Youtube

### DOCUMENTATION

#### INSTALLATION

- install git

- install nodejs and npm

- intstall mongodb

- get a youtube api key

- clone the repository with git

	git clone https://github.com/Mparaiso/mpm.video

- add the following envirronment variables to your system : 

	- EXPRESS_VIDEO_MONGODB_CONNECTION_STRING : your mongodb connection string
	  
	  on a local mongodb installation , should be  mongodb://localhost

	- EXPRESS_VIDEO_YOUTUBE_API_KEY : your youtube api key 

	- SESSION_SECRET : a secret phrase for session encryption

- open a terminal, go to the project folder

- install packages with the npm install command

- you should be good to go , just type : node app.js in the project folder

- open a web browser to http://localhost:300

- go to /signup to create a new account



	


#### API 

	GET		/ : homepage
	GET		/videoId : display a video

	user accounts

	/signup : signup
	/login :login
	/profile : profile
	/logout :logout

	### video management

	/profile/video :list user videos
	/profile/video/new :add new vide
	/profile/video/:videoId/update :update a video
	/profile/video/:videoId/delete :delete a video

### TODO
