supertest = require 'supertest'
initApp = require '../src/app'

admin =
  login: 'admin@localhost'
  password: 'secret'

describe 'Express 3.x integration test', ->

  request = null
  agent = null

  before (done) ->
    initApp (err, app, db) ->
      if err? then done err else
        request = supertest app
        agent = supertest.agent app
        db.User.create(admin)
        .then ->
          done null
        .catch (err) ->
          done err

  it 'GET / public index page', (done) ->
    request.get('/').expect(200).expect('Content-Type', /html/).expect(/password/).end done

  it 'POST /login invalid', (done) ->
    request.post('/login').send(login: 'anonymous').expect(500).end done

  it 'POST /login success', (done) ->
    agent.post('/login').send(admin).expect(302).end done

  it 'GET /private unauthorized', (done) ->
    request.get('/private').expect(401).end done

  it 'GET /private authorized', (done) ->
    agent.get('/private').expect(200).expect(/Logout/).end done

  it 'GET /logout unauthorized', (done) ->
    request.get('/logout').expect(500).end done

  it 'GET /logout authorized', (done) ->
    agent.get('/logout').expect(302).end done

