###
    Copyright © 2014 mparaiso <mparaiso@online.fr>. All Rights Reserved.
###
module.exports = (container)->

    container.set "app", container.share (c)->
        init = false
        middlewares = c.middlewares
        controllers = c.controllers

        app = c.express()
        app.disable 'x-powered-by'
        app.enable 'trust proxy'

        app.engine('twig', c.swig.renderFile)
        app.set('view engine', 'twig')
        app.locals(c.locals)

        app.use (req, res, next)->
            # init models
            if not init
                c.Session
                c.Category
                c.User
                c.Video
                c.Playlist
                init = true
            next()
    
        app.use(c.express.static(c.path.join(__dirname, "..", "public"), c.config.static))
        app.use(c.express.cookieParser(c.config.session.secret))
        app.use(c.express.session(c._.extend({}, c.config.session, {store: c.sessionStore})))
        app.use require('connect-flash')()
        app.use c.express.bodyParser()
        app.use c.passport.initialize()
        app.use c.passport.session()
        app.use c.express.compress()
        app.use c.express.csrf()

        if c.debug
            app.enable('verbose errors') unless process.env.NODE_ENV is "testing"
            app.use(c.express.logger("dev"))
        else
            app.disable("verbose errors")
            app.on 'error', (err)->
                c.logger.error({error:err,message:err.message})

        app.enable('verbose errors')

        app.use (req,res,next)->
            #set various params on res.locals
            if req.isAuthenticated()
                res.locals.isAuthenticated = true
                res.locals.user = req.user

            res.locals.originalUrl = req.originalUrl
            res.locals.config = c.config
            res.locals._csrf = req.csrfToken()
            res.locals.flash = req.flash()
            next()

        app.use middlewares.requestLogger # log every regquests
        app.use middlewares.firewall #use acl to check if current user can access route

        app.param 'videoId', middlewares.video
        app.param 'playlistId', middlewares.playlist




        ### Routes ###
        app.get  '/',controllers.index
        app.get  '/video/:videoId',controllers.videoById
        app.get  '/playlist/:playlistId',controllers.playlistById
        app.get  '/category/:categoryId/:categoryTitle?',middlewares.categories, controllers.categoryById
        app.get  '/profile', controllers.profile.index
        app.all  '/profile/video/new',controllers.videoCreate
        app.all  '/profile/video',controllers.videoList
        app.post '/profile/video/action',controllers.profile.video.actions
        app.all  '/profile/video/:videoId/update',middlewares.belongsToUser(c.Video, 'video'),controllers.videoUpdate
        app.post '/profile/video/:videoId/delete',middlewares.belongsToUser(c.Video, 'video'),controllers.videoDelete
        app.get  '/profile/playlist', controllers.playlistList
        app.all  '/profile/playlist/:playlistId/update',middlewares.belongsToUser(c.Playlist, 'playlist'),controllers.playlistUpdate
        app.post '/profile/playlist/:playlistId/delete',middlewares.belongsToUser(c.Playlist, 'playlist'),controllers.playlistRemove
        app.all  '/profile/playlist/new', controllers.playlistCreate
        app.all  '/profile/playlist/fromurl',controllers.profile.playlist.fromUrl
        app.get  '/profile/logout', controllers.logout #erase user credentials
        app.get  '/login',controllers.login
        app.post '/login', c.passport.authenticate('local-login', {successRedirect: '/profile',failureRedirect: '/login',failureFlash: true})
        app.get  '/signup', controllers.signup
        app.post '/signup',controllers.signupPost, c.passport.authenticate('local-signup', {successRedirect: '/profile',failureRedirect: '/signup',failureFlash: true})
        app.get  '/search', controllers.videoSearch #search videos by title
    
        if not c.debug
            #middleware for errors if not debug
            app.get '/*', (req, res, next)->
                next(new c.errors.NotFound("page not found"))
    
            app.use middlewares.error
    

        return app