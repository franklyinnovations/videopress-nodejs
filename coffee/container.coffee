"use strict"

express = require 'express'
pimple = require 'pimple'
util = require 'util'
path = require 'path'
flash = require 'connect-flash'
config = require './lib/config'
events = require 'events'
sessionStores = require './lib/session-stores'
_ = require('lodash')

container = new pimple
    port: process.env.OPENSHIFT_NODEJS_PORT || process.env.PORT || 3000 ,
    ip: process.env.OPENSHIFT_NODEJS_IP || '127.0.0.1',
    youtub_api_key: process.env.EXPRESS_VIDEO_YOUTUBE_API_KEY,
    connection_string: process.env.EXPRESS_VIDEO_MONGODB_CONNECTION_STRING,
    debug: if process.env.NODE_ENV == "production" then false else true

container.set "app", container.share ->
    app = express()
    middlewares = container.middlewares
    controllers = container.controllers
    app.configure ->
        app.use(express.static(path.join(__dirname, "..", "public"),{maxAge:10000}))
        app.engine('twig',container.swig.renderFile)
        app.set('view engine', 'twig')
        app.locals(container.locals)
        app.use(express.cookieParser("secret sentence"))
        app.use(express.session({store:container.sessionStore}))
        app.use(flash())
        app.use(express.bodyParser())
        app.use(container.passport.initialize())
        app.use(container.passport.session())
        # persistent session login
        app.use(express.favicon())
        app.use(express.compress())
        app.use(container.monolog.middleware())
        app.disable("verbose errors")

    app.configure 'development', ->
        app.use(express.logger("dev"))
        app.enable('verbose errors')

    app.configure 'testing', ->
        app.disable("verbose errors")

    app.map = container.mixins.map
    
    app.param('videoId',middlewares.video)
    app.param('playlistId',middlewares.playlist)
    ### protect profile pages ###
    ### inject container into current request scope ###
    app.use((req,res,next)->
        res.locals.container=container
        next()
    )
    app.use(middlewares.user)
    app.use(middlewares.flash)
    app.use('/profile',middlewares.isLoggedIn)
    app.use('/profile',middlewares.csrf)
    app.use('/login',middlewares.csrf)
    app.use('/signup',middlewares.csrf)
    app.use('/video',middlewares.csrf)
    
    app.map
        "/":
            get:controllers.index
        "/api/video":
            use: middlewares.videoApi
        "/api/video.fromUrl":
            post: controllers.videoFromUrl
        "/api/playlist":
            use: middlewares.playlistApi
        "/video/:videoId":
            get:controllers.videoById
        "/playlist/:playlistId":
            get:controllers.playlistById
        "/category/:categoryId/:categoryTitle?":
            get:[middlewares.categories,controllers.categoryById]
        "/profile":
            all:controllers.profile
            "/video/new":
                all:controllers.videoCreate
            "/video":
                all:controllers.videoList
            "/video/:videoId/update":
                all:[middlewares.belongsToUser(container.Video,'video'),
                    controllers.videoUpdate]
            '/video/:videoId/remove':
                post:[middlewares.belongsToUser(container.Video,'video')
                    controllers.videoRemove]
            '/playlist':
                get:controllers.playlistList
            '/playlist/:playlistId/update':
                all:[middlewares.belongsToUser(container.Playlist,'playlist'),
                    controllers.playlistUpdate]
            '/playlist/:playlistId/delete':
                all:[middlewares.belongsToUser(container.Playlist,'playlist'),
                    controllers.playlistRemove]
            '/playlist/new':
                all:controllers.playlistCreate
        "/login":
            get:controllers.login
            post:container.passport.authenticate('local-login',{
                successRedirect:'/profile',
                failureRedirect:'/login',
                failureFlash:true
                })
        "/signup":
            get:controllers.signup
            post:[controllers.signupPost,container.passport.authenticate('local-signup',{
                successRedirect:'/profile',
                failureRedirect:'/signup',
                failureFlash:true
            })]
        #erase user credentials
        "/logout":
            get:controllers.logout
        #search videos by title
        "/search":
            get:controllers.videoSearch

    app.configure "production",->
        #middleware for errors
        app.use(middlewares.error)

    app.on 'error',(err)->
        container.mongolog.error(err)

    return app

container.set "locals", container.share ->
    title: "videopress",
    logopath:"/images/video-big.png",
    paginate: (array, length, start = 0)->
        divisions = Math.ceil(array.length / length)
        [start...divisions].map (i)->
            array.slice(i * length, i * length + length)

container.set "swig", container.share (c)->
    swig = require 'swig'
    swig.setDefaults({cache: c.config.swig_cache})
    return swig

container.set "db", container.share ->
    database = require './lib/database'
    database.set("debug", container.config.mongoose_debug) #container.debug 
    database.connect(container.config.connection_string)
    return database

container.set "User", container.share ->
    container.db.model('User')

container.set("Category",container.share(->
    container.db.model('Category'))
)

container.set "Video", container.share ->
    container.db.model('Video')

container.set "Playlist", container.share ->
    container.db.model('Playlist')

container.set "Session",container.share ->
    container.db.model('Session')

container.set "sessionStore",container.share ->
    new sessionStores.MongooseSessionStore({},container.Session)

container.set "monolog", container.share ->
    monolog = require 'monolog'
    logger = new monolog.Logger("express logger")
    logger.addHandler(new monolog.handler.StreamHandler(__dirname + "/../temp/log.txt"))
    logger.middleware = (message = "debug")->
        init = false
        return (req, res, next)->
            if not init
                logger.addProcessor(new monolog.processor.ExpressProcessor(req.app))
                req.app.set('monolog', logger)
                init = true
            logger.debug("#{message} #{req.method} #{req.path} #{JSON.stringify(req.headers)}")
            next()

    return logger

container.set "passport", container.share ->
    passport = require 'passport'
    LocalStrategy = require('passport-local').Strategy
    User = container.User
    passport.serializeUser (user,done)->done(null,user.id)
    passport.deserializeUser (id,done)->User.findById(id,done)
    passport.use 'local-signup', new LocalStrategy({
        usernameField:'email',
        passwordField:'password',
        passReqToCallback:true
    },(req,email,password,done)->
        process.nextTick ->
            User.findOne 'local.email':email,(err,user)->
                if err  then done(err)
                if user
                    done(null,false,req.flash('signupMessage','That email is already taken'))
                else
                    newUser = new User()
                    newUser.username = req.body.username
                    newUser.local.email = email
                    newUser.local.password = newUser.generateHash(password)
                    newUser.save(done)
    )
    passport.use 'local-login',new LocalStrategy({
        usernameField:'email',
        passwordField:'password',
        passReqToCallback:true
    },(req,email,password,done)->
        User.findOne {'local.email':email},(err,user)->
            if err then return done(err)
            if user 
                if user.validPassword(password)
                    return done(null,user)
            return done(null,false,req.flash('loginMessage','Invalid credentials!'))
    )
    return passport

container.set("forms", container.share -> require './lib/forms')
container.set("middlewares", container.share -> require './lib/middlewares')
container.set("controllers", container.share -> require './lib/controllers')
container.set("mixins", container.share -> require './lib/mixins')
container.set("parsers",container.share -> require './lib/parsers')
container.set("config",container.share( -> require './lib/config'))

module.exports = container
