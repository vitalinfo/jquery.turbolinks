before (next) ->
  require('jsdom').env
    html: "<!doctype html><html><head><meta charset='utf-8'></head><body></body></html>",
    done: (errors, window) ->
      global.window = window
      global.document = window.document
      if (errors)
        errors.forEach(console.error)
        throw new Error(errors[0].data.error + " (" + errors[0].data.filename + ")")
      next()

before ->
  global.$ = require('jquery')
  global.jQuery = require('jquery')
  require('../src/jquery.turbolinks.coffee')

chai      = require('chai')
sinon     = require('sinon')
sinonChai = require('sinon-chai')

chai.should()
chai.use(sinonChai)

getUniqId = do ->
  counter = 0
  -> 'id_' + (counter += 1)

describe '$ Turbolinks', ->

  callback1 = callback2 = null

  # Simulate a reset.
  beforeEach ->
    $.turbo.isReady = false
    $.turbo.use 'turbolinks:load', 'turbolinks:request-start'
    $(document).off('turbo:ready')

  describe "DOM isn't ready", ->

    beforeEach ->
      $(callback1 = sinon.spy())
      $(callback2 = sinon.spy())

    it '''
         should trigger callbacks passed to
         `$()` and `$.ready()` when turbolinks:load
         event fired
       ''', ->
         $(document).trigger('turbolinks:load')

         callback1.should.have.been.calledOnce
         callback2.should.have.been.calledOnce

    it 'should pass $ as the first argument to callbacks', (done) ->
      $ ($$) ->
        $$.fn.should.be.an.object
        done()

      $(document).trigger 'turbolinks:load'

    describe '$.turbo.use', ->

      beforeEach ->
        $.turbo.use('turbolinks:load', 'turbolinks:request-start')

      it 'should unbind default (turbolinks:load) event', ->
        $.turbo.use('other1', 'other2')

        $(document).trigger('turbolinks:load')

        callback1.should.have.not.been.called
        callback2.should.have.not.been.called

      it 'should bind ready to passed function', ->
        $(document)
          .trigger('turbolinks:load')
          .trigger('page:change')

        callback1.should.have.been.calledOnce
        callback2.should.have.been.calledOnce

    describe '$.setFetchEvent', ->

      beforeEach ->
        $.turbo.use('turbolinks:load', 'turbolinks:request-start')
        $.turbo.isReady = true

      it 'should unbind default (turbolinks:request-start) event', ->
        $.turbo.use('turbolinks:load', 'random_event_name')
        $(document).trigger('turbolinks:request-start')
        $.turbo.isReady.should.to.be.true

      it 'should bind passed fetch event', ->
        $.turbo.use('turbolinks:load', 'turbolinks:loading')
        $(document).trigger('turbolinks:loading')
        $.turbo.isReady.should.to.be.false

  describe 'DOM is ready', ->

    beforeEach ->
      $.turbo.use('turbolinks:load', 'turbolinks:request-start')
      $.turbo.isReady = true

    it 'should call trigger right after add to waiting list', ->
      $(callback = sinon.spy())
      callback.should.have.been.calledOnce

    it 'should not call trigger after turbolinks:request-start and before turbolinks:load', ->
      $(document).trigger('turbolinks:request-start')
      $(callback1 = sinon.spy())
      callback1.should.have.not.been.called

      $(document).trigger('turbolinks:load')
      $(callback2 = sinon.spy())
      callback2.should.have.been.calledOnce

    it 'should call trigger after a subsequent turbolinks:request-start and before turbolinks:load', ->
      $(document).trigger('turbolinks:request-start')
      $(document).trigger('turbolinks:load')
      $(callback1 = sinon.spy())
      callback1.should.have.been.calledOnce
      $(document).trigger('turbolinks:request-start')
      $(document).trigger('turbolinks:load')
      callback1.should.have.been.calledTwice

    it 'should pass $ as the first argument to callbacks', (done) ->
      $ ($$) ->
        $$.fn.should.be.an.object
        done()
