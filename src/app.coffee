# load dependencies
express = require 'express'
Sequelize = require 'sequelize'
Store = require('express-sequelize-session') express.session.Store

# use in-memory SQLite3 database
sequelize = new Sequelize 'itest', 'sa', 'secret', dialect: 'sqlite', logging: false
store = new Store sequelize, 'session'

# define user table
User = sequelize.define 'user',
  login:
    type: Sequelize.STRING
    allowNull: false
    unique: true
  password:
    type: Sequelize.STRING
    allowNull: false

# associate session with user
User.belongsTo store.Session, foreignKeyConstraint: true

# process a login request, reference the session and yield the user
login = (req, done) ->
  User.findOne
    where:
      login: req.body.login
      password: req.body.password
  .then (user) ->
    if not user
      throw new Error 'login failed'
    else
      store.Session.findOne
        where:
          sid: req.sessionID
      .then (session) ->
        if not session # login without session
          user
        else # reference session
          user.setSession session
  .then (user) ->
    done null, user
  .catch (err) ->
    done err, null

# process a logout request
logout = (req, done) ->
  User.findOne
    where:
      login: req.session.user
  .then (user) ->
    if not user
      throw new Error 'logout failed'
    else
      user.setSession null
  .then (user) ->
    done null, user
  .catch (err) ->
    done err, null

# create and configure express app
app = express()
app.use express.bodyParser()
app.use express.methodOverride()
app.use express.cookieParser()
app.use express.session
  key: 'sid'
  secret: 'MyAwesomeAppSessionSecret'
  store: store

# activate router
app.use app.router

# restrict requests
app.all '*', (req, res, next) ->
  if req.path in ['/', '/login', '/logout']
    next() # always allow access of these resources
  else # check user session
    if req.session.user
      next() # authenticated request
    else
      res.send 401 # unauthorized

# public index page with login form
app.get '/', (req, res) ->
  res.send """
    <html><head><title>restricted area</title></head><body>
    <form action="/login" method="POST">
      <label>Login <input type="text" name="login"/></label>
      <label>Password <input type="password" name="password"/></label>
      <button type="submit">Login</button>
    </form></body></html>
  """

# validate login and redirect
app.post '/login', (req, res, next) ->
  login req, (err, user) ->
    if err? then next err else # re-ref user login
      req.session.user = user.login
      res.redirect '/private'

# logout and redirect
app.get '/logout', (req, res, next) ->
  logout req, (err) ->
    if err? then next err else
      delete req.session.user # de-ref user for safety
      req.session.destroy ->
        res.redirect '/'

# private content page
app.get '/private', (req, res) ->
  res.send """
    <html><head><title>private space</title></head><body>
    <h1>Welcome #{req.session.user}</h1>
    <p>nice 2 cu</p>
    <a href="/logout">Logout</a>
    </body></html>
  """

# export database and express app
module.exports = (done) ->
  sequelize.sync
    force: true
  .then ->
    done null, app,
      Session: store.Session
      User: User
  .catch (err) ->
    done err

