### IN THE APP FILE ###

express = require 'express'
app = express()
session = require 'express-session'
app.use session
	secret: 'your-random-secret'
	resave: false
	saveUninitialized: true

### MIDDLEWARES ###

module.exports =
	auth: (req, res, next) ->
		if req.session and req.session.user then next() else res.redirect '/login'

	guest: (req, res, next) ->
		if not req.session or not req.session.user then next() else res.redirect '/home'

### IN THE ROUTES ###
# Notice that the second parameter is the middleware
# In case you use passport, here is the passport middleware
router.get '/invoices', middleware.auth, (req, res) ->

### AUTH ###

# Login view
router.get '/login', middleware.guest, (req, res) -> 	res.render 'login'

# Login to the app
router.post '/login', middleware.guest, (req, res) ->
	# Modules
	Promise = require 'bluebird'
	bcrypt = Promise.promisifyAll require('bcrypt-nodejs')
	users = require('../database/models').getUserModel

	# Find user
	users.findOneAsync(user: req.body.user, active: true)
	.then (user) ->
		# If user exist check password else redirect
		if (user)
			# Compare password
			bcrypt.compareAsync(req.body.password, user.password)
			.then((valid) ->
				# If password is valid send to home
				if valid
					# WE SET THE SESSION VARIABLE
					req.session.user = user
					res.redirect 'home'
				else
					# WE JUST REDIRECT TO THE LOGIN ROUTE WITH THE RESPECTIVE MESSAGE
					message = "Wrong user informatin, try again"
					res.render 'login', msg: message
			).catch (err) ->
				# Some random error in the login
				res.render 'login', msg: 'Oops! try again.'
		else
			res.render 'login', msg: '¡Usuario invalido o bloqueado!'

# Bcrypt test
router.get '/password/:password', (req, res) ->
	bcrypt = require 'bcrypt-nodejs'
	hash = bcrypt.hashSync req.params.password
	res.send hash

### ROUTE EXAMPLE ###
router.get '/home', middleware.auth, (req, res) ->
	# Look I'm passing session parameters to the template helper for the route
	res.render 'home',
		username: req.session.user.name
		role: req.session.user.role
		section: 'home'

# Logout
router.get '/logout', middleware.auth, (req, res) ->
	# I destroy the session and redirect to login
	req.session.destroy()
	res.redirect '/login'